// test/features/live_nav/guidance_engine_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:naviapp/features/live_navigation/models/geo_math.dart';
import 'package:naviapp/features/live_navigation/models/nav_route.dart';
import 'package:naviapp/features/live_navigation/services/guidance_engine.dart';

/// Builds a simple L-shaped route: east 100m (step 0), then north 100m (step 1).
NavRouteOption buildTestRoute() {
  NavLatLng east(double meters) =>
      NavLatLng(8.0, 123.0 + meters / 111320.0);
  NavLatLng north(double meters) =>
      NavLatLng(8.0 + meters / 110574.0, 123.0 + 100 / 111320.0);

  final step0Points = [for (var m = 0; m <= 100; m += 20) east(m.toDouble())];
  final step1Points = [for (var m = 0; m <= 100; m += 20) north(m.toDouble())];
  return NavRouteOption(
    summary: 'Test route',
    distanceMeters: 200,
    durationSeconds: 60,
    overviewPoints: [...step0Points, ...step1Points.skip(1)],
    steps: [
      NavRouteStep(
        instruction: 'Head east',
        maneuver: 'STRAIGHT',
        distanceMeters: 100,
        durationSeconds: 30,
        points: step0Points,
      ),
      NavRouteStep(
        instruction: 'Turn left',
        maneuver: 'TURN_LEFT',
        distanceMeters: 100,
        durationSeconds: 30,
        points: step1Points,
      ),
    ],
  );
}

void main() {
  group('GuidanceEngine', () {
    test('first fix reports step 0 with distance to maneuver', () {
      final engine = GuidanceEngine();
      engine.setRoute(buildTestRoute());
      final snap = engine.update(
        position: const NavLatLng(8.0, 123.0),
        speedMps: 8,
        now: DateTime(2026, 1, 1, 8),
      );
      expect(snap.stepIndex, 0);
      expect(snap.instruction, 'Head east');
      expect(snap.distanceToManeuverM, closeTo(100, 5));
      expect(snap.remainingDistanceM, closeTo(200, 5));
      expect(snap.arrived, isFalse);
      expect(snap.offRoute, isFalse);
    });

    test('advances to step 1 after the corner', () {
      final engine = GuidanceEngine();
      engine.setRoute(buildTestRoute());
      var now = DateTime(2026, 1, 1, 8);
      // Walk along step 0.
      for (var m = 0; m <= 100; m += 20) {
        now = now.add(const Duration(seconds: 3));
        engine.update(
          position: NavLatLng(8.0, 123.0 + m / 111320.0),
          speedMps: 8,
          now: now,
        );
      }
      // Enter step 1 heading north.
      final snap = engine.update(
        position: const NavLatLng(8.0 + 30 / 110574.0, 123.0 + 100 / 111320.0),
        speedMps: 8,
        now: now.add(const Duration(seconds: 3)),
      );
      expect(snap.stepIndex, 1);
      expect(snap.instruction, 'Turn left');
    });

    test('signals reroute after consecutive off-route fixes', () {
      final engine = GuidanceEngine(
        offRouteDeviationMeters: 60,
        offRouteFixesRequired: 3,
        rerouteCooldown: Duration.zero,
      );
      engine.setRoute(buildTestRoute());
      const farAway = NavLatLng(8.05, 123.05); // ~km away
      var now = DateTime(2026, 1, 1, 8);
      // First two strays: no signal yet.
      for (var i = 0; i < 2; i++) {
        now = now.add(const Duration(seconds: 2));
        final snap = engine.update(
          position: farAway,
          speedMps: 8,
          now: now,
        );
        expect(snap.offRoute, isTrue);
        expect(engine.takeRerouteSignal(now), isFalse);
      }
      // Third stray: signal fires exactly once.
      now = now.add(const Duration(seconds: 2));
      engine.update(position: farAway, speedMps: 8, now: now);
      expect(engine.takeRerouteSignal(now), isTrue);
      expect(engine.takeRerouteSignal(now), isFalse);
    });

    test('respects reroute cooldown', () {
      final engine = GuidanceEngine(
        offRouteDeviationMeters: 60,
        offRouteFixesRequired: 1,
        rerouteCooldown: const Duration(minutes: 5),
      );
      engine.setRoute(buildTestRoute());
      final now = DateTime(2026, 1, 1, 8);
      const farAway = NavLatLng(8.05, 123.05);
      engine.update(position: farAway, speedMps: 8, now: now);
      expect(engine.takeRerouteSignal(now), isTrue);
      // Cooldown active even though still off-route.
      final later = now.add(const Duration(minutes: 1));
      engine.update(position: farAway, speedMps: 8, now: later);
      expect(engine.takeRerouteSignal(later), isFalse);
    });

    test('reports arrival at the destination', () {
      final engine = GuidanceEngine(arrivalRadiusMeters: 30);
      final route = buildTestRoute();
      engine.setRoute(route);
      var now = DateTime(2026, 1, 1, 8);
      // Walk the whole route first so progress is near the end.
      for (final p in route.trackingPoints) {
        now = now.add(const Duration(seconds: 2));
        engine.update(position: p, speedMps: 8, now: now);
      }
      final snap = engine.update(
        position: route.trackingPoints.last,
        speedMps: 2,
        now: now.add(const Duration(seconds: 2)),
      );
      expect(snap.arrived, isTrue);
    });
  });
}


