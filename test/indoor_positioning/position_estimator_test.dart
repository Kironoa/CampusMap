import 'package:flutter_test/flutter_test.dart';
import 'package:naviapp/services/indoor_positioning/beacon_config.dart';
import 'package:naviapp/services/indoor_positioning/indoor_position.dart';
import 'package:naviapp/services/indoor_positioning/position_estimator.dart';

void main() {
  group('PositionEstimator.distanceFromRssi', () {
    test('returns 1 m when RSSI equals txPower', () {
      expect(PositionEstimator.distanceFromRssi(-59, -59), closeTo(1.0, 0.01));
    });

    test('returns ~2 m for 6 dB attenuation with n = 2.0', () {
      expect(PositionEstimator.distanceFromRssi(-65, -59), closeTo(2.0, 0.05));
    });

    test('returns ~10 m for 20 dB attenuation with n = 2.0', () {
      expect(PositionEstimator.distanceFromRssi(-79, -59), closeTo(10.0, 0.2));
    });

    test('respects a custom path-loss exponent', () {
      // n = 3.0: 6 dB -> 10^(6/30) ~ 1.58 m
      expect(
        PositionEstimator.distanceFromRssi(-65, -59, n: 3.0),
        closeTo(1.58, 0.05),
      );
    });
  });

  group('PositionEstimator.isUsableRssi', () {
    test('accepts typical indoor RSSI', () {
      expect(PositionEstimator.isUsableRssi(-60), isTrue);
      expect(PositionEstimator.isUsableRssi(-95), isTrue);
    });

    test('rejects out-of-range samples', () {
      expect(PositionEstimator.isUsableRssi(-110), isFalse);
      expect(PositionEstimator.isUsableRssi(-5), isFalse);
    });
  });

  group('PositionEstimator.estimatePosition', () {
    const beacons = [
      BeaconDefinition(id: 'A', floor: 0, x: 0.2, y: 0.2, txPower: -59),
      BeaconDefinition(id: 'B', floor: 0, x: 0.8, y: 0.2, txPower: -59),
      BeaconDefinition(id: 'C', floor: 0, x: 0.5, y: 0.8, txPower: -59),
    ];

    DateTime now() => DateTime(2026, 8, 20, 12, 0, 0);

    test('estimates a position weighted toward the strongest beacon', () {
      final estimate = PositionEstimator.estimatePosition(
        beacons: beacons,
        readings: [
          RssiReading(beaconId: 'A', rssi: -60, timestamp: now()),
          RssiReading(beaconId: 'B', rssi: -70, timestamp: now()),
          RssiReading(beaconId: 'C', rssi: -80, timestamp: now()),
        ],
      );

      expect(estimate.hasFix, isTrue);
      expect(estimate.beaconCount, 3);
      expect(estimate.confidence, greaterThan(0));
      expect(estimate.position!.floor, 0);
      expect(estimate.position!.source, PositionSource.ble);
      expect(estimate.position!.x, lessThan(0.5));
      expect(estimate.position!.y, lessThan(0.5));
      expect(estimate.position!.accuracy, greaterThan(0));
    });

    test('averages repeated samples per beacon', () {
      final estimate = PositionEstimator.estimatePosition(
        beacons: beacons,
        readings: [
          // A alternates between -40 (close) and -80 (far): avg -60.
          RssiReading(beaconId: 'A', rssi: -40, timestamp: now()),
          RssiReading(beaconId: 'A', rssi: -80, timestamp: now()),
          RssiReading(beaconId: 'B', rssi: -70, timestamp: now()),
          RssiReading(beaconId: 'C', rssi: -80, timestamp: now()),
        ],
      );
      expect(estimate.hasFix, isTrue);
      expect(estimate.beaconCount, 3);
    });

    test('returns no fix when fewer than minBeaconsForFix are usable', () {
      final estimate = PositionEstimator.estimatePosition(
        beacons: beacons,
        readings: [
          RssiReading(beaconId: 'A', rssi: -60, timestamp: now()),
        ],
      );
      expect(estimate.hasFix, isFalse);
      expect(estimate.position, isNull);
      expect(estimate.confidence, 0.0);
      expect(estimate.beaconCount, 1);
    });

    test('ignores unknown beacon ids', () {
      final estimate = PositionEstimator.estimatePosition(
        beacons: beacons,
        readings: [
          RssiReading(beaconId: 'NOT_CONFIGURED', rssi: -60, timestamp: now()),
          RssiReading(beaconId: 'ALSO_UNKNOWN', rssi: -55, timestamp: now()),
        ],
      );
      expect(estimate.hasFix, isFalse);
      expect(estimate.beaconCount, 0);
    });

    test('ignores unusable RSSI samples', () {
      final estimate = PositionEstimator.estimatePosition(
        beacons: beacons,
        readings: [
          RssiReading(beaconId: 'A', rssi: -110, timestamp: now()), // too weak
          RssiReading(beaconId: 'B', rssi: -70, timestamp: now()),
          RssiReading(beaconId: 'C', rssi: -80, timestamp: now()),
        ],
      );
      expect(estimate.hasFix, isTrue);
      expect(estimate.beaconCount, 2);
    });

    test('clamps coordinates to 0..1', () {
      const outOfRangeBeacons = [
        BeaconDefinition(id: 'A', floor: 2, x: -0.05, y: 1.05, txPower: -59),
        BeaconDefinition(id: 'B', floor: 2, x: 0.5, y: 0.5, txPower: -59),
      ];
      final estimate = PositionEstimator.estimatePosition(
        beacons: outOfRangeBeacons,
        readings: [
          RssiReading(beaconId: 'A', rssi: -59, timestamp: now()),
          RssiReading(beaconId: 'B', rssi: -80, timestamp: now()),
        ],
      );
      expect(estimate.hasFix, isTrue);
      expect(estimate.position!.x, 0.0);
      expect(estimate.position!.y, 1.0);
    });

    test('floor is selected by weighted majority vote', () {
      const mixedFloorBeacons = [
        BeaconDefinition(id: 'A', floor: 2, x: 0.2, y: 0.2, txPower: -59),
        BeaconDefinition(id: 'B', floor: 0, x: 0.8, y: 0.2, txPower: -59),
        BeaconDefinition(id: 'C', floor: 0, x: 0.5, y: 0.8, txPower: -59),
      ];
      final estimate = PositionEstimator.estimatePosition(
        beacons: mixedFloorBeacons,
        readings: [
          RssiReading(beaconId: 'A', rssi: -55, timestamp: now()),
          RssiReading(beaconId: 'B', rssi: -80, timestamp: now()),
          RssiReading(beaconId: 'C', rssi: -80, timestamp: now()),
        ],
      );
      expect(estimate.hasFix, isTrue);
      expect(estimate.position!.floor, 2);
    });
  });

  group('IndoorPosition.clampCoordinate', () {
    test('clamps out-of-range values', () {
      expect(IndoorPosition.clampCoordinate(-0.5), 0.0);
      expect(IndoorPosition.clampCoordinate(1.5), 1.0);
    });

    test('passes through valid values', () {
      expect(IndoorPosition.clampCoordinate(0.0), 0.0);
      expect(IndoorPosition.clampCoordinate(0.42), 0.42);
      expect(IndoorPosition.clampCoordinate(1.0), 1.0);
    });
  });
}