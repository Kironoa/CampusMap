// lib/services/indoor_positioning/beacon_parser.dart

/// A parsed Apple iBeacon advertisement.
///
/// The [beaconId] format (`uuid:major:minor`) is designed to match
/// [BeaconDefinition.id] entries in `BeaconConfig.beacons`.
class IBeaconPacket {
  final String uuid;
  final int major;
  final int minor;
  final int txPower;

  const IBeaconPacket({
    required this.uuid,
    required this.major,
    required this.minor,
    required this.txPower,
  });

  String get beaconId => '$uuid:$major:$minor';
}

/// Parses raw BLE manufacturer data into iBeacon packets.
///
/// Only Apple iBeacons are supported in this first version (the de-facto
/// standard for indoor beacon deployments). Eddystone and vendor-specific
/// formats can be added here later without touching the provider.
class BeaconParser {
  BeaconParser._();

  /// Apple's Bluetooth SIG company identifier (0x004C).
  static const int appleCompanyId = 0x004C;

  /// Byte layout of an iBeacon payload inside manufacturer data:
  /// `02 15 <uuid:16> <major:2> <minor:2> <txPower:1>` = 23 bytes.
  static const int payloadLength = 23;

  /// Returns the first valid iBeacon packet found in [manufacturerData]
  /// (the map keyed by company id), or null when the advertisement is not
  /// an iBeacon.
  static IBeaconPacket? parseIBeacon(Map<int, List<int>> manufacturerData) {
    final data = manufacturerData[appleCompanyId];
    if (data == null || data.length < payloadLength) return null;
    if (data[0] != 0x02 || data[1] != 0x15) return null;

    final uuid = _formatUuid(data.sublist(2, 18));
    final major = (data[18] << 8) | data[19];
    final minor = (data[20] << 8) | data[21];
    final txPower = data[22].toSigned(8);

    return IBeaconPacket(
      uuid: uuid,
      major: major,
      minor: minor,
      txPower: txPower,
    );
  }

  /// Formats 16 raw uuid bytes as the canonical 8-4-4-4-12 hex string.
  static String _formatUuid(List<int> bytes) {
    final hex =
        bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}