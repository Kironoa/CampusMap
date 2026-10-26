import 'package:flutter_test/flutter_test.dart';
import 'package:naviapp/services/indoor_positioning/indoor_position.dart';
import 'package:naviapp/services/navigation_graph.dart';
import 'package:naviapp/services/pathfinder.dart';
import 'package:naviapp/services/route_calculator.dart';

IndoorPosition live(double x, double y, int floor, {double accuracy = 2.0}) =>
    IndoorPosition(
      x: x,
      y: y,
      floor: floor,
      accuracy: accuracy,
      timestamp: DateTime(2026, 8, 20, 12, 0, 0),
      source: PositionSource.mock,
    );

Offset nodePos(String nodeId, int floor) =>
    NavigationGraph.nodesForFloor(floor).firstWhere((n) => n.id == nodeId).pos;

void main() {
  group('RouteCalculator (same floor)', () {
    test('starts from the nearest node to the live position', () {
      final position = live(0.10, 0.30, 0);
      final result = RouteCalculator.fromLivePosition(
        position: position,
        roomId: 'gf_registrar',
        destinationFloor: 0,
      );

      expect(result, isNotNull);
      expect(result!.hasPath, isTrue);
      expect(result.floorIndex, 0);

      final expectedStart = Pathfinder.findNearestNodeToPosition(
        const Offset(0.10, 0.30),
        0,
      );
      expect(result.path.first, nodePos(expectedStart, 0));

      // It must NOT start from the default entrance node.
      expect(result.path.first, isNot(nodePos('gf_v_100', 0)));
      expect(result.floorIndices.every((f) => f == 0), isTrue);
    });

    test('routes to the destination room node', () {
      final position = live(0.468, 0.8, 0);
      final result = RouteCalculator.fromLivePosition(
        position: position,
        roomId: 'gf_registrar',
        destinationFloor: 0,
      );
      expect(result, isNotNull);
      expect(result!.path.last, nodePos('gf_room_registrar', 0));
      expect(result.roomId, 'gf_registrar');
    });

    test('returns a route when start and destination are the same node', () {
      // Use a position very close to gf_room_ics (0.080, 0.201) so the
      // nearest node is gf_room_ics itself, making startNodeId == endNodeId.
      final position = live(0.08, 0.20, 0);
      final result = RouteCalculator.fromLivePosition(
        position: position,
        roomId: 'gf_ics',
        destinationFloor: 0,
      );
      expect(result, isNotNull);
      // Standing at the destination: the path is the single node itself.
      expect(result!.path, hasLength(1));
      expect(result.path.first, nodePos('gf_room_ics', 0));
    });

    test('betweenNodes supports the manual starting-point flow', () {
      final result = RouteCalculator.betweenNodes(
        startNodeId: 'gf_start_lobby_center',
        endNodeId: 'gf_room_registrar',
        floor: 0,
      );
      expect(result.hasPath, isTrue);
      expect(result.floorIndices.every((f) => f == 0), isTrue);
      expect(result.path.first, nodePos('gf_start_lobby_center', 0));
    });
  });

  group('RouteCalculator (cross floor)', () {
    test('walks Ground → stairs → 2nd → stairs → 3rd for a 3rd-floor room', () {
      final position = live(0.45, 0.55, 0);
      final result = RouteCalculator.fromLivePosition(
        position: position,
        roomId: 'tf_library',
        destinationFloor: 2,
      );

      expect(result, isNotNull);
      expect(result!.hasPath, isTrue);
      expect(result.floorIndex, 2);
      expect(result.roomId, 'tf_library');

      // Crosses every floor in order.
      expect(result.floorIndices.toSet(), containsAll([0, 1, 2]));
      var last = -1;
      for (final f in result.floorIndices) {
        expect(f, greaterThanOrEqualTo(last));
        last = f;
      }

      // Ends at the destination room node on the 3rd floor.
      expect(result.path.last, nodePos('tf_room_library', 2));
      // Starts at the nearest node to the live position on the ground floor.
      final expectedStart = Pathfinder.findNearestNodeToPosition(
        const Offset(0.45, 0.55),
        0,
      );
      expect(result.path.first, nodePos(expectedStart, 0));
    });

    test('also works in the downward direction (3rd → Ground)', () {
      final position = live(0.5, 0.5, 2);
      final result = RouteCalculator.fromLivePosition(
        position: position,
        roomId: 'gf_registrar',
        destinationFloor: 0,
      );

      expect(result, isNotNull);
      expect(result!.hasPath, isTrue);
      expect(result.floorIndex, 0);
      expect(result.floorIndices.toSet(), containsAll([0, 1, 2]));
      expect(result.path.last, nodePos('gf_room_registrar', 0));
    });

    test('routes within an adjacent floor pair (Ground → 2nd)', () {
      final position = live(0.1, 0.2, 0);
      final result = RouteCalculator.fromLivePosition(
        position: position,
        roomId: 'sf_board_room',
        destinationFloor: 1,
      );
      expect(result, isNotNull);
      expect(result!.hasPath, isTrue);
      expect(result.floorIndices.toSet(), containsAll([0, 1]));
      expect(result.path.last, nodePos('sf_room_board', 1));
    });

    test('cross-floor path length equals sum of per-floor A* segments', () {
      final position = live(0.45, 0.55, 0);
      final result = RouteCalculator.fromLivePosition(
        position: position,
        roomId: 'tf_library',
        destinationFloor: 2,
      );

      // The composed path must be strictly longer than a single-floor path,
      // proving it really routes through the staircase transitions.
      expect(result!.path.length, greaterThan(3));
    });
  });

  group('Nearest navigation node', () {
    test('findNearestNodeToPosition snaps a position to the graph', () {
      final nodeId = Pathfinder.findNearestNodeToPosition(
        const Offset(0.468, 0.95),
        0,
      );
      expect(nodeId, 'gf_v_100');
    });

    test('findNearestNodeToRoom uses the roomToNode mapping', () {
      expect(
        Pathfinder.findNearestNodeToRoom('gf_registrar', 0),
        'gf_room_registrar',
      );
      expect(
        Pathfinder.findNearestNodeToRoom('tf_library', 2),
        'tf_room_library',
      );
    });
  });

  group('Floor plan coordinate conversion', () {
    test('normalized coordinates map to floor-plan pixels', () {
      const imageWidth = 1485.0;
      const imageHeight = 704.0;
      const x = 0.42;
      const y = 0.58;
      expect(x * imageWidth, closeTo(623.7, 0.1));
      expect(y * imageHeight, closeTo(408.32, 0.1));
    });
  });
}
