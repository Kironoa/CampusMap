// test/features/live_nav/geo_math_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:naviapp/features/live_navigation/models/geo_math.dart';

void main() {
  group('GeoMath.distanceMeters', () {
    test('same point is zero', () {
      const p = NavLatLng(8.0625, 123.7458);
      expect(GeoMath.distanceMeters(p, p), 0.0);
    });

    test('known distance: 1 degree latitude ~ 111km', () {
      const a = NavLatLng(8.0, 123.0);
      const b = NavLatLng(9.0, 123.0);
      expect(GeoMath.distanceMeters(a, b), closeTo(111195, 200));
    });
  });

  group('GeoMath.bearingDegrees', () {
    test('due north is 0, due east is 90', () {
      const a = NavLatLng(8.0, 123.0);
      expect(GeoMath.bearingDegrees(a, const NavLatLng(9.0, 123.0)), closeTo(0, 0.5));
      expect(GeoMath.bearingDegrees(a, const NavLatLng(8.0, 124.0)), closeTo(90, 0.5));
    });
  });

  group('GeoMath.projectOntoSegment', () {
    test('midpoint projects to 0.5 with ~0 distance', () {
      const a = NavLatLng(8.0, 123.0);
      const b = NavLatLng(8.0, 124.0);
      const mid = NavLatLng(8.0, 123.5);
      final proj = GeoMath.projectOntoSegment(mid, a, b);
      expect(proj.fraction, closeTo(0.5, 0.01));
      expect(proj.distanceMeters, lessThan(5));
    });

    test('far point clamps and reports large distance', () {
      const a = NavLatLng(8.0, 123.0);
      const b = NavLatLng(8.0, 123.001);
      const far = NavLatLng(9.0, 124.0);
      final proj = GeoMath.projectOntoSegment(far, a, b);
      expect(proj.distanceMeters, greaterThan(10000));
    });
  });

  group('GeoMath.decodePolyline', () {
    test('empty input returns empty list', () {
      expect(GeoMath.decodePolyline(''), isEmpty);
    });

    test('decodes documented example polyline', () {
      // Example from Google's polyline documentation.
      const encoded = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';
      final points = GeoMath.decodePolyline(encoded);
      expect(points.length, 3);
      expect(points[0].latitude, closeTo(38.5, 1e-4));
      expect(points[0].longitude, closeTo(-120.2, 1e-4));
      expect(points[2].latitude, closeTo(43.252, 1e-4));
      expect(points[2].longitude, closeTo(-126.453, 1e-4));
    });

    test('truncated input does not throw', () {
      expect(GeoMath.decodePolyline('_p~iF'), isNotNull);
    });
  });

  group('GeoMath parsers', () {
    test('parseDurationSeconds handles "321s" and numbers', () {
      expect(GeoMath.parseDurationSeconds('321s'), 321);
      expect(GeoMath.parseDurationSeconds(45), 45);
      expect(GeoMath.parseDurationSeconds(null), 0);
      expect(GeoMath.parseDurationSeconds('n/a'), 0);
    });

    test('parseDistanceMeters handles numbers and strings', () {
      expect(GeoMath.parseDistanceMeters(1500), 1500.0);
      expect(GeoMath.parseDistanceMeters('12.5'), 12.5);
      expect(GeoMath.parseDistanceMeters(null), 0.0);
    });
  });
}


