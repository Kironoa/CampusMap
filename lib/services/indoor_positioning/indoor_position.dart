// lib/services/indoor_positioning/indoor_position.dart
import 'package:flutter/foundation.dart';

/// Where a position estimate came from.
enum PositionSource {
  /// Bluetooth Low Energy beacon RSSI estimation.
  ble,

  /// Simulated position (dev/demo mode, no hardware).
  mock,

  /// Manually calibrated / user-provided position.
  manual,
}

/// A real-time position estimate inside the building.
///
/// Coordinates are NORMALIZED 0.0..1.0 over the floor-plan image for the
/// given [floor], matching the coordinate system used by [NavigationGraph]
/// and [Pathfinder]. Convert to pixels with:
///
///   pixelX = x * floorImageWidth
///   pixelY = y * floorImageHeight
///
/// [accuracy] is the estimated uncertainty in METERS (not pixels).
/// The larger the value, the less trustworthy the position.
@immutable
class IndoorPosition {
  final double x;
  final double y;
  final int floor;
  final double accuracy;
  final DateTime timestamp;
  final PositionSource source;

  const IndoorPosition({
    required this.x,
    required this.y,
    required this.floor,
    required this.accuracy,
    required this.timestamp,
    required this.source,
  });

  /// Clamps x/y into the valid 0.0..1.0 range.
  static double clampCoordinate(double value) => value.clamp(0.0, 1.0);

  IndoorPosition copyWith({
    double? x,
    double? y,
    int? floor,
    double? accuracy,
    DateTime? timestamp,
    PositionSource? source,
  }) {
    return IndoorPosition(
      x: x ?? this.x,
      y: y ?? this.y,
      floor: floor ?? this.floor,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IndoorPosition &&
        other.x == x &&
        other.y == y &&
        other.floor == floor &&
        other.accuracy == accuracy &&
        other.timestamp == timestamp &&
        other.source == source;
  }

  @override
  int get hashCode =>
      Object.hash(x, y, floor, accuracy, timestamp, source);

  @override
  String toString() =>
      'IndoorPosition(x: $x, y: $y, floor: $floor, accuracy: $accuracy, source: $source)';
}