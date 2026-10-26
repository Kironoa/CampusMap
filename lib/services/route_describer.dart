// lib/services/route_describer.dart
//
// Converts ONLY an already-calculated [NavigationResult] into human steps.
//
// Grounding rules (never violated):
// - Every named place comes from the result's node IDs, the configured
//   [NavigationGraph] labels, or [RoomCatalog] names for the resolved IDs.
// - Every heading comes from the real node coordinates of consecutive path
//   nodes (normalized map frame: +x = east, +y = south/down the image).
// - Floor transitions are described only when the result actually spans
//   floors, using the matching [FloorTransition] (stairs vs elevator is read
//   from the real node IDs, never assumed).
// - Room destinations end at the configured room-center node; the text says
//   so explicitly instead of stopping at a doorway/corridor.

import 'dart:math';
import 'dart:ui';

import 'location_resolver.dart';
import 'navigation_graph.dart';
import 'room_catalog.dart';
import 'route_calculator.dart';

class RouteDescriber {
  /// Describes [result] from [startLabel]/[startFloor] to the room
  /// [destRoomId]. All names must already be resolved via [LocationResolver];
  /// this function performs no guessing.
  static String describe({
    required String startLabel,
    required int startFloor,
    required String destRoomId,
    required int destFloor,
    required NavigationResult result,
    bool startIsDefault = false,
    String? destLabelOverride,
    bool destIsRoomCenter = true,
  }) {
    final destName =
        destLabelOverride ?? RoomCatalog.roomNameById(destRoomId) ?? destRoomId;
    final arrival = destIsRoomCenter
        ? 'You have arrived at $destName (room center).'
        : 'You have arrived at $destName.';
    final buf = StringBuffer();

    if (startIsDefault) {
      buf.writeln(
        'Starting from $startLabel (${floorName(startFloor)}, default).',
      );
    } else {
      buf.writeln('Start at $startLabel (${floorName(startFloor)}).');
    }

    final ids = result.nodeIds;
    if (ids.length <= 1 || result.path.length < 2) {
      buf.write(arrival);
      return buf.toString().trim();
    }

    // Split the flat node/offset/floor lists into per-floor segments,
    // preserving travel order.
    final segments = _segmentsOf(result);
    var step = 1;

    for (var s = 0; s < segments.length; s++) {
      final seg = segments[s];
      if (s > 0) {
        final prev = segments[s - 1];
        final hop = _findTransition(
          prev.ids.last,
          prev.floor,
          seg.ids.first,
          seg.floor,
        );
        final stairName = _transitionName(
          hop,
          prev.ids.last,
          seg.ids.first,
          prev.floor,
        );
        final verb = _isElevator(prev.ids.last) || _isElevator(seg.ids.first)
            ? 'Ride'
            : 'Take the stairs';
        buf.writeln(
          '$step. $verb from ${floorName(prev.floor)} to ${floorName(seg.floor)} via $stairName.',
        );
        step++;
      }
      final isLastSeg = s == segments.length - 1;
      final target = isLastSeg ? destName : null;
      for (final line in _walkingSteps(seg, target)) {
        buf.writeln('$step. $line');
        step++;
      }
    }

    buf.write(arrival);
    return buf.toString().trim();
  }

  // ------------------------------------------------------------------
  // Geometry helpers (all derived from real graph coordinates).
  // ------------------------------------------------------------------

