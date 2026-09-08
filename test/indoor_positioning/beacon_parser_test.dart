// test/indoor_positioning/beacon_parser_test.dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:naviapp/services/indoor_positioning/beacon_parser.dart';

void main() {
  group('BeaconParser', () {
    // Canonical iBeacon test UUID: E2C56DB5-DFFB-48D2-B060-D0F5A71096E0
    final uuidBytes = Uint8List.fromList([
      0xE2, 0xC5, 0x6D, 0xB5, 0xDF, 0xFB, 0x48, 0xD2, //
      0xB0, 0x60, 0xD0, 0xF5, 0xA7, 0x10, 0x96, 0xE0,
    ]);

    List<int> iBeaconPayload({
      int major = 1,
      int minor = 42,
      int txPower = -59,
    }) {
      return [
        0x02, 0x15, //
        ...uuidBytes,
        (major >> 8) & 0xFF, major & 0xFF,
        (minor >> 8) & 0xFF, minor & 0xFF,
        txPower & 0xFF,
      ];
    }

    test('parses a valid iBeacon advertisement', () {
      final packet = BeaconParser.parseIBeacon({
        BeaconParser.appleCompanyId: iBeaconPayload(),
      });

      expect(packet, isNotNull);
      expect(packet!.uuid, 'e2c56db5-dffb-48d2-b060-d0f5a71096e0');
      expect(packet.major, 1);
      expect(packet.minor, 42);
      expect(packet.txPower, -59);
      expect(packet.beaconId, 'e2c56db5-dffb-48d2-b060-d0f5a71096e0:1:42');
    });

    test('negative txPower is parsed as a signed byte', () {
      final packet = BeaconParser.parseIBeacon({
        BeaconParser.appleCompanyId: iBeaconPayload(txPower: -70),
      });
      expect(packet!.txPower, -70);
    });

    test('returns null for a truncated payload', () {
      final data = iBeaconPayload().sublist(0, 10);
      expect(
        BeaconParser.parseIBeacon({BeaconParser.appleCompanyId: data}),
        isNull,
      );
    });

    test('returns null when the payload is not iBeacon (bad type byte)', () {
      final data = iBeaconPayload();
      data[0] = 0x03;
      expect(
        BeaconParser.parseIBeacon({BeaconParser.appleCompanyId: data}),
        isNull,
      );
    });

    test('returns null when the company id does not match', () {
      expect(BeaconParser.parseIBeacon({0x1234: iBeaconPayload()}), isNull);
    });

    test('returns null for an empty manufacturer data map', () {
      expect(BeaconParser.parseIBeacon(const {}), isNull);
    });
  });
}
