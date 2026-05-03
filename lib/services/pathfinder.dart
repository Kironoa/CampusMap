// lib/services/pathfinder.dart
import 'dart:math';
import 'dart:ui';
import 'navigation_graph.dart';

class Pathfinder {
  static List<Offset> findPath({
    required String startNodeId,
    required String endNodeId,
    required List<NavNode> nodes,
    required List<NavEdge> edges,
  }) {
    if (startNodeId == endNodeId) {
      final n = nodes.firstWhere((n) => n.id == startNodeId, orElse: () => nodes.first);
      return [n.pos];
    }

    final Map<String, List<String>> adj = {};
    for (final n in nodes) {
      adj[n.id] = [];
    }
    for (final e in edges) {
      adj[e.from]?.add(e.to);
      adj[e.to]?.add(e.from);
    }

    final nodeMap = <String, NavNode>{};
    for (final n in nodes) {
      nodeMap[n.id] = n;
    }

    if (!nodeMap.containsKey(startNodeId) || !nodeMap.containsKey(endNodeId)) {
      return [];
    }

    final openSet = <String>{startNodeId};
    final cameFrom = <String, String>{};
    final gScore = <String, double>{};
    final fScore = <String, double>{};

    for (final n in nodes) {
      gScore[n.id] = double.infinity;
      fScore[n.id] = double.infinity;
    }

    gScore[startNodeId] = 0.0;
    fScore[startNodeId] = _h(nodeMap[startNodeId]!.pos, nodeMap[endNodeId]!.pos);

    while (openSet.isNotEmpty) {
      String current = openSet.first;
      for (final nodeId in openSet) {
        if ((fScore[nodeId] ?? double.infinity) < (fScore[current] ?? double.infinity)) {
          current = nodeId;
        }
      }

      if (current == endNodeId) {
        return _reconstruct(cameFrom, current, nodeMap);
      }

      openSet.remove(current);

      final neighbors = adj[current] ?? [];
      for (final neighbor in neighbors) {
        if (!nodeMap.containsKey(neighbor)) continue;
        final tentG = (gScore[current] ?? double.infinity) +
            _d(nodeMap[current]!.pos, nodeMap[neighbor]!.pos);

        if (tentG < (gScore[neighbor] ?? double.infinity)) {
          cameFrom[neighbor] = current;
          gScore[neighbor] = tentG;
          fScore[neighbor] = tentG + _h(nodeMap[neighbor]!.pos, nodeMap[endNodeId]!.pos);
          openSet.add(neighbor);
        }
      }
    }

    return [];
  }

  static double _h(Offset a, Offset b) =>
      sqrt(pow(a.dx - b.dx, 2) + pow(a.dy - b.dy, 2));

  static double _d(Offset a, Offset b) => _h(a, b);

  static List<Offset> _reconstruct(
    Map<String, String> cameFrom,
    String current,
    Map<String, NavNode> nodeMap,
  ) {
    final path = <Offset>[nodeMap[current]!.pos];
    String c = current;
    while (cameFrom.containsKey(c)) {
      c = cameFrom[c]!;
      path.insert(0, nodeMap[c]!.pos);
    }
    return path;
  }

  static String nearestNode(Offset pos, List<NavNode> nodes) {
    String nearestId = nodes.first.id;
    double minDist = _d(pos, nodes.first.pos);

    for (final n in nodes) {
      final d = _d(pos, n.pos);
      if (d < minDist) {
        minDist = d;
        nearestId = n.id;
      }
    }
    return nearestId;
  }

  static String findNearestNodeToRoom(String roomId, int floor) {
    final mappedNodeId = NavigationGraph.roomToNode[roomId];
    if (mappedNodeId != null) {
      final nodes = NavigationGraph.nodesForFloor(floor);
      for (final n in nodes) {
        if (n.id == mappedNodeId) {
          return mappedNodeId;
        }
      }
    }

    final nodes = NavigationGraph.nodesForFloor(floor);
    final nodePos = _getRoomApproxPos(roomId, floor);
    return nearestNode(nodePos, nodes);
  }

