// lib/features/live_navigation/providers/routing/campus_routing_service.dart
//
// Campus-specific routing service that wraps OSRM and adds custom pathways
// for known campus connections (e.g., Main Building ↔ Annex Building).
// Enforces campus boundary: all entry/exit must go through designated gates.

import '../../../../models/user_role.dart';
import '../../config/campus_buildings.dart';
import '../../models/geo_math.dart';
import '../../models/nav_route.dart';
import '../../services/nav_errors.dart';
import '../routing/osrm_routing_service.dart';
import '../routing/routing_service.dart';

class CampusRoutingService implements RoutingService {
  CampusRoutingService({RoutingService? osrmService, this.role})
    : _osrm = osrmService ?? OsrmRoutingService();

  final RoutingService _osrm;

  /// Selected campus role; limits which gates a walk-in visitor may enter.
  final UserRole? role;

  // Custom pathway: Main Building (MB) to Annex Building (AB)
  // From: 8.06522, 123.75695 (MB southeast)
  // To:   8.06549, 123.75726 (AB southwest)
  static const List<NavLatLng> mbToAbPath = [
    NavLatLng(8.06522, 123.75695),
    NavLatLng(8.06549, 123.75726),
  ];

  // Campus boundary polygon (4 corners, clockwise, closed)
  // NW: 8.06441, 123.75838
  // NE: 8.06615, 123.75696
  // SE: 8.06444, 123.75502
  // SW: 8.06271, 123.75648
  static const List<NavLatLng> _campusBoundary = [
    NavLatLng(8.06441, 123.75838),
    NavLatLng(8.06615, 123.75696),
    NavLatLng(8.06444, 123.75502),
    NavLatLng(8.06271, 123.75648),
    NavLatLng(8.06441, 123.75838), // closed
  ];

  // Radius (meters) to consider a point "at" a building
  static const double _buildingProximityRadius = 50.0;

  // A boundary crossing is allowed only within this distance of a gate.
  static const double _gateCrossingToleranceMeters = 35.0;

  @override
  Future<List<NavRouteOption>> computeRoutes({
    required NavLatLng origin,
    required NavLatLng destination,
  }) async {
    final originInside = _isInsideCampus(origin);
    final destinationInside = _isInsideCampus(destination);

    if (originInside && destinationInside) {
      return _computeInsideRoutes(origin, destination);
    }

    if (!originInside && !destinationInside) {
      final routes = await _osrm.computeRoutes(
        origin: origin,
        destination: destination,
      );
      final safe = routes
          .where(
            (route) => _routeRespectsBoundary(
              route,
              originInside: false,
              destinationInside: false,
            ),
          )
          .toList();
      return safe.isNotEmpty ? safe : routes;
    }

    return _routesViaGate(
      origin: origin,
      destination: destination,
      originInside: originInside,
    );
  }

  Future<List<NavRouteOption>> _computeInsideRoutes(
    NavLatLng origin,
    NavLatLng destination,
  ) async {
    final destinationIsAnnex = _isNearBuilding(
      destination,
      CampusBuildings.annexBuilding.labelPoint,
    );
    final originIsAnnex = _isNearBuilding(
      origin,
      CampusBuildings.annexBuilding.labelPoint,
    );

    if (destinationIsAnnex || originIsAnnex) {
      return [_buildCustomMbAbRoute(origin, destination)];
    }

    final routes = await _osrm.computeRoutes(
      origin: origin,
      destination: destination,
    );
    final safe = routes
        .where(
          (route) => _routeRespectsBoundary(
            route,
            originInside: true,
            destinationInside: true,
          ),
        )
        .toList();
    if (safe.isNotEmpty) return safe;

    return [_buildDirectInsideRoute(origin, destination)];
  }

