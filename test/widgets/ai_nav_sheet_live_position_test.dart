import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviapp/services/indoor_positioning/indoor_position.dart';
import 'package:naviapp/services/navigation_graph.dart';
import 'package:naviapp/services/pathfinder.dart';
import 'package:naviapp/services/route_calculator.dart';
import 'package:naviapp/widgets/ai_nav_sheet.dart';

IndoorPosition livePosition(double x, double y, int floor) => IndoorPosition(
  x: x,
  y: y,
  floor: floor,
  accuracy: 2.0,
  timestamp: DateTime(2026, 8, 20, 12, 0, 0),
  source: PositionSource.mock,
);

void main() {
  testWidgets('sheet skips the starting-point step when live position exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => AINavSheet(
                    currentFloorIndex: 2,
                    livePosition: livePosition(0.62, 0.71, 2),
                    onNavigationResult: (result) {},
                  ),
                ),
                child: const Text('Open sheet'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();

    // Already on the destination-selection step, not the start selector.
    expect(find.text('🏁 Where do you want to go?'), findsOneWidget);
    expect(find.text('📍 Where are you starting from?'), findsNothing);
    // No "Starting from your live location" text anymore
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('selecting a destination routes from the live position', (
    tester,
  ) async {
    NavigationResult? captured;
    final position = livePosition(0.62, 0.71, 2);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => AINavSheet(
                    currentFloorIndex: 2,
                    livePosition: position,
                    onNavigationResult: (result) => captured = result,
                  ),
                ),
                child: const Text('Open sheet'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();

    // Scroll to find the room and tap it
    await tester.dragUntilVisible(
      find.text('Rest Room (Left)'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rest Room (Left)'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.hasPath, isTrue);
    expect(captured!.roomId, 'tf_restroom_left');
    expect(captured!.floorIndex, 2);

    // The route starts at the nearest node to the live position,
    // NOT at the floor's default entrance (tf_start_left).
    final expectedStart = Pathfinder.findNearestNodeToPosition(
      position.asOffset,
      position.floor,
    );
    final expectedNode = NavigationGraph.nodesForFloor(
      2,
    ).firstWhere((n) => n.id == expectedStart);
    expect(captured!.path.first, expectedNode.pos);
    expect(
      captured!.path.first,
      isNot(
        NavigationGraph.nodesForFloor(
          2,
        ).firstWhere((n) => n.id == 'tf_start_left').pos,
      ),
    );
  });

  testWidgets(
    'without live position, shows room list immediately (no starting-point step)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AINavSheet(
                      currentFloorIndex: 0,
                      onNavigationResult: (result) {},
                    ),
                  ),
                  child: const Text('Open sheet'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();

      // Immediately shows room list, no starting point step
      expect(find.text('📍 Where are you starting from?'), findsNothing);
      expect(find.text('🏁 Where do you want to go?'), findsOneWidget);
      expect(find.text('Main Lobby'), findsOneWidget);
      // No search bar
      expect(find.byType(TextField), findsNothing);
    },
  );
}

extension on IndoorPosition {
  Offset get asOffset => Offset(x, y);
}
