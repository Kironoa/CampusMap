// lib/services/indoor_positioning/beacon_config.dart

/// A single configured BLE beacon.
///
/// PLACEHOLDER COORDINATES: the x/y values below are invented for
/// development only. Replace them with positions surveyed in the real
/// building before relying on BLE positioning. Floor index convention:
/// 0 = Ground, 1 = 2nd Floor, 2 = 3rd Floor.
class BeaconDefinition {
  /// Stable identifier that matches the physical beacon. For iBeacon-style
  /// devices use e.g. 'uuid:major:minor'; for other devices use the
  /// advertised MAC or manufacturer-data key.
  final String id;

  /// Zero-based floor this beacon is mounted on.
  final int floor;

  /// Normalized map coordinate (0..1 over the floor-plan image).
  final double x;
  final double y;

  /// Measured RSSI (dBm) at 1 meter distance (calibrated per device).
  final double txPower;

  const BeaconDefinition({
    required this.id,
    required this.floor,
    required this.x,
    required this.y,
    this.txPower = -59,
  });
}

/// A raw BLE scan observation for one beacon.
class RssiReading {
  final String beaconId;
  final double rssi;
  final DateTime timestamp;

  const RssiReading({
    required this.beaconId,
    required this.rssi,
    required this.timestamp,
  });
}

/// Central beacon + RSSI positioning configuration.
///
/// The `beacons` list is the ONLY place that maps physical beacons to
/// normalized floor-plan coordinates. Tune everything here after
/// surveying the building.
class BeaconConfig {
  BeaconConfig._();

  /// Number of usable beacons required before a position is reported.
  static const int minBeaconsForFix = 2;

  /// Beacons whose average RSSI is better (stronger) than this are ignored
  /// as likely broken/too-close outliers.
  static const double maxUsableRssi = -20.0;

  /// Beacons weaker than this are ignored (out of range / noise).
  static const double minUsableRssi = -100.0;

  /// Path-loss exponent `n` in the log-distance model. 2.0 = free space.
  static const double pathLossExponent = 2.0;

  /// Default transmit power (dBm at 1 m) used when a beacon definition
  /// does not override it.
  static const double defaultTxPower = -59.0;

  /// How long RSSI samples are kept per beacon (sliding window).
  static const Duration rssiWindow = Duration(seconds: 10);

  /// Number of recent samples averaged per beacon before estimating.
  static const int maxSamplesPerBeacon = 5;

  /// PLACEHOLDER beacons — REPLACE with ids + x/y from a physical survey.
  ///
  /// Development UUID `e2c56db5-dffb-48d2-b060-d0f5a71096e0` (the widely
  /// used Apple iBeacon test UUID). Floor = major number, beacon = minor,
  /// so a physical beacon can be identified by (uuid, major, minor).
  /// Layout per floor: two corridor beacons + one room-area beacon,
  /// deliberately spaced so weighted-centroid estimation can be tested.
  static const List<BeaconDefinition> beacons = [
    // ── Ground floor (floor 0, major 1) ────────────────────────────────
    BeaconDefinition(
      id: 'e2c56db5-dffb-48d2-b060-d0f5a71096e0:1:1',
      floor: 0,
      x: 0.20,
      y: 0.30,
    ),
    BeaconDefinition(
      id: 'e2c56db5-dffb-48d2-b060-d0f5a71096e0:1:2',
      floor: 0,
      x: 0.70,
      y: 0.30,
    ),
    BeaconDefinition(
      id: 'e2c56db5-dffb-48d2-b060-d0f5a71096e0:1:3',
      floor: 0,
      x: 0.50,
      y: 0.70,
    ),
    // ── 2nd floor (floor 1, major 2) ───────────────────────────────────
    BeaconDefinition(
      id: 'e2c56db5-dffb-48d2-b060-d0f5a71096e0:2:1',
      floor: 1,
      x: 0.20,
      y: 0.30,
    ),
    BeaconDefinition(
      id: 'e2c56db5-dffb-48d2-b060-d0f5a71096e0:2:2',
      floor: 1,
      x: 0.70,
      y: 0.30,
    ),
    BeaconDefinition(
      id: 'e2c56db5-dffb-48d2-b060-d0f5a71096e0:2:3',
      floor: 1,
      x: 0.50,
      y: 0.70,
    ),
    // ── 3rd floor (floor 2, major 3) ───────────────────────────────────
    BeaconDefinition(
      id: 'e2c56db5-dffb-48d2-b060-d0f5a71096e0:3:1',
      floor: 2,
      x: 0.20,
      y: 0.30,
    ),
    BeaconDefinition(
      id: 'e2c56db5-dffb-48d2-b060-d0f5a71096e0:3:2',
      floor: 2,
      x: 0.70,
      y: 0.30,
    ),
    BeaconDefinition(
      id: 'e2c56db5-dffb-48d2-b060-d0f5a71096e0:3:3',
      floor: 2,
      x: 0.50,
      y: 0.70,
    ),
  ];

  /// Looks up a configured beacon by its stable id.
  static BeaconDefinition? beaconById(String id) {
    for (final beacon in beacons) {
      if (beacon.id == id) return beacon;
    }
    return null;
  }
}