  Future<List<NavRouteOption>> _routesViaGate({
    required NavLatLng origin,
    required NavLatLng destination,
    required bool originInside,
  }) async {
    final outsidePoint = originInside ? destination : origin;
    final gates =
        CampusEntrances.all
            .where(
              (gate) => originInside ? gate.walkInExit : _canEnterOnFoot(gate),
            )
            .toList()
          ..sort(
            (a, b) => GeoMath.distanceMeters(
              outsidePoint,
              a.location,
            ).compareTo(GeoMath.distanceMeters(outsidePoint, b.location)),
          );
    if (gates.isEmpty) {
      throw const NavError(
        NavErrorKind.routeNotFound,
        'No gate allows this direction of travel.',
      );
    }

    NavError? firstRouteNotFound;
    for (final gate in gates) {
      NavRouteOption outsideLeg;
      try {
        final routes = await _osrm.computeRoutes(
          origin: origin,
          destination: gate.location,
        );
        if (routes.isEmpty) continue;
        outsideLeg = routes.first;
      } on NavError catch (error) {
        if (error.kind == NavErrorKind.routeNotFound) {
          firstRouteNotFound ??= error;
          continue;
        }
        rethrow;
      }

      NavRouteOption? insideLeg;
      try {
        final routes = await _osrm.computeRoutes(
          origin: gate.location,
          destination: destination,
        );
        if (routes.isNotEmpty) insideLeg = routes.first;
      } on NavError {
        insideLeg = null;
      }

      if (insideLeg != null) {
        final combined = _combineRoutes(outsideLeg, insideLeg, gate.name);
        if (_routeRespectsBoundary(
          combined,
          originInside: originInside,
          destinationInside: !originInside,
        )) {
          return [combined];
        }
      }

      final fallbackLeg = _buildDirectRoute(
        gate.location,
        destination,
        summary: originInside
            ? 'Leave campus via ${gate.name}'
            : 'Inside campus from ${gate.name}',
        instruction: originInside
            ? 'Exit through ${gate.name} and continue to your destination'
            : 'Walk inside the campus towards your destination',
      );
      final combined = _combineRoutes(outsideLeg, fallbackLeg, gate.name);
      if (_routeRespectsBoundary(
        combined,
        originInside: originInside,
        destinationInside: !originInside,
      )) {
        return [combined];
      }
    }

    if (firstRouteNotFound != null) throw firstRouteNotFound;

    NavRouteOption? directFallback;
    for (final gate in gates) {
      final toGateLeg = _buildDirectRoute(
        origin,
        gate.location,
        summary: 'Head to ${gate.name}',
        instruction: 'Head to ${gate.name}',
      );
      final fromGateLeg = _buildDirectInsideRoute(
        gate.location,
        destination,
        summary: originInside
            ? 'Leave campus via ${gate.name}'
            : 'Inside campus from ${gate.name}',
        instruction: originInside
            ? 'Exit through ${gate.name} and continue to your destination'
            : 'Walk inside the campus towards your destination',
      );
      final combined = _combineRoutes(toGateLeg, fromGateLeg, gate.name);
      if (_routeRespectsBoundary(
        combined,
        originInside: originInside,
        destinationInside: !originInside,
      )) {
        return [combined];
      }
      directFallback ??= combined;
    }
    return [directFallback!];
  }

  bool _routeRespectsBoundary(
    NavRouteOption route, {
    required bool originInside,
    required bool destinationInside,
  }) {
    final points = _routePoints(route);
    if (points.length < 2) return false;
    if (_isInsideCampus(points.first) != originInside) return false;
    if (_isInsideCampus(points.last) != destinationInside) return false;

    for (var i = 0; i < points.length - 1; i++) {
      final from = points[i];
      final to = points[i + 1];
      final crossings = _boundaryCrossings(from, to);
      if (crossings.isEmpty) {
        if (_isInsideCampus(from) != _isInsideCampus(to)) return false;
        continue;
      }
      for (final crossing in crossings) {
        if (!_isNearGate(crossing, entering: !originInside)) return false;
      }
    }
    return true;
  }

  List<NavLatLng> _routePoints(NavRouteOption route) {
    return route.overviewPoints.isNotEmpty
        ? route.overviewPoints
        : route.trackingPoints;
  }

  List<NavLatLng> _boundaryCrossings(NavLatLng from, NavLatLng to) {
    final crossings = <NavLatLng>[];
    for (var i = 0; i < _campusBoundary.length - 1; i++) {
      final crossing = _segmentIntersection(
        from,
        to,
        _campusBoundary[i],
        _campusBoundary[i + 1],
      );
      if (crossing != null) crossings.add(crossing);
    }
    return crossings;
  }

  NavLatLng? _segmentIntersection(
    NavLatLng a,
    NavLatLng b,
    NavLatLng c,
    NavLatLng d,
  ) {
    final x1 = a.longitude;
    final y1 = a.latitude;
    final x2 = b.longitude;
    final y2 = b.latitude;
    final x3 = c.longitude;
    final y3 = c.latitude;
    final x4 = d.longitude;
    final y4 = d.latitude;

    final denominator = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);
    if (denominator.abs() < 1e-12) return null;

    final t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denominator;
    final u = ((x1 - x3) * (y1 - y2) - (y1 - y3) * (x1 - x2)) / denominator;
    if (t < 0 || t > 1 || u < 0 || u > 1) return null;

