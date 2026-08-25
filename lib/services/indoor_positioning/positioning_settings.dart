// lib/services/indoor_positioning/positioning_settings.dart

/// Position source selected in debug mode.
enum IndoorPositioningMode {
  /// Bluetooth Low Energy beacon positioning (real hardware).
  ble,

  /// Simulated position, no hardware required (default).
  mock,
}

/// Global dev/debug configuration for indoor positioning.
///
/// In-memory singleton; intentionally not persisted so the app always
/// starts in the safe Mock mode until real beacons are deployed.
class PositioningSettings {
  PositioningSettings._();

  static final PositioningSettings instance = PositioningSettings._();

  /// Selected position source.
  IndoorPositioningMode mode = IndoorPositioningMode.mock;

  /// Show the developer overlay in the floor plan screen.
  bool debugOverlayEnabled = false;

  /// EMA smoothing factor (0..1) applied to BLE positions. 1.0 = no smoothing.
  double bleFilterAlpha = 0.4;

  /// Estimated accuracy (meters) reported by the mock provider.
  double mockAccuracyMeters = 2.0;

  /// How often position updates are emitted.
  Duration positionUpdateInterval = const Duration(milliseconds: 300);

  /// Simulated walking speed in normalized map units per second.
  double mockWalkSpeedUnitsPerSecond = 0.12;

  /// Accuracy (meters) above which a position is considered low-confidence.
  double lowConfidenceAccuracyMeters = 12.0;
}