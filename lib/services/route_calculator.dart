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

  /// Ordered graph node IDs parallel to [path]. Empty for legacy callers
  /// that only need geometry; populated by all [RouteCalculator] methods so
  /// human directions can reference only real traversed nodes.
  final List<String> nodeIds;

  /// Floor of the final destination.
  final int floorIndex;

  /// Destination room id (null for free-form routes).
  final String? roomId;

  const NavigationResult({
    required this.path,
    required this.floorIndices,
    required this.floorIndex,
    this.roomId,
    this.nodeIds = const [],
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
    final nodes = NavigationGraph.nodesForFloor(floor);
    final edges = NavigationGraph.edgesForFloor(floor);
    final ids = Pathfinder.findPathNodeIds(
      startNodeId: startNodeId,
      endNodeId: endNodeId,
      nodes: nodes,
      edges: edges,
    );
    final path = Pathfinder.findPath(
      startNodeId: startNodeId,
      endNodeId: endNodeId,
      nodes: nodes,
      edges: edges,
    );
    return NavigationResult(
      path: path,
      floorIndices: List.filled(path.length, floor),
      floorIndex: floor,
      roomId: roomId,
      nodeIds: ids,
    );
  }

  /// Routes from an explicit graph node to a room, on the same floor or
  /// across floors via [NavigationGraph.floorTransitions].
  ///
  /// Unlike [fromLivePosition] (which snaps a coordinate to the nearest
  /// node), this resolves already-validated node IDs — e.g. a user-typed
  /// "leftside stair" mapped through [LocationResolver] — then runs the
  /// real A* on every traversed floor. Room destinations always end at the
  /// configured room-center node via [Pathfinder.findNearestNodeToRoom].
  /// Returns null when no connected route exists; never invents geometry.
  static NavigationResult? fromNodes({
    required String startNodeId,
    required int startFloor,
    required String roomId,
    required int destinationFloor,
  }) {
    final startNodes = NavigationGraph.nodesForFloor(startFloor);
    if (!startNodes.any((n) => n.id == startNodeId)) return null;
    if (startFloor == destinationFloor) {
      final endNodeId = Pathfinder.findNearestNodeToRoom(
        roomId,
        destinationFloor,
      );
      final nodes = NavigationGraph.nodesForFloor(destinationFloor);
      final edges = NavigationGraph.edgesForFloor(destinationFloor);
      final ids = Pathfinder.findPathNodeIds(
        startNodeId: startNodeId,
        endNodeId: endNodeId,
        nodes: nodes,
        edges: edges,
      );
      if (ids.isEmpty) return null;
      final path = Pathfinder.findPath(
        startNodeId: startNodeId,
        endNodeId: endNodeId,
        nodes: nodes,
        edges: edges,
      );
      if (path.isEmpty) return null;
      return NavigationResult(
        path: path,
        floorIndices: List.filled(path.length, destinationFloor),
        floorIndex: destinationFloor,
        roomId: roomId,
        nodeIds: ids,
      );
    }
    return _crossFloorFromNode(
      startNodeId: startNodeId,
      startFloor: startFloor,
      roomId: roomId,
      destinationFloor: destinationFloor,
    );
  }

  static NavigationResult? _sameFloor(
    IndoorPosition position,
    String roomId,
    int floor,
  ) {
    final nodes = NavigationGraph.nodesForFloor(floor);
    final edges = NavigationGraph.edgesForFloor(floor);
    final startId = Pathfinder.findNearestNodeToPosition(
      Offset(position.x, position.y),
      floor,
    );
    final endId = Pathfinder.findNearestNodeToRoom(roomId, floor);
    final ids = Pathfinder.findPathNodeIds(
      startNodeId: startId,
      endNodeId: endId,
      nodes: nodes,
      edges: edges,
    );
    if (ids.isEmpty) return null;
    final path = Pathfinder.findPath(
      startNodeId: startId,
      endNodeId: endId,
      nodes: nodes,
      edges: edges,
    );
    if (path.isEmpty) return null;
    return NavigationResult(
      path: path,
      floorIndices: List.filled(path.length, floor),
      floorIndex: floor,
      roomId: roomId,
      nodeIds: ids,
    );
  }

  static NavigationResult? _crossFloor(
    IndoorPosition position,
    String roomId,
    int destinationFloor,
  ) {
    final startId = Pathfinder.findNearestNodeToPosition(
      Offset(position.x, position.y),
      position.floor,
    );
    return _crossFloorFromNode(
      startNodeId: startId,
      startFloor: position.floor,
      roomId: roomId,
      destinationFloor: destinationFloor,
    );
  }

  /// Routes between two explicit graph nodes, possibly across floors.
  ///
  /// Used when both endpoints are named places (e.g. room → staircase or
  /// staircase → staircase). Never invents geometry.
  static NavigationResult? fromNodeToNode({
    required String startNodeId,
    required int startFloor,
    required String endNodeId,
    required int endFloor,
    String? roomId,
  }) {
    final startNodes = NavigationGraph.nodesForFloor(startFloor);
    final endNodes = NavigationGraph.nodesForFloor(endFloor);
    if (!startNodes.any((n) => n.id == startNodeId)) return null;
    if (!endNodes.any((n) => n.id == endNodeId)) return null;
    if (startFloor == endFloor) {
      return betweenNodes(
        startNodeId: startNodeId,
        endNodeId: endNodeId,
        floor: startFloor,
        roomId: roomId,
      );
    }
    final chain = _floorChain(startFloor, endFloor);
    if (chain == null || chain.isEmpty) return null;
    final path = <Offset>[];
    final indices = <int>[];
    final ids = <String>[];

    bool appendIds(List<String> segIds, int floor) {
      final nodes = NavigationGraph.nodesForFloor(floor);
      final map = {for (final n in nodes) n.id: n.pos};
      for (final id in segIds) {
        if (!map.containsKey(id)) return false;
      }
      for (final id in segIds) {
        ids.add(id);
        path.add(map[id]!);
        indices.add(floor);
      }
      return true;
    }

    String exitNodeOf((int, FloorTransition, bool) hop) =>
        hop.$3 ? hop.$2.fromNode : hop.$2.toNode;
    String entryNodeOf((int, FloorTransition, bool) hop) =>
        hop.$3 ? hop.$2.toNode : hop.$2.fromNode;

    final firstIds = Pathfinder.findPathNodeIds(
      startNodeId: startNodeId,
      endNodeId: exitNodeOf(chain.first),
      nodes: NavigationGraph.nodesForFloor(startFloor),
      edges: NavigationGraph.edgesForFloor(startFloor),
    );
    if (firstIds.isEmpty) return null;
    if (!appendIds(firstIds, startFloor)) return null;
    for (var i = 0; i < chain.length; i++) {
      final floor = chain[i].$1;
      final isLast = i == chain.length - 1;
      final startNode = entryNodeOf(chain[i]);
      final endNode = isLast ? endNodeId : exitNodeOf(chain[i + 1]);
      final segIds = Pathfinder.findPathNodeIds(
        startNodeId: startNode,
        endNodeId: endNode,
        nodes: NavigationGraph.nodesForFloor(floor),
        edges: NavigationGraph.edgesForFloor(floor),
      );
      if (segIds.isEmpty) return null;
      if (!appendIds(segIds, floor)) return null;
    }
    if (path.isEmpty) return null;
    return NavigationResult(
      path: path,
      floorIndices: indices,
      floorIndex: endFloor,
      roomId: roomId,
      nodeIds: ids,
    );
  }

  /// Shared cross-floor composer from an explicit start node.
  static NavigationResult? _crossFloorFromNode({
    required String startNodeId,
    required int startFloor,
    required String roomId,
    required int destinationFloor,
  }) {
    final chain = _floorChain(startFloor, destinationFloor);
    if (chain == null || chain.isEmpty) return null;

    final path = <Offset>[];
    final indices = <int>[];
    final ids = <String>[];

    bool appendIds(List<String> segIds, int floor) {
      final nodes = NavigationGraph.nodesForFloor(floor);
      final map = {for (final n in nodes) n.id: n.pos};
      for (final id in segIds) {
        if (!map.containsKey(id)) return false;
      }
      for (final id in segIds) {
        ids.add(id);
        path.add(map[id]!);
        indices.add(floor);
      }
      return true;
    }

    // Node used to LEAVE a floor through a hop (stair node on that floor).
    String exitNodeOf((int, FloorTransition, bool) hop) =>
        hop.$3 ? hop.$2.fromNode : hop.$2.toNode;

    // Node used to ENTER a floor through a hop (stair node on that floor).
    String entryNodeOf((int, FloorTransition, bool) hop) =>
        hop.$3 ? hop.$2.toNode : hop.$2.fromNode;

    // First segment: from the explicit start node to the first staircase.
    final firstHop = chain.first;
    final firstIds = Pathfinder.findPathNodeIds(
      startNodeId: startNodeId,
      endNodeId: exitNodeOf(firstHop),
      nodes: NavigationGraph.nodesForFloor(startFloor),
      edges: NavigationGraph.edgesForFloor(startFloor),
    );
    if (firstIds.isEmpty) return null;
    if (!appendIds(firstIds, startFloor)) return null;

    for (var i = 0; i < chain.length; i++) {
      final floor = chain[i].$1;
      final isLast = i == chain.length - 1;

      final startNode = entryNodeOf(chain[i]);
      final endNode = isLast
          ? Pathfinder.findNearestNodeToRoom(roomId, floor)
          : exitNodeOf(chain[i + 1]);

      final segIds = Pathfinder.findPathNodeIds(
        startNodeId: startNode,
        endNodeId: endNode,
        nodes: NavigationGraph.nodesForFloor(floor),
        edges: NavigationGraph.edgesForFloor(floor),
      );
      if (segIds.isEmpty) return null;
      if (!appendIds(segIds, floor)) return null;
    }

    if (path.isEmpty) return null;
    return NavigationResult(
      path: path,
      floorIndices: indices,
      floorIndex: destinationFloor,
      roomId: roomId,
      nodeIds: ids,
    );
  }

  /// BFS over the undirected floor-adjacency from [NavigationGraph].
  /// Returns the ordered hop chain or null when floors are disconnected.
  static List<(int, FloorTransition, bool)>? _floorChain(
    int startFloor,
    int destinationFloor,
  ) {
    if (startFloor == destinationFloor) return [];
    const transitions = NavigationGraph.floorTransitions;
    final neighbors = <int, List<(int, FloorTransition)>>{};
    for (final t in transitions) {
      neighbors.putIfAbsent(t.fromFloor, () => []).add((t.toFloor, t));
      neighbors.putIfAbsent(t.toFloor, () => []).add((t.fromFloor, t));
    }
    final queue = <int>[startFloor];
    final visited = <int>{startFloor};
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
    final chain = <(int, FloorTransition, bool)>[];
    var current = destinationFloor;
    while (current != startFloor) {
      final entry = cameFrom[current]!;
      chain.insert(0, (current, entry.$2, entry.$3));
      current = entry.$1;
    }
    return chain;
  }
}
