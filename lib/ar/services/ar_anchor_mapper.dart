// lib/ar/services/ar_anchor_mapper.dart
import 'dart:math' as math;
import 'dart:ui';

import 'package:vector_math/vector_math_64.dart';

import '../../services/pathfinder.dart';
import '../ar_config.dart';
import 'ar_calibration_service.dart';

/// One placed element in the AR scene: either a guide arrow, the
/// destination marker, or a room marker.
class ArAnchorPoint {
  ArAnchorPoint({
    required this.position,
    this.yaw = 0,
    this.nodeName,
    this.roomId,
  });

  /// World-space position in the AR scene.
  final Vector3 position;

  /// Rotation around the world Y axis (radians). Only used by arrows.
  final double yaw;

  /// Unique node name; room markers use their room id.
  final String? nodeName;

  /// Room id for room markers (null for arrows/destination).
  final String? roomId;
}

/// Computes the layout of AR elements from a route.
class ArAnchorMapper {
  ArAnchorMapper({required this.floorIndex, required this.calibration});

  final int floorIndex;
  final ArCalibrationService calibration;

  /// Yaw so the arrow (which points along its local +Z axis) faces `to`.
  static double yawBetween(Vector3 from, Vector3 to) {
    final dx = to.x - from.x;
    final dz = to.z - from.z;
    return math.atan2(dx, dz);
  }

  /// Produces arrows placed at a regular spacing along the route.
  /// The first [skipFirst] arrow slots are omitted so they don't sit on top
  /// of the user's calibrated start position.
  List<ArAnchorPoint> buildArrowPoints(List<Offset> path, {int skipFirst = 1}) {
    final points = <ArAnchorPoint>[];
    if (path.length < 2) return points;

    final worldPoints = path.map(calibration.mapToWorld).toList();

    var arrowSlot = skipFirst * ArConfig.arrowSpacingMeters;
    for (var i = 0; i < worldPoints.length - 1; i++) {
      final from = worldPoints[i];
      final to = worldPoints[i + 1];
      final segmentLength = (to - from).length;
      if (segmentLength <= 0.001) continue;

      final direction = (to - from)..normalize();
      while (arrowSlot <= segmentLength - 0.2) {
        final position = from + direction * arrowSlot;
        points.add(ArAnchorPoint(
          position: Vector3(
            position.x,
            ArConfig.placeHeight,
            position.z,
          ),
          yaw: yawBetween(from, to),
        ));
        arrowSlot += ArConfig.arrowSpacingMeters;
      }
      arrowSlot -= segmentLength;
    }

    return points;
  }

  /// The destination marker sits on the last route point, slightly raised.
  ArAnchorPoint? buildDestinationPoint(List<Offset> path) {
    if (path.isEmpty) return null;
    final world = calibration.mapToWorld(path.last);
    return ArAnchorPoint(
      position: Vector3(world.x, ArConfig.placeHeight + 0.08, world.z),
    );
  }

  /// Room markers for rooms whose position lies within [ArConfig.roomMarkerRadius]
  /// meters of the route polyline.
  List<ArAnchorPoint> buildRoomMarkerPoints(
    List<Offset> path,
    List<Map<String, String>> rooms,
  ) {
    if (path.length < 2) return const [];

    final markers = <ArAnchorPoint>[];
    final worldPoints = path.map(calibration.mapToWorld).toList();

    for (final room in rooms) {
      final roomId = room['id']!;
      final roomMapPos = Pathfinder.getRoomApproxPos(roomId, floorIndex);
      final roomWorld = calibration.mapToWorld(roomMapPos);

      if (!_isWithinRadiusOfPolyline(roomWorld, worldPoints)) continue;

      markers.add(ArAnchorPoint(
        position: Vector3(roomWorld.x, ArConfig.placeHeight + 0.04, roomWorld.z),
        nodeName: 'room_$roomId',
        roomId: roomId,
      ));
    }
    return markers;
  }

  bool _isWithinRadiusOfPolyline(Vector3 point, List<Vector3> worldPoints) {
    for (var i = 0; i < worldPoints.length - 1; i++) {
      final dist = _distancePointToSegment(point, worldPoints[i], worldPoints[i + 1]);
      if (dist <= ArConfig.roomMarkerRadius) return true;
    }
    return false;
  }

  double _distancePointToSegment(Vector3 p, Vector3 a, Vector3 b) {
    final ab = b - a;
    final lengthSq = ab.length2;
    if (lengthSq <= 0.0001) return (p - a).length;
    final t = ((p - a).dot(ab) / lengthSq).clamp(0.0, 1.0);
    final projection = a + ab * t;
    return (p - projection).length;
  }
}
