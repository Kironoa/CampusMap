// lib/features/live_navigation/models/geo_math.dart
//
// Pure-Dart geographic math (no Flutter/plugin imports) so route guidance
// stays unit-testable on the VM.
import 'dart:math' as math;

/// Plugin-free latitude/longitude point used across the feature.
/// Convert to the map SDK point type only at the UI boundary.
class NavLatLng {
  const NavLatLng(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      other is NavLatLng &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'NavLatLng($latitude, $longitude)';
}

/// Result of projecting a point onto a route segment.
class SegmentProjection {
  const SegmentProjection({
    required this.fraction,
    required this.distanceMeters,
  });

  /// Position along the segment in [0, 1] (0 = start, 1 = end).
  final double fraction;

  /// Perpendicular distance from the point to the segment, in meters.
  final double distanceMeters;
}

class GeoMath {
  GeoMath._();

  static const double earthRadiusMeters = 6371000.0;

  static double _radians(double degrees) => degrees * math.pi / 180.0;

  /// Haversine distance between two points, in meters.
  static double distanceMeters(NavLatLng a, NavLatLng b) {
    final dLat = _radians(b.latitude - a.latitude);
    final dLng = _radians(b.longitude - a.longitude);
    final s1 = math.sin(dLat / 2);
    final s2 = math.sin(dLng / 2);
    final h =
        s1 * s1 +
        math.cos(_radians(a.latitude)) *
            math.cos(_radians(b.latitude)) *
            s2 *
            s2;
    return 2 * earthRadiusMeters * math.asin(math.sqrt(h.clamp(0.0, 1.0)));
  }

  /// Initial bearing from [a] to [b] in degrees [0, 360).
  static double bearingDegrees(NavLatLng a, NavLatLng b) {
    final lat1 = _radians(a.latitude);
    final lat2 = _radians(b.latitude);
    final dLng = _radians(b.longitude - a.longitude);
    final y = math.sin(dLng) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return (math.atan2(y, x) * 180.0 / math.pi + 360.0) % 360.0;
  }

  /// Projects [p] onto segment [a]→[b] using an equirectangular
  /// approximation (accurate for the short segments used in guidance).
  static SegmentProjection projectOntoSegment(
    NavLatLng p,
    NavLatLng a,
    NavLatLng b,
  ) {
    final meanLat = _radians((a.latitude + b.latitude) / 2.0);
    final cosLat = math.cos(meanLat);
    double px = _radians(p.longitude) * cosLat;
    double py = _radians(p.latitude);
    final ax = _radians(a.longitude) * cosLat;
    final ay = _radians(a.latitude);
    final bx = _radians(b.longitude) * cosLat;
    final by = _radians(b.latitude);

    final dx = bx - ax;
    final dy = by - ay;
    final lenSq = dx * dx + dy * dy;
    double t = 0.0;
    if (lenSq > 0) {
      t = ((px - ax) * dx + (py - ay) * dy) / lenSq;
      t = t.clamp(0.0, 1.0);
    }
    final cx = ax + dx * t;
    final cy = ay + dy * t;
    final distRad = math.sqrt(
      (px - cx) * (px - cx) + (py - cy) * (py - cy),
    );
    return SegmentProjection(
      fraction: t,
      distanceMeters: distRad * earthRadiusMeters,
    );
  }

  /// Total length of a polyline in meters.
  static double polylineLength(List<NavLatLng> points) {
    if (points.length < 2) return 0.0;
    var total = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      total += distanceMeters(points[i], points[i + 1]);
    }
    return total;
  }

  /// Decodes a Google encoded polyline into a point list.
  /// Returns [] for empty/invalid input instead of throwing.
  static List<NavLatLng> decodePolyline(String encoded) {
    final points = <NavLatLng>[];
    if (encoded.isEmpty) return points;
    try {
      var index = 0;
      var lat = 0;
      var lng = 0;
      while (index < encoded.length) {
        var shift = 0;
        var result = 0;
        int byte;
        do {
          if (index >= encoded.length) return points;
          byte = encoded.codeUnitAt(index++) - 63;
          result |= (byte & 0x1F) << shift;
          shift += 5;
        } while (byte >= 0x20);
        final dLat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
        lat += dLat;

        shift = 0;
        result = 0;
        do {
          if (index >= encoded.length) return points;
          byte = encoded.codeUnitAt(index++) - 63;
          result |= (byte & 0x1F) << shift;
          shift += 5;
        } while (byte >= 0x20);
        final dLng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
        lng += dLng;

        points.add(NavLatLng(lat / 1e5, lng / 1e5));
      }
    } catch (_) {
      return points;
    }
    return points;
  }

  /// Parses a Routes/Places API duration string like "321s" into seconds.
  /// Returns 0 when unparseable.
  static int parseDurationSeconds(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) {
      final digits = RegExp(r'\d+').firstMatch(value);
      if (digits != null) return int.tryParse(digits.group(0)!) ?? 0;
    }
    return 0;
  }

  /// Parses a distance value that may be int/double/String into meters.
  static double parseDistanceMeters(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}




