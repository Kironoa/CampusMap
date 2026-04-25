import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';

class DirectionsService {
  static const String _directionsBaseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  static Future<List<LatLng>> getRoute(
    LatLng origin,
    LatLng destination,
    String apiKey,
  ) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        _directionsBaseUrl,
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'mode': 'walking',
          'key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final overviewPolyline = route['overview_polyline']['points'] as String;
          return _decodePolyline(overviewPolyline);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> poly = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      poly.add(LatLng(
        lat / 1E5,
        lng / 1E5,
      ));
    }

    return poly;
  }

  static double calculateDistance(LatLng origin, LatLng destination) {
    const double earthRadius = 6371000;
    final double lat1Rad = origin.latitude * math.pi / 180;
    final double lat2Rad = destination.latitude * math.pi / 180;
    final double deltaLat = (destination.latitude - origin.latitude) * math.pi / 180;
    final double deltaLng = (destination.longitude - origin.longitude) * math.pi / 180;

    final double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLng / 2) * math.sin(deltaLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
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