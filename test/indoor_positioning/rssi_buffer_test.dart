// test/indoor_positioning/rssi_buffer_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:naviapp/services/indoor_positioning/rssi_buffer.dart';

void main() {
  group('RssiBuffer', () {
    test('averages samples per beacon', () {
      final buffer = RssiBuffer();
      final t0 = DateTime(2026, 1, 1, 12, 0, 0);

      buffer.add('b1', -60, at: t0);
      buffer.add('b1', -62, at: t0.add(const Duration(seconds: 1)));
      buffer.add('b2', -70, at: t0);

      final readings = buffer.readings();
      expect(readings, hasLength(2));
      expect(readings.firstWhere((r) => r.beaconId == 'b1').rssi, closeTo(-61, 0.001));
      expect(readings.firstWhere((r) => r.beaconId == 'b2').rssi, closeTo(-70, 0.001));
    });

    test('drops samples older than the window', () {
      final buffer = RssiBuffer(window: const Duration(seconds: 10));
      final t0 = DateTime(2026, 1, 1, 12, 0, 0);

      buffer.add('b1', -60, at: t0);
      buffer.add('b1', -80, at: t0.add(const Duration(seconds: 11)));

      final readings = buffer.readings();
      expect(readings, hasLength(1));
      expect(readings.single.rssi, closeTo(-80, 0.001));
    });

    test('keeps at most maxSamplesPerBeacon samples (oldest dropped)', () {
      final buffer = RssiBuffer(maxSamplesPerBeacon: 3);
      final t0 = DateTime(2026, 1, 1, 12, 0, 0);

      for (var i = 0; i < 5; i++) {
        buffer.add('b1', -50.0 - i, at: t0.add(Duration(seconds: i)));
      }

      final readings = buffer.readings();
      expect(readings, hasLength(1));
      // Newest 3 samples: -52, -53, -54 → average -53.
      expect(readings.single.rssi, closeTo(-53, 0.001));
    });

    test('activeBeaconCount counts beacons with live samples', () {
      final buffer = RssiBuffer();
      final t0 = DateTime(2026, 1, 1, 12, 0, 0);

      expect(buffer.activeBeaconCount, 0);
      buffer.add('b1', -60, at: t0);
      buffer.add('b2', -65, at: t0);
      expect(buffer.activeBeaconCount, 2);
    });

    test('clear empties the buffer', () {
      final buffer = RssiBuffer();
      buffer.add('b1', -60);
      buffer.clear();
      expect(buffer.readings(), isEmpty);
      expect(buffer.activeBeaconCount, 0);
    });
  });
}