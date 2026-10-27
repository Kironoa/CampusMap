// test/widgets/live_navigation_initial_destination_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviapp/features/live_navigation/config/campus_buildings.dart';
import 'package:naviapp/features/live_navigation/models/geo_math.dart';
import 'package:naviapp/features/live_navigation/models/nav_route.dart';
import 'package:naviapp/features/live_navigation/models/navigation_state.dart';
import 'package:naviapp/features/live_navigation/providers/location/location_provider.dart';
import 'package:naviapp/features/live_navigation/providers/map/map_provider.dart';
import 'package:naviapp/features/live_navigation/providers/routing/routing_service.dart';
import 'package:naviapp/features/live_navigation/ui/navigation_screen.dart';

class _FakeMapProvider implements MapProvider {
  @override
  String get styleUrl => 'about:blank';

  @override
  Widget buildMap({
    required MapViewState state,
    required MapViewCallbacks callbacks,
    required NavLatLng initialCenter,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      callbacks.onStyleLoaded?.call();
    });
    return const ColoredBox(color: Colors.grey);
  }
}

class _FakeLocationProvider implements LocationProvider {
  _FakeLocationProvider(this.fix);

  final NavFix fix;

  @override
  Future<LocationReadiness> ensureReady() async => LocationReadiness.ready;

  @override
  Future<NavFix> currentFix({Duration? timeout}) async => fix;

  @override
  Stream<NavFix> liveFixes() => const Stream.empty();

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationSettings() async {}
}

class _RecordingRoutingService implements RoutingService {
  NavLatLng? origin;
  NavLatLng? destination;

  @override
  Future<List<NavRouteOption>> computeRoutes({
    required NavLatLng origin,
    required NavLatLng destination,
  }) async {
    this.origin = origin;
    this.destination = destination;
    final distance = GeoMath.distanceMeters(origin, destination);
    return [
      NavRouteOption(
        summary: 'Test route',
        distanceMeters: distance,
        durationSeconds: (distance / 1.4).round(),
        overviewPoints: [origin, destination],
        steps: [
          NavRouteStep(
            instruction: 'Walk to the Annex Building',
            maneuver: 'continue',
            distanceMeters: distance,
            durationSeconds: (distance / 1.4).round(),
            points: [origin, destination],
          ),
        ],
      ),
    ];
  }
}

void main() {
  testWidgets('initial destination routes from the current position', (
    tester,
  ) async {
    final fix = NavFix(
      latitude: 8.065037,
      longitude: 123.756237,
      accuracyM: 5,
      timestamp: DateTime(2026, 1, 1),
    );
    final routing = _RecordingRoutingService();
    final annex = CampusBuildings.annexBuilding.labelPoint;

    await tester.pumpWidget(
      MaterialApp(
        home: LiveNavigationScreen(
          mapProvider: _FakeMapProvider(),
          locationProvider: _FakeLocationProvider(fix),
          routingService: routing,
          initialDestination: NavDestination(
            label: CampusBuildings.annexBuilding.name,
            location: annex,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(routing.origin, NavLatLng(fix.latitude, fix.longitude));
    expect(routing.destination, annex);
    expect(find.text('Annex Building'), findsOneWidget);
    expect(find.textContaining('Starting from QR location'), findsNothing);
  });
}