  static Offset _getRoomApproxPos(String roomId, int floor) {
    const positions = {
      'gf_main_lobby': Offset(0.595, 0.530),
      'gf_drive_way': Offset(0.468, 0.950),
      'gf_scholarship': Offset(0.435, 0.490),
      'gf_ojt': Offset(0.435, 0.550),
      'gf_accreditation': Offset(0.595, 0.490),
      'gf_record': Offset(0.438, 0.420),
      'gf_registrar': Offset(0.375, 0.420),
      'gf_vp_admin': Offset(0.300, 0.420),
      'gf_crim_lab': Offset(0.185, 0.420),
      'gf_icje': Offset(0.095, 0.420),
      'gf_sldo': Offset(0.030, 0.420),
      'gf_ciso': Offset(0.595, 0.420),
      'gf_avr': Offset(0.670, 0.420),
      'gf_dressing': Offset(0.745, 0.420),
      'gf_music': Offset(0.815, 0.420),
      'gf_dance': Offset(0.885, 0.420),
      'gf_barracks': Offset(0.960, 0.420),
      'gf_medical': Offset(0.630, 0.190),
      'gf_restroom_left': Offset(0.050, 0.130),
      'gf_restroom_center': Offset(0.468, 0.190),
      'gf_restroom_right': Offset(0.895, 0.190),
      'gf_mb105': Offset(0.720, 0.190),
      'gf_mb103': Offset(0.775, 0.190),
      'gf_mpr': Offset(0.830, 0.190),
      'gf_midwifery': Offset(0.885, 0.190),
      'gf_pfom': Offset(0.960, 0.190),
      'gf_ias': Offset(0.468, 0.130),
      'gf_ite': Offset(0.360, 0.190),
      'gf_ibfs': Offset(0.295, 0.190),
      'gf_ihs': Offset(0.240, 0.190),
      'gf_training': Offset(0.180, 0.190),
      'gf_ics': Offset(0.130, 0.190),
      'gf_cr_left1': Offset(0.170, 0.130),
      'gf_cr_left2': Offset(0.195, 0.130),
      'gf_cr_right1': Offset(0.895, 0.130),
      'gf_cr_right2': Offset(0.920, 0.130),
      'gf_elevator': Offset(0.468, 0.370),
      'sf_main_stage': Offset(0.500, 0.120),
      'sf_guidance_testing': Offset(0.045, 0.320),
      'sf_sub_lobby': Offset(0.090, 0.320),
      'sf_computer_lab': Offset(0.185, 0.320),
      'sf_computer_room_1': Offset(0.285, 0.320),
      'sf_computer_room_2': Offset(0.360, 0.320),
      'sf_computer_room_3': Offset(0.420, 0.320),
      'sf_restroom_left': Offset(0.468, 0.320),
      'sf_restroom_cl': Offset(0.468, 0.320),
      'sf_restroom_cr': Offset(0.490, 0.320),
      'sf_restroom_r1': Offset(0.790, 0.320),
      'sf_restroom_r2': Offset(0.820, 0.320),
      'sf_vip_lounge': Offset(0.590, 0.320),
      'sf_faculty_lounge': Offset(0.740, 0.320),
      'sf_speech_lab': Offset(0.875, 0.320),
      'sf_bseed_left': Offset(0.970, 0.320),
      'sf_guidance_counsel': Offset(0.045, 0.510),
      'sf_moot_court': Offset(0.170, 0.510),
      'sf_business_center': Offset(0.290, 0.510),
      'sf_classroom_left': Offset(0.380, 0.510),
      'sf_classroom_center': Offset(0.425, 0.510),
      'sf_classroom_right': Offset(0.460, 0.510),
      'sf_board_room': Offset(0.560, 0.510),
      'sf_hrmo': Offset(0.640, 0.510),
      'sf_faculty_room': Offset(0.720, 0.510),
      'sf_supply': Offset(0.795, 0.510),
      'sf_vp_planning': Offset(0.855, 0.510),
      'sf_evp': Offset(0.910, 0.510),
      'sf_deans': Offset(0.440, 0.590),
      'sf_vpaa': Offset(0.440, 0.680),
      'sf_president': Offset(0.595, 0.630),
      'sf_deck_canopy': Offset(0.500, 0.920),
      'sf_bleacher_left': Offset(0.250, 0.200),
      'sf_bleacher_right': Offset(0.750, 0.200),
      'tf_library': Offset(0.260, 0.300),
      'tf_lrc1': Offset(0.065, 0.300),
      'tf_lrc2': Offset(0.430, 0.300),
      'tf_prayer': Offset(0.380, 0.185),
      'tf_activity': Offset(0.490, 0.150),
      'tf_research': Offset(0.620, 0.185),
      'tf_restroom_left': Offset(0.560, 0.300),
      'tf_restroom_right': Offset(0.590, 0.300),
      'tf_classroom_1': Offset(0.650, 0.300),
      'tf_classroom_2': Offset(0.700, 0.300),
      'tf_classroom_3': Offset(0.750, 0.300),
      'tf_classroom_4': Offset(0.800, 0.300),
      'tf_classroom_5': Offset(0.855, 0.300),
      'tf_classroom_6': Offset(0.975, 0.300),
      'tf_science_lab': Offset(0.920, 0.300),
      'tf_elevator': Offset(0.490, 0.300),
      'tf_main_stage': Offset(0.500, 0.750),
      'tf_bleacher_left': Offset(0.250, 0.600),
      'tf_bleacher_right': Offset(0.750, 0.600),
    };

    return positions[roomId] ?? const Offset(0.5, 0.5);
  }
}