    return NavLatLng(y1 + t * (y2 - y1), x1 + t * (x2 - x1));
  }

  bool _isNearGate(NavLatLng point, {required bool entering}) {
    for (final gate in CampusEntrances.all) {
      final allowed = entering ? _canEnterOnFoot(gate) : gate.walkInExit;
      if (!allowed) continue;
      if (GeoMath.distanceMeters(point, gate.location) <=
          _gateCrossingToleranceMeters) {
        return true;
      }
    }
    return false;
  }

  /// Applies the walk-in entry rules for the selected role. Without a role,
  /// retain the permissive behavior used before onboarding was added.
  bool _canEnterOnFoot(CampusEntrance gate) {
    if (!gate.walkInEntry) return false;
    switch (role) {
      case null:
        return true;
      case UserRole.student:
        return gate.id == CampusEntrances.entrance1.id ||
            gate.id == CampusEntrances.entrance5.id;
      case UserRole.faculty:
      case UserRole.ojt:
      case UserRole.visitor:
        return gate.id == CampusEntrances.entrance3.id ||
            gate.id == CampusEntrances.entrance5.id;
    }
  }

  bool _isInsideCampus(NavLatLng point) {
    return CampusBuildings.isPointInRing(point, _campusBoundary);
  }

  bool _isNearBuilding(NavLatLng point, NavLatLng buildingCenter) {
    return GeoMath.distanceMeters(point, buildingCenter) <=
        _buildingProximityRadius;
  }

  NavRouteOption _buildCustomMbAbRoute(
    NavLatLng origin,
    NavLatLng destination,
  ) {
    final path = _connectViaMbAbPath(origin, destination);
    return _buildRoute(
      path,
      summary: 'Campus Pathway (inside campus)',
      instruction:
          'Walk through the pathway connecting Main Building and Annex Building',
    );
  }

  List<NavLatLng> _connectViaMbAbPath(NavLatLng origin, NavLatLng destination) {
    final originIsAnnex = _isNearBuilding(
      origin,
      CampusBuildings.annexBuilding.labelPoint,
    );
    final destinationIsAnnex = _isNearBuilding(
      destination,
      CampusBuildings.annexBuilding.labelPoint,
    );

    if (originIsAnnex && destinationIsAnnex) {
      return _dedupe([origin, destination]);
    }
    if (destinationIsAnnex) {
      final projection = _nearestPointOnPath(origin, mbToAbPath);
      return _dedupe([origin, projection, mbToAbPath.last, destination]);
    }
    if (originIsAnnex) {
      final projection = _nearestPointOnPath(destination, mbToAbPath);
      return _dedupe([origin, mbToAbPath.last, projection, destination]);
    }
    final originProjection = _nearestPointOnPath(origin, mbToAbPath);
    final destinationProjection = _nearestPointOnPath(destination, mbToAbPath);
    return _dedupe([
      origin,
      originProjection,
      destinationProjection,
      destination,
    ]);
  }

  NavLatLng _nearestPointOnPath(NavLatLng point, List<NavLatLng> path) {
    NavLatLng best = path.first;
    var bestDistance = double.infinity;
    for (var i = 0; i < path.length - 1; i++) {
      final start = path[i];
      final end = path[i + 1];
      final projection = GeoMath.projectOntoSegment(point, start, end);
      final candidate = NavLatLng(
        start.latitude + (end.latitude - start.latitude) * projection.fraction,
        start.longitude +
            (end.longitude - start.longitude) * projection.fraction,
      );
      if (projection.distanceMeters < bestDistance) {
        bestDistance = projection.distanceMeters;
        best = candidate;
      }
    }
    return best;
  }

  NavRouteOption _buildDirectInsideRoute(
    NavLatLng origin,
    NavLatLng destination, {
    String summary = 'Campus route (inside campus)',
    String instruction = 'Walk inside the campus to your destination',
  }) {
    return _buildRoute(
      _dedupe([origin, destination]),
      summary: summary,
      instruction: instruction,
    );
  }

  NavRouteOption _buildDirectRoute(
    NavLatLng origin,
    NavLatLng destination, {
    required String summary,
    required String instruction,
  }) {
    return _buildRoute(
      _dedupe([origin, destination]),
      summary: summary,
      instruction: instruction,
    );
  }

  NavRouteOption _buildRoute(
    List<NavLatLng> points, {
    required String summary,
    required String instruction,
  }) {
    final distanceMeters = GeoMath.polylineLength(points);
    final durationSeconds = (distanceMeters / 1.4).round();
    final step = NavRouteStep(
      instruction: instruction,
      maneuver: 'continue',
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      points: points,
    );
    return NavRouteOption(
      summary: summary,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      overviewPoints: points,
      steps: [step],
    );
  }

  List<NavLatLng> _dedupe(List<NavLatLng> points) {
    final result = <NavLatLng>[];
    for (final point in points) {
      if (result.isEmpty || result.last != point) result.add(point);
    }
    return result;
  }

  NavRouteOption _combineRoutes(
    NavRouteOption leg1,
    NavRouteOption leg2,
    String gateName,
  ) {
    final leg1Points = _routePoints(leg1);
    final leg2Points = _routePoints(leg2);
    final skipFirst =
        leg1Points.isNotEmpty &&
        leg2Points.isNotEmpty &&
        leg1Points.last == leg2Points.first;
    final combinedPoints = [
      ...leg1Points,
      ...leg2Points.skip(skipFirst ? 1 : 0),
    ];
    final distance = leg1.distanceMeters + leg2.distanceMeters;
    final duration = leg1.durationSeconds + leg2.durationSeconds;

    final steps = <NavRouteStep>[
      ...leg1.steps,
      NavRouteStep(
        instruction: 'Pass through $gateName',
        maneuver: 'continue',
        distanceMeters: 0,
        durationSeconds: 30,
        points: [leg1Points.last, leg2Points.first],
      ),
      ...leg2.steps,
    ];

    return NavRouteOption(
      summary: 'Via $gateName',
      distanceMeters: distance,
      durationSeconds: duration,
      overviewPoints: combinedPoints,
      steps: steps,
    );
  }
}