  /// 8-wind compass heading for one leg in normalized map frame
  /// (+x east, +y south/down the floor-plan image).
  static String _heading(Offset from, Offset to) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final deg = atan2(dy, dx) * 180 / pi; // -180..180, 0 = east
    if (deg >= -22.5 && deg < 22.5) return 'east';
    if (deg >= 22.5 && deg < 67.5) return 'southeast';
    if (deg >= 67.5 && deg < 112.5) return 'south';
    if (deg >= 112.5 && deg < 157.5) return 'southwest';
    if (deg >= -67.5 && deg < -22.5) return 'northeast';
    if (deg >= -112.5 && deg < -67.5) return 'north';
    if (deg >= -157.5 && deg < -112.5) return 'northwest';
    return 'west';
  }

  static bool _isRoomNode(String id) =>
      id.startsWith('gf_room_') ||
      id.startsWith('sf_room_') ||
      id.startsWith('tf_room_');

  /// Human name for a waypoint node, or null for anonymous corridor nodes.
  static String? _waypointName(String id, int floor) {
    if (_isRoomNode(id)) {
      for (final entry in NavigationGraph.roomToNode.entries) {
        if (entry.value == id) {
          return RoomCatalog.roomNameById(entry.key);
        }
      }
      return null;
    }
    for (final c in LocationResolver.index) {
      if (c.kind == LocationKind.start &&
          c.nodeId == id &&
          c.floor == floor) {
        return c.label;
      }
    }
    return null;
  }

  static List<_FloorSegment> _segmentsOf(NavigationResult result) {
    final out = <_FloorSegment>[];
    List<String> ids = [];
    List<Offset> pts = [];
    var floor = result.floorIndices.first;
    void flush() {
      if (ids.length >= 2) {
        out.add(_FloorSegment(floor: floor, ids: List.of(ids), pts: List.of(pts)));
      } else if (ids.length == 1) {
        // Single-point segment (e.g. a lone transition landing): keep it so
        // the stairs step still has an anchor, but there is nothing to walk.
        out.add(_FloorSegment(floor: floor, ids: List.of(ids), pts: List.of(pts)));
      }
    }

    for (var i = 0; i < result.nodeIds.length && i < result.path.length; i++) {
      final f = result.floorIndices[i];
      if (ids.isNotEmpty && f != floor) {
        flush();
        ids = [];
        pts = [];
        floor = f;
      }
      ids.add(result.nodeIds[i]);
      pts.add(result.path[i]);
    }
    flush();
    return out;
  }

  /// Compresses one floor segment into walking instructions derived from the
  /// real leg headings. [target] names the final destination of the whole
  /// route and is only used on the last segment.
  static List<String> _walkingSteps(_FloorSegment seg, String? target) {
    final legs = <_Leg>[];
    for (var i = 0; i + 1 < seg.ids.length; i++) {
      final a = seg.pts[i];
      final b = seg.pts[i + 1];
      final dx = b.dx - a.dx;
      final dy = b.dy - a.dy;
      if (dx * dx + dy * dy < 1e-12) continue; // zero-length hop
      legs.add(_Leg(heading: _heading(a, b), toId: seg.ids[i + 1]));
    }
    if (legs.isEmpty) return const [];

    // Group consecutive legs with the same heading into one run.
    final runs = <List<_Leg>>[];
    for (final leg in legs) {
      if (runs.isNotEmpty && runs.last.first.heading == leg.heading) {
        runs.last.add(leg);
      } else {
        runs.add([leg]);
      }
    }

    final lines = <String>[];
    for (var r = 0; r < runs.length; r++) {
      final run = runs[r];
      final isLastRun = r == runs.length - 1;
      final verb = r == 0 ? 'Head' : 'Then turn';
      // Named waypoints actually traversed in this run (excluding the
      // final destination, which gets its own arrival line).
      final passed = <String>[];
      for (var k = 0; k < run.length; k++) {
        final isFinalLeg = isLastRun && k == run.length - 1;
        if (isFinalLeg && target != null) continue;
        final name = _waypointName(run[k].toId, seg.floor);
        if (name != null && !passed.contains(name)) passed.add(name);
      }
      final sb = StringBuffer('$verb ${run.first.heading}');
      sb.write(' along the ${floorName(seg.floor)} corridor');
      if (run.length > 1) sb.write(' for about ${run.length} sections');
      if (passed.isNotEmpty) {
        sb.write(
          run.length > 1 ? ', passing ${passed.join(', ')}' : ' past ${passed.join(', ')}',
        );
      }
      if (isLastRun && target != null) {
        final lastId = seg.ids.last;
        if (_isRoomNode(lastId)) {
          sb.write(' toward $target');
        } else {
          sb.write(' toward $target');
        }
      }
      sb.write('.');
      lines.add(sb.toString());
    }
    return lines;
  }

  static FloorTransition? _findTransition(
    String exitId,
    int exitFloor,
    String entryId,
    int entryFloor,
  ) {
    for (final t in NavigationGraph.floorTransitions) {
      final fwd = t.fromFloor == exitFloor &&
          t.toFloor == entryFloor &&
          t.fromNode == exitId &&
          t.toNode == entryId;
      final rev = t.fromFloor == entryFloor &&
          t.toFloor == exitFloor &&
          t.fromNode == entryId &&
          t.toNode == exitId;
      if (fwd || rev) return t;
    }
    return null;
  }

  static bool _isElevator(String nodeId) =>
      nodeId.toLowerCase().contains('elevator');

  /// Names the stairs/elevator using the exit-side (current floor) label so
  /// up/down traversals of the same link are described from the walker's side.
  static String _transitionName(
    FloorTransition? hop,
    String exitId,
    String entryId,
    int exitFloor,
  ) {
    String? label;
    for (final c in LocationResolver.index) {
      if (c.kind == LocationKind.start &&
          c.nodeId == exitId &&
          c.floor == exitFloor) {
        label = c.label;
        break;
      }
    }
    label ??= LocationResolver.labelForNode(exitId, exitFloor);
    final kind = _isElevator(exitId) || _isElevator(entryId)
        ? 'elevator'
        : 'stairs';
    // Avoid doubling: "Left Wing Staircase (stairs)" -> keep label as-is
    // when it already mentions stairs/elevator.
    final low = label.toLowerCase();
    if (low.contains('stair') || low.contains('elevator')) return label;
    return '$label $kind';
  }
}

class _FloorSegment {
  final int floor;
  final List<String> ids;
  final List<Offset> pts;
  const _FloorSegment({
    required this.floor,
    required this.ids,
    required this.pts,
  });
}

class _Leg {
  final String heading;
  final String toId;
  const _Leg({required this.heading, required this.toId});
}
