// lib/features/live_navigation/providers/routing/osrm_routing_service.dart
//
// OSRM v1 compatible [RoutingService] (open-source engine, no key).
//
// Default endpoint is the public OSRM demo server: a SHARED, rate-limited
// resource with no SLA — fine for development, NOT for production traffic.
// Point [baseUrl] (or --dart-define=OSRM_BASE_URL) at your own OSRM
// instance for real use. Any server speaking the OSRM v1 route API works.
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/nav_config.dart';
import '../../models/geo_math.dart';
import '../../models/nav_route.dart';
import '../../services/nav_errors.dart';
import 'routing_service.dart';

class OsrmRoutingService implements RoutingService {
  OsrmRoutingService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? NavConfig.osrmBaseUrl).replaceAll(
        RegExp(r'/+$'),
        '',
      );

  final http.Client _client;
  final String _baseUrl;

  @override
  Future<List<NavRouteOption>> computeRoutes({
    required NavLatLng origin,
    required NavLatLng destination,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/route/v1/driving/'
      '${origin.longitude},${origin.latitude};'
      '${destination.longitude},${destination.latitude}',
    ).replace(
      queryParameters: {
        'overview': 'full',
        'geometries': 'polyline',
        'steps': 'true',
        'alternatives': 'true',
      },
    );

    late http.Response response;
    try {
      response = await _client
          .get(uri)
          .timeout(NavConfig.apiTimeout);
    } on TimeoutException {
      throw const NavError(NavErrorKind.timeout);
    } catch (e) {
      throw _mapTransportError(e);
    }

    if (response.statusCode == 429) {
      throw const NavError(NavErrorKind.rateLimited);
    }
    if (response.statusCode != 200) {
      throw _mapStatusError(response.statusCode);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final code = (body['code'] ?? '').toString();
    if (code == 'TooManyRequests') {
      throw const NavError(NavErrorKind.rateLimited);
    }
    if (code != 'Ok') {
      // e.g. "NoRoute", "NoSegment", "InvalidOptions", "InvalidQuery".
      throw const NavError(NavErrorKind.routeNotFound);
    }

    final routes = (body['routes'] as List?) ?? const [];
    final options = <NavRouteOption>[];
    for (var i = 0; i < routes.length; i++) {
      final r = routes[i];
      if (r is Map<String, dynamic>) {
        final option = _parseRoute(r, i);
        if (option.trackingPoints.length >= 2) options.add(option);
      }
    }
    if (options.isEmpty) {
      throw const NavError(NavErrorKind.routeNotFound);
    }
    return options;
  }

  NavRouteOption _parseRoute(Map<String, dynamic> json, int index) {
    final overview = GeoMath.decodePolyline(
      (json['geometry'] ?? '').toString(),
    );
    final steps = <NavRouteStep>[];
    final legs = (json['legs'] as List?) ?? const [];
    for (final leg in legs) {
      if (leg is! Map<String, dynamic>) continue;
      final legSteps = (leg['steps'] as List?) ?? const [];
      for (final s in legSteps) {
        if (s is Map<String, dynamic>) steps.add(_parseStep(s));
      }
    }
    final summary = (json['weight_name'] ?? '').toString();
    return NavRouteOption(
      summary: summary.isEmpty ? 'Route ${index + 1}' : summary,
      distanceMeters: (json['distance'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: ((json['duration'] as num?)?.toDouble() ?? 0.0).round(),
      overviewPoints: overview,
      steps: steps,
    );
  }

  NavRouteStep _parseStep(Map<String, dynamic> json) {
    final maneuver = json['maneuver'] as Map<String, dynamic>? ?? {};
    final type = (maneuver['type'] ?? '').toString();
    final modifier = maneuver['modifier']?.toString();
    final name = (json['name'] ?? '').toString();
    final points = GeoMath.decodePolyline(
      (json['geometry'] ?? '').toString(),
    );
    return NavRouteStep(
      instruction: _buildInstruction(type, modifier, name),
      maneuver: _maneuverToken(type, modifier),
      distanceMeters: (json['distance'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: ((json['duration'] as num?)?.toDouble() ?? 0.0).round(),
      points: points,
    );
  }

  /// Turns OSRM maneuver {type, modifier} + road name into plain speech.
  static String _buildInstruction(
    String type,
    String? modifier,
    String road,
  ) {
    final on = road.isEmpty ? '' : ' onto $road';
    final onRoad = road.isEmpty ? '' : ' on $road';
    final mod = _modifierWord(modifier);
    switch (type) {
      case 'depart':
        return road.isEmpty ? 'Start driving' : 'Start on $road';
      case 'arrive':
        return road.isEmpty
            ? 'You have arrived at your destination'
            : 'You have arrived at $road';
      case 'turn':
        return 'Turn $mod$on';
      case 'new name':
        return road.isEmpty ? 'Continue straight' : 'Continue onto $road';
      case 'continue':
        return road.isEmpty ? 'Continue straight' : 'Continue$onRoad';
      case 'merge':
        return road.isEmpty ? 'Merge' : 'Merge$onRoad';
      case 'on ramp':
        return road.isEmpty ? 'Take the ramp' : 'Take the ramp$on';
      case 'off ramp':
        return road.isEmpty ? 'Take the exit' : 'Take the exit$on';
      case 'fork':
        return 'Keep $mod at the fork${road.isEmpty ? '' : ' onto $road'}';
      case 'end of road':
        return 'At the end of the road, turn $mod$on';
      case 'roundabout':
      case 'rotary':
        return road.isEmpty
            ? 'Enter the roundabout'
            : 'Enter the roundabout$on';
      case 'roundabout turn':
      case 'exit roundabout':
      case 'exit rotary':
        return road.isEmpty
            ? 'Exit the roundabout'
            : 'Exit the roundabout$on';
      case 'notification':
        return road.isEmpty ? 'Continue' : 'Continue$onRoad';
      default:
        return road.isEmpty ? 'Continue' : 'Follow $road';
    }
  }

  static String _modifierWord(String? modifier) {
    switch (modifier) {
      case 'left':
        return 'left';
      case 'right':
        return 'right';
      case 'slight left':
        return 'slightly left';
      case 'slight right':
        return 'slightly right';
      case 'sharp left':
        return 'sharply left';
      case 'sharp right':
        return 'sharply right';
      case 'straight':
        return 'straight';
      case 'uturn':
        return 'back (U-turn)';
      default:
        return modifier ?? '';
    }
  }

  /// Short token for the banner icon mapping.
  static String _maneuverToken(String type, String? modifier) {
    if (type == 'arrive') return 'arrive';
    if (type == 'depart') return 'depart';
    if (type.contains('roundabout') || type == 'rotary') {
      return 'roundabout';
    }
    if (type.contains('ramp') || type == 'exit roundabout') return 'exit';
    if (type == 'merge' || type == 'fork') return type;
    if (modifier == null || modifier.isEmpty) return type;
    return 'turn $modifier';
  }

  NavError _mapTransportError(Object e) {
    final text = e.toString();
    if (text.contains('SocketException') ||
        text.contains('Failed host lookup') ||
        text.contains('Network is unreachable') ||
        text.contains('Connection refused')) {
      return const NavError(NavErrorKind.noInternet);
    }
    return NavError(NavErrorKind.unknown, text);
  }

  NavError _mapStatusError(int status) {
    if (status >= 500) {
      return NavError(
        NavErrorKind.serviceUnavailable,
        'Routing server error (HTTP $status).',
      );
    }
    return NavError(
      NavErrorKind.serviceUnavailable,
      'Routing request failed (HTTP $status).',
    );
  }
}
