import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviapp/config/starting_locations.dart';
import 'package:naviapp/providers/user_location_provider.dart';
import 'package:naviapp/screens/floor_plan_screen.dart';
import 'package:naviapp/services/indoor_positioning/indoor_position.dart';
import 'package:naviapp/services/indoor_positioning/indoor_position_provider.dart';
import 'package:provider/provider.dart';

class _FakeIndoorPositionProvider extends IndoorPositionProvider {
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

Future<void> _pumpFloorPlan(
  WidgetTester tester,
  UserLocationProvider userLocation,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ChangeNotifierProvider<UserLocationProvider>.value(
        value: userLocation,
        child: FloorPlanScreen(positionProvider: _FakeIndoorPositionProvider()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('search finds a room and opens its floor', (tester) async {
    await _pumpFloorPlan(tester, UserLocationProvider());

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Navigate (Indoor)'), findsNothing);

    await tester.enterText(find.byType(TextField), 'library');
    await tester.pumpAndSettle();

    expect(find.text('Library'), findsOneWidget);

    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();

    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 2);
    expect(find.text('3rd Floor'), findsOneWidget);
  });

  testWidgets('a scanned location shows a compact You are here card', (
    tester,
  ) async {
    final location = StartingLocations.byId('GF_LOBBY_LEFT_STAIRCASE')!;
    final userLocation = UserLocationProvider()
      ..setFromStartingLocation(location);

    await _pumpFloorPlan(tester, userLocation);

    expect(find.text('You are here'), findsOneWidget);
    expect(find.text(location.name), findsNWidgets(2));
    expect(find.byTooltip('Clear location'), findsOneWidget);
    expect(find.text('Start Navigation'), findsNothing);
  });
}
