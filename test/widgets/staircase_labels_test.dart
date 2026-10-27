// test/widgets/staircase_labels_test.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviapp/providers/user_location_provider.dart';
import 'package:naviapp/screens/floor_plan_screen.dart';
import 'package:naviapp/services/indoor_positioning/indoor_position.dart';
import 'package:naviapp/services/indoor_positioning/indoor_position_provider.dart';
import 'package:provider/provider.dart';

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

  testWidgets('staircase labels do not expose QR codes', (tester) async {
    await pumpFloorPlan(tester);

    await tester.tap(find.text('Left Wing Staircase'));
    await tester.pumpAndSettle();

    expect(find.text('Staircase QR Codes'), findsNothing);
    expect(find.byTooltip('Staircase QR codes'), findsNothing);
    expect(find.textContaining('GF_LEFT_WING_STAIRCASE'), findsNothing);
  });
}
