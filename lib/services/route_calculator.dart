// lib/services/route_calculator.dart
import 'dart:ui';

import 'indoor_positioning/indoor_position.dart';
import 'navigation_graph.dart';
import 'pathfinder.dart';

/// The result of a route computation.
class NavigationResult {
  /// Normalized path points (may span multiple floors).
  final List<Offset> path;

  /// Floor index for every point in [path].
  final List<int> floorIndices;

  /// Floor of the final destination.
  final int floorIndex;

  /// Destination room id (null for free-form routes).
  final String? roomId;

  const NavigationResult({
    required this.path,
    required this.floorIndices,
    required this.floorIndex,
    this.roomId,
  });

  bool get hasPath => path.length >= 2;
}

/// Computes routes FROM a live indoor position, reusing the existing
/// [NavigationGraph] and [Pathfinder]. No duplicate A* implementation.
///
/// - Same-floor routes: nearest node to the position → room node (A*).
/// - Cross-floor routes: walk the existing graph to the nearest staircase
///   node, hop floors via [NavigationGraph.floorTransitions], then walk to
///   the destination on the target floor. Never invents stair coordinates:
///   transitions come only from configured data.
class RouteCalculator {
  RouteCalculator._();

  /// Routes from [position] to [roomId] on [destinationFloor].
  ///
  /// Returns null when no route exists (e.g. disconnected floors).
  static NavigationResult? fromLivePosition({
    required IndoorPosition position,
    required String roomId,
    required int destinationFloor,
  }) {
    if (position.floor == destinationFloor) {
      return _sameFloor(position, roomId, destinationFloor);
    }
    return _crossFloor(position, roomId, destinationFloor);
  }

  /// Routes between two arbitrary nodes on the same floor (manual flow).
  static NavigationResult betweenNodes({
    required String startNodeId,
    required String endNodeId,
    required int floor,
    String? roomId,
  }) {
    final path = Pathfinder.findPath(
      startNodeId: startNodeId,
      endNodeId: endNodeId,
      nodes: NavigationGraph.nodesForFloor(floor),
      edges: NavigationGraph.edgesForFloor(floor),
    );
    return NavigationResult(
      path: path,
      floorIndices: List.filled(path.length, floor),
      floorIndex: floor,
      roomId: roomId,
    );
  }

  static NavigationResult? _sameFloor(
    IndoorPosition position,
    String roomId,
    int floor,
  ) {
    final path = Pathfinder.findPath(
      startNodeId: Pathfinder.findNearestNodeToPosition(
        Offset(position.x, position.y),
        floor,
      ),
      endNodeId: Pathfinder.findNearestNodeToRoom(roomId, floor),
      nodes: NavigationGraph.nodesForFloor(floor),
      edges: NavigationGraph.edgesForFloor(floor),
    );
    if (path.isEmpty) return null;
    return NavigationResult(
      path: path,
      floorIndices: List.filled(path.length, floor),
      floorIndex: floor,
      roomId: roomId,
    );
  }

  static NavigationResult? _crossFloor(
    IndoorPosition position,
    String roomId,
    int destinationFloor,
  ) {
    const transitions = NavigationGraph.floorTransitions;

    // Undirected floor adjacency: each transition connects two floors.
    final neighbors = <int, List<(int, FloorTransition)>>{};
    for (final t in transitions) {
      neighbors.putIfAbsent(t.fromFloor, () => []).add((t.toFloor, t));
      neighbors.putIfAbsent(t.toFloor, () => []).add((t.fromFloor, t));
    }

    // BFS over floors.
    final queue = <int>[position.floor];
    final visited = <int>{position.floor};
    // floor -> (previous floor, transition used, was it traversed upward)
    final cameFrom = <int, (int, FloorTransition, bool)>{};

    while (queue.isNotEmpty) {
      final floor = queue.removeAt(0);
      if (floor == destinationFloor) break;
      for (final (next, t)
          in neighbors[floor] ?? const <(int, FloorTransition)>[]) {
        if (!visited.contains(next)) {
          visited.add(next);
          cameFrom[next] = (floor, t, t.fromFloor == floor);
          queue.add(next);
        }
      }
    }

    if (!visited.contains(destinationFloor)) return null;

    // Reconstruct the floor chain: [(floor, transition entered via, forward)].
    final chain = <(int, FloorTransition, bool)>[];
    var current = destinationFloor;
    while (current != position.floor) {
      final entry = cameFrom[current]!;
      chain.insert(0, (current, entry.$2, entry.$3));
      current = entry.$1;
    }

    final path = <Offset>[];
    final indices = <int>[];

    void append(List<Offset> points, int floor) {
      path.addAll(points);
      indices.addAll(List.filled(points.length, floor));
    }

    // Node used to LEAVE a floor through a hop (stair node on that floor).
    String exitNodeOf((int, FloorTransition, bool) hop) =>
        hop.$3 ? hop.$2.fromNode : hop.$2.toNode;

    // Node used to ENTER a floor through a hop (stair node on that floor).
    String entryNodeOf((int, FloorTransition, bool) hop) =>
        hop.$3 ? hop.$2.toNode : hop.$2.fromNode;

    // First segment: from the live position to the first staircase node.
    final firstHop = chain.first;
    final firstSegment = Pathfinder.findPath(
      startNodeId: Pathfinder.findNearestNodeToPosition(
        Offset(position.x, position.y),
        position.floor,
      ),
      endNodeId: exitNodeOf(firstHop),
      nodes: NavigationGraph.nodesForFloor(position.floor),
      edges: NavigationGraph.edgesForFloor(position.floor),
    );
    if (firstSegment.isEmpty) return null;
    append(firstSegment, position.floor);

    for (var i = 0; i < chain.length; i++) {
      final floor = chain[i].$1;
      final isLast = i == chain.length - 1;

      final startNode = entryNodeOf(chain[i]);
      final endNode = isLast
          ? Pathfinder.findNearestNodeToRoom(roomId, floor)
          : exitNodeOf(chain[i + 1]);

      final segment = Pathfinder.findPath(
        startNodeId: startNode,
        endNodeId: endNode,
        nodes: NavigationGraph.nodesForFloor(floor),
        edges: NavigationGraph.edgesForFloor(floor),
      );
      if (segment.isEmpty) return null;
      append(segment, floor);
    }

    return NavigationResult(
      path: path,
      floorIndices: indices,
      floorIndex: destinationFloor,
      roomId: roomId,
    );
  }
}
