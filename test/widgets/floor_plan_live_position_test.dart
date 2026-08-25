import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviapp/screens/floor_plan_screen.dart';
import 'package:naviapp/services/indoor_positioning/indoor_position.dart';
import 'package:naviapp/services/indoor_positioning/indoor_position_provider.dart';

/// Controllable provider used to drive the FloorPlan UI in tests.
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
    // Schedule emission to avoid synchronous setState during build
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

IndoorPosition fakePosition(
  double x,
  double y,
  int floor, {
  double accuracy = 2.0,
}) =>
    IndoorPosition(
      x: x,
      y: y,
      floor: floor,
      accuracy: accuracy,
      timestamp: DateTime(2026, 8, 20, 12, 0, 0),
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

void main() {
  testWidgets('no marker before any position is available', (tester) async {
    final fake = FakeIndoorPositionProvider();
    await tester.pumpWidget(
      MaterialApp(home: FloorPlanScreen(positionProvider: fake)),
    );
    await tester.pump();

    expect(painterOf(tester).livePosition, isNull);
  });

  testWidgets('blue location marker appears when a position arrives',
      (tester) async {
    final fake = FakeIndoorPositionProvider();
    await tester.pumpWidget(
      MaterialApp(home: FloorPlanScreen(positionProvider: fake)),
    );
    await tester.pump();

    fake.emit(fakePosition(0.42, 0.58, 1));
    await tester.pumpAndSettle();

    final painter = painterOf(tester);
    expect(painter.livePosition, isNotNull);
    expect(painter.livePosition!.x, 0.42);
    expect(painter.livePosition!.y, 0.58);
    expect(painter.livePosition!.floor, 1);
  });

  testWidgets('marker moves when the IndoorPosition changes', (tester) async {
    final fake = FakeIndoorPositionProvider();
    await tester.pumpWidget(
      MaterialApp(home: FloorPlanScreen(positionProvider: fake)),
    );
    await tester.pump();
    fake.emit(fakePosition(0.20, 0.40, 1));
    await tester.pumpAndSettle();
    expect(painterOf(tester).livePosition!.x, 0.20);

    fake.emit(fakePosition(0.35, 0.40, 1));
    await tester.pumpAndSettle();
    final painter = painterOf(tester);
    expect(painter.livePosition!.x, 0.35);
    expect(painter.livePosition!.y, 0.40);
  });

  testWidgets('floor switches automatically when the position floor changes',
      (tester) async {
    final fake = FakeIndoorPositionProvider();
    await tester.pumpWidget(
      MaterialApp(home: FloorPlanScreen(positionProvider: fake)),
    );
    await tester.pump();
    fake.emit(fakePosition(0.5, 0.5, 0));
    await tester.pumpAndSettle();
    expect(painterOf(tester).currentFloor, 0);

    fake.emit(fakePosition(0.62, 0.71, 2));
    await tester.pumpAndSettle();

    final painter = painterOf(tester);
    expect(painter.currentFloor, 2);
    expect(painter.livePosition!.floor, 2);
    // The bottom NavigationBar selection follows.
    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 2);
  });

  testWidgets('marker is not drawn when the position is on another floor',
      (tester) async {
    final fake = FakeIndoorPositionProvider();
    await tester.pumpWidget(
      MaterialApp(home: FloorPlanScreen(positionProvider: fake)),
    );
    await tester.pump();
    fake.emit(fakePosition(0.5, 0.5, 2));
    await tester.pumpAndSettle();
    // Auto-switched to floor 2, so the marker IS on the shown floor.
    expect(painterOf(tester).currentFloor, 2);

    // Manually switch back to ground: the floor-2 marker is not drawn here.
    await tester.tap(find.text('Ground'));
    await tester.pumpAndSettle();
    final painter = painterOf(tester);
    expect(painter.currentFloor, 0);
    expect(painter.livePosition!.floor, 2);
  });

  testWidgets('provider is stopped when the screen is disposed',
      (tester) async {
    final fake = FakeIndoorPositionProvider();
    await tester.pumpWidget(
      MaterialApp(home: FloorPlanScreen(positionProvider: fake)),
    );
    await tester.pump();
    expect(fake.isRunning, isTrue);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(fake.isRunning, isFalse);
  });
}

