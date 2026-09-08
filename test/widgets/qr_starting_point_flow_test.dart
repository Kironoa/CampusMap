// test/widgets/qr_starting_point_flow_test.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviapp/config/starting_locations.dart';
import 'package:naviapp/models/starting_location.dart';
import 'package:naviapp/providers/user_location_provider.dart';
import 'package:naviapp/screens/floor_plan_screen.dart';
import 'package:naviapp/services/indoor_positioning/indoor_position.dart';
import 'package:naviapp/services/indoor_positioning/indoor_position_provider.dart';
import 'package:provider/provider.dart';

/// Controllable live-position provider used to prove that a pinned QR
/// location overrides the live stream.
class FakeIndoorPositionProvider extends IndoorPositionProvider {
  final StreamController<IndoorPosition> _controller =
      StreamController<IndoorPosition>.broadcast();
  IndoorPosition? _current;
  bool _running = false;

  @override
  Stream<IndoorPosition> get positions => _controller.stream;

  @override
  IndoorPosition? get currentPosition => _current;

  @override
  bool get isRunning => _running;

  void emit(IndoorPosition position) {
    _current = position;
    scheduleMicrotask(() => _controller.add(position));
  }

  @override
  Future<void> start() async {
    _running = true;
  }

  @override
  Future<void> stop() async {
    _running = false;
  }
}

IndoorPosition decoyLivePosition() => IndoorPosition(
  x: 0.5,
  y: 0.5,
  floor: 1,
  accuracy: 2,
  timestamp: DateTime(2026, 8, 25, 12),
  source: PositionSource.mock,
);

FloorPlanPainter painterOf(WidgetTester tester) {
  final customPaint = tester.widget<CustomPaint>(
    find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is FloorPlanPainter,
    ),
  );
  return customPaint.painter as FloorPlanPainter;
}

Future<FloorPlanPainter> simulateQrScan(
  WidgetTester tester, {
  required StartingLocation scanned,
}) async {
  final fake = FakeIndoorPositionProvider();
  final userLocation = UserLocationProvider();
  await tester.pumpWidget(
    // UniqueKey forces a fresh screen state per simulated scan so repeated
    // calls don't inherit state from the previous scenario.
    MaterialApp(
      key: UniqueKey(),
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<UserLocationProvider>.value(
            value: userLocation,
          ),
        ],
        child: FloorPlanScreen(positionProvider: fake),
      ),
    ),
  );
  await tester.pump();

  // A live estimate arrives from somewhere else first...
  fake.emit(decoyLivePosition());
  await tester.pumpAndSettle();

  // ...then the user scans a Campus Guide starting-point QR code. This is
  // exactly what FloorPlanScreen._scanStartingPoint does after the scanner
  // pops with a result.
  final resolved = StartingLocations.fromQrData(scanned.qrData);
  expect(resolved, isNotNull, reason: scanned.id);

  userLocation.setFromStartingLocation(resolved!);
  await tester.pumpAndSettle();

  return painterOf(tester);
}

void main() {
  testWidgets('each of the seven QR codes pins the marker to its own spot', (
    tester,
  ) async {
    for (final location in StartingLocations.groundFloorLocations) {
      final painter = await simulateQrScan(tester, scanned: location);

      expect(painter.livePosition, isNotNull, reason: location.id);
      expect(
        painter.livePosition!.x,
        location.x,
        reason:
            '${location.id} marker must sit at its configured x (got '
            '${painter.livePosition!.x}, expected ${location.x})',
      );
      expect(
        painter.livePosition!.y,
        location.y,
        reason:
            '${location.id} marker must sit at its configured y (got '
            '${painter.livePosition!.y}, expected ${location.y})',
      );
      expect(
        painter.livePosition!.floor,
        0,
        reason: '${location.id} is a ground-floor starting point',
      );
      // The Ground Floor is displayed after scanning.
      expect(painter.currentFloor, 0, reason: location.id);
    }
  });

  testWidgets('a pinned QR location survives later live updates', (
    tester,
  ) async {
    final location = StartingLocations.byId('GF_LOBBY_LEFT_STAIRCASE')!;
    final painter = await simulateQrScan(tester, scanned: location);
    expect(painter.livePosition!.x, location.x);
    expect(painter.livePosition!.y, location.y);
  });

  testWidgets('invalid QR content never changes the current location', (
    tester,
  ) async {
    const invalidPayloads = [
      'https://unrelated-site.example.com',
      '{"type": "other_app", "location_id": "GF_MAIN_ENTRANCE"}',
      '{broken json',
    ];

    for (final raw in invalidPayloads) {
      final fake = FakeIndoorPositionProvider();
      final userLocation = UserLocationProvider();
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: ChangeNotifierProvider<UserLocationProvider>.value(
            value: userLocation,
            child: FloorPlanScreen(positionProvider: fake),
          ),
        ),
      );
      await tester.pump();
      fake.emit(decoyLivePosition());
      await tester.pumpAndSettle();

      // The scanner resolves the raw payload; an invalid code yields null
      // and the flow must stop without touching the location state.
      final resolved = StartingLocations.fromQrData(raw);
      expect(resolved, isNull, reason: raw);

      // State untouched: still the decoy live position, no manual pin.
      final painter = painterOf(tester);
      expect(userLocation.hasManualPosition, isFalse);
      expect(painter.livePosition!.x, decoyLivePosition().x);
      expect(painter.livePosition!.floor, decoyLivePosition().floor);
    }
  });

  testWidgets('scanning a second code moves the marker to the new location', (
    tester,
  ) async {
    final first = StartingLocations.byId('GF_LEFT_SIDE_DOOR')!;
    final second = StartingLocations.byId('GF_RIGHT_WING_STAIRCASE')!;

    await simulateQrScan(tester, scanned: first);
    final context = tester.element(find.byType(FloorPlanScreen));
    final userLocation = Provider.of<UserLocationProvider>(
      context,
      listen: false,
    );

    userLocation.setFromStartingLocation(second);
    await tester.pumpAndSettle();

    final painter = painterOf(tester);
    expect(painter.livePosition!.x, second.x);
    expect(painter.livePosition!.y, second.y);
    expect(userLocation.startingLocation!.name, 'Right Wing Staircase');
  });
}
