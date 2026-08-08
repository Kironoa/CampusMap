// lib/ar/ar_config.dart
import 'dart:ui';

/// Central configuration for the AR navigation experience.
class ArConfig {
  ArConfig._();

  /// Real-world width of the floor map in meters.
  /// Tune this value on-device to match the physical building.
  static const double metersPerMapWidth = 36.0;

  /// ARCore/ARKit world scale: 1 world meter maps to this many Flutter
  /// logical units for the anchor mapper.
  static const double worldScale = 1.0;

  /// Distance in meters between consecutive guide arrows along the route.
  static const double arrowSpacingMeters = 1.6;

  /// Base size (meters) of the guide arrows in the AR scene.
  static const double arrowSize = 0.42;

  /// Size (meters) of the destination marker in the AR scene.
  static const double destinationSize = 0.55;

  /// Size (meters) of room marker spheres in the AR scene.
  static const double roomMarkerSize = 0.22;

  /// Height (meters) above the floor at which objects are placed.
  static const double placeHeight = 0.02;

  /// Rooms within this distance (meters) of the route get a marker.
  static const double roomMarkerRadius = 7.0;

  /// Only rooms within this distance (meters) of the camera get a label.
  static const double roomLabelRadius = 5.0;

  /// Poll interval for camera pose updates (room label proximity).
  static const Duration cameraPoseInterval = Duration(milliseconds: 500);

  /// Relative model URIs (resolved against the app's asset root).
  static const String arrowModel = 'ar_models/arrow.gltf';
  static const String destinationModel = 'ar_models/destination.gltf';
  static const String roomMarkerModel = 'ar_models/marker.gltf';

  /// Original pixel dimensions of each floor map image (indexed by floor).
  static const List<Size> floorImageSizes = [
    Size(1485, 704),
    Size(1464, 720),
    Size(1600, 671),
  ];

  /// Meters per normalized map unit for the given floor.
  static double metersPerUnitX(int floorIndex) => metersPerMapWidth;

  static double metersPerUnitY(int floorIndex) {
    final size = floorImageSizes[floorIndex];
    return metersPerMapWidth * (size.height / size.width);
  }
}
