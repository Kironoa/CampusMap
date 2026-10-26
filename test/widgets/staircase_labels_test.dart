// test/widgets/staircase_labels_test.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviapp/providers/user_location_provider.dart';
import 'package:naviapp/screens/floor_plan_screen.dart';
import 'package:naviapp/services/indoor_positioning/indoor_position.dart';
import 'package:naviapp/services/indoor_positioning/indoor_position_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class FakeIndoorPositionProvider extends IndoorPositionProvider {
  final StreamController<IndoorPosition> _controller =
      StreamController<IndoorPosition>.broadcast();
  bool _running = false;

  @override
  Stream<IndoorPosition> get positions => _controller.stream;

  @override
  IndoorPosition? get currentPosition => null;

  @override
  bool get isRunning => _running;

  @override
  Future<void> start() async {
    _running = true;
  }

  @override
  Future<void> stop() async {
    _running = false;
  }
}

Future<void> pumpFloorPlan(WidgetTester tester, {int floor = 0}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ChangeNotifierProvider.value(
        value: UserLocationProvider(),
        child: FloorPlanScreen(
          initialFloor: floor,
          positionProvider: FakeIndoorPositionProvider(),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('every floor shows a label for each of its staircases', (
    tester,
  ) async {
    await pumpFloorPlan(tester);

    expect(find.text('Lobby Left Staircase'), findsOneWidget);
    expect(find.text('Lobby Right Staircase'), findsOneWidget);
    expect(find.text('Left Wing Staircase'), findsOneWidget);
    expect(find.text('Right Wing Staircase'), findsOneWidget);

    await tester.tap(find.text('2nd'));
    await tester.pumpAndSettle();

    expect(find.text('Left Staircase'), findsOneWidget);
    expect(find.text('Center Staircase'), findsOneWidget);
    expect(find.text('Right Staircase'), findsOneWidget);
    expect(find.text('Bottom Left Staircase'), findsOneWidget);
    expect(find.text('Bottom Right Staircase'), findsOneWidget);

    await tester.tap(find.text('3rd'));
    await tester.pumpAndSettle();

    expect(find.text('Left Staircase'), findsOneWidget);
    expect(find.text('Right Staircase'), findsOneWidget);
    expect(find.text('Top Left Staircase'), findsOneWidget);
  });

  testWidgets('tapping a staircase label opens its QR code', (tester) async {
    await pumpFloorPlan(tester);

    await tester.tap(find.text('Left Wing Staircase'));
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Ground · GF_LEFT_WING_STAIRCASE'), findsOneWidget);
  });

  testWidgets('app bar action lists every staircase QR on the floor', (
    tester,
  ) async {
    await pumpFloorPlan(tester, floor: 1);

    await tester.tap(find.byTooltip('Staircase QR codes'));
    await tester.pumpAndSettle();

    expect(find.text('Staircase QR Codes'), findsOneWidget);
    expect(find.text('2nd Floor · 5 staircases'), findsOneWidget);
  });

  testWidgets('third floor label opens the matching staircase QR', (
    tester,
  ) async {
    await pumpFloorPlan(tester, floor: 2);

    await tester.tap(find.text('Top Left Staircase'));
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('3rd Floor · TF_TOP_LEFT_STAIRCASE'), findsOneWidget);
  });

  testWidgets('staircase QR sheet fits a small landscape screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(700, 360);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpFloorPlan(tester, floor: 1);
    await tester.tap(find.byTooltip('Staircase QR codes'));
    await tester.pumpAndSettle();

    expect(find.text('2nd Floor · 5 staircases'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
