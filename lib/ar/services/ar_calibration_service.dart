// lib/ar/services/ar_calibration_service.dart
import 'dart:math' as math;
import 'dart:ui';

import 'package:vector_math/vector_math_64.dart';

import '../ar_config.dart';

/// Converts normalized floor-map coordinates into AR world coordinates.
///
/// Because the app has no indoor GPS, the user calibrates the scene by
/// tapping the floor where they are standing. The tapped world position is
/// bound to the route's start point and the rest of the route (and nearby
/// rooms) is laid out relative to it using the configured map scale.
class ArCalibrationService {
  ArCalibrationService(this.floorIndex);

  final int floorIndex;

  /// AR world position the user tapped to mark their location (null until
  /// the user calibrates).
  Vector3? _originWorld;

  /// Map coordinates of the route start point bound to [_originWorld].
  Offset? _originMap;

  bool get isCalibrated => _originWorld != null && _originMap != null;

  /// Binds the tapped world position to the given map start point.
  void calibrate(Vector3 worldPosition, Offset mapStart) {
    _originWorld = worldPosition.clone();
    _originMap = mapStart;
  }

  /// Resets the calibration so the user can re-tap.
  void reset() {
    _originWorld = null;
    _originMap = null;
  }

  /// Projects a normalized map offset into AR world coordinates.
  Vector3 mapToWorld(Offset mapPoint) {
    assert(isCalibrated, 'Calibrate before mapping points to world space');
    final origin = _originWorld!;
    final originMap = _originMap!;
    final dx = (mapPoint.dx - originMap.dx) * ArConfig.metersPerUnitX(floorIndex);
    final dy = (mapPoint.dy - originMap.dy) * ArConfig.metersPerUnitY(floorIndex);
    return Vector3(
      origin.x + dx * ArConfig.worldScale,
      ArConfig.placeHeight,
      origin.z + dy * ArConfig.worldScale,
    );
  }

  /// Distance in meters between two map offsets (approximate straight line).
  static double mapDistance(Offset a, Offset b, int floorIndex) {
    final dx = (a.dx - b.dx) * ArConfig.metersPerUnitX(floorIndex);
    final dy = (a.dy - b.dy) * ArConfig.metersPerUnitY(floorIndex);
    return math.sqrt(dx * dx + dy * dy);
  }
}
