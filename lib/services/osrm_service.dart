import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

class RouteInfo {
  final List<LatLng> points;
  final double distance;
  final String distanceText;
  final String timeText;

  RouteInfo({
    required this.points,
    required this.distance,
    required this.distanceText,
    required this.timeText,
  });
}

class OSRMRouteService {
  static const String _baseUrl = 'http://router.project-osrm.org/route/v1/walking';

  static Future<RouteInfo?> getRoute(LatLng origin, LatLng destination) async {
    try {
      final dio = Dio();
      final url = '$_baseUrl/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson';
      
      final response = await dio.get(url);
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final distance = (route['distance'] as num?)?.toDouble() ?? calculateDistance(origin, destination);
          return RouteInfo(
            points: _decodeGeoJSON(geometry),
            distance: distance,
            distanceText: formatDistance(distance),
            timeText: formatWalkingTime(distance),
          );
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static List<LatLng> _decodeGeoJSON(Map<String, dynamic> geometry) {
    final coords = geometry['coordinates'] as List<dynamic>;
    return coords.map((c) {
      final coord = c as List<dynamic>;
      return LatLng(coord[1] as double, coord[0] as double);
    }).toList();
  }

  static double calculateDistance(LatLng origin, LatLng destination) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, origin, destination);
  }

  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  static String formatWalkingTime(double meters) {
    const double walkingSpeed = 1.4;
    final int minutes = (meters / (walkingSpeed * 60)).round();
    if (minutes < 1) return '< 1 min';
    if (minutes == 1) return '1 min';
    return '$minutes mins';
  }
}