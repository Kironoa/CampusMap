// lib/services/indoor_positioning/position_estimator.dart
import 'dart:math' as math;

import 'beacon_config.dart';
import 'indoor_position.dart';

/// Result of a position estimation attempt.
class PositionEstimate {
  /// Best estimate, or null when confidence was too low to report a fix.
  final IndoorPosition? position;

  /// 0..1 confidence (beacon count + signal strength based).
  final double confidence;

  /// Number of usable beacons that contributed to this estimate.
  final int beaconCount;

  const PositionEstimate({
    required this.position,
    required this.confidence,
    required this.beaconCount,
  });

  bool get hasFix => position != null;
}

/// RSSI → distance → position estimation (weighted centroid).
///
/// Honest about its limitations: RSSI in buildings is noisy and NOT
/// centimeter-accurate. The estimator therefore reports a confidence and
/// refuses to produce a fix when too few beacons are usable.
class PositionEstimator {
  PositionEstimator._();

  /// Log-distance path-loss model:
  ///   distance = 10 ^ ((txPower - rssi) / (10 * n))
  static double distanceFromRssi(
    double rssi,
    double txPower, {
    double n = BeaconConfig.pathLossExponent,
  }) {
    return math.pow(10.0, (txPower - rssi) / (10.0 * n)).toDouble();
  }

  /// True when the RSSI sample is within the usable range.
  static bool isUsableRssi(double rssi) =>
      rssi >= BeaconConfig.minUsableRssi && rssi <= BeaconConfig.maxUsableRssi;

  /// Estimates the user position from a batch of RSSI readings.
  ///
  /// - Unknown beacon ids are ignored.
  /// - Unusable (too weak / impossible) RSSI samples are ignored.
  /// - Distances come from [distanceFromRssi].
  /// - The position is a signal-strength-weighted centroid of the beacon
  ///   positions (weight = 1 / distance^2).
  /// - The floor is the majority vote among contributing beacons.
  /// - Coordinates are clamped to 0..1.
  ///
  /// Returns a low-confidence result (no fix) when fewer than
  /// [BeaconConfig.minBeaconsForFix] beacons are usable.
  static PositionEstimate estimatePosition({
    required List<RssiReading> readings,
    List<BeaconDefinition>? beacons,
  }) {
    final configured = beacons ?? BeaconConfig.beacons;

    final knownIds = <String>{for (final b in configured) b.id};

    // Average usable samples per configured beacon.
    final averages = <String, double>{};
    final counts = <String, int>{};
    for (final reading in readings) {
      if (!isUsableRssi(reading.rssi)) continue;
      if (!knownIds.contains(reading.beaconId)) continue;
      averages[reading.beaconId] =
          (averages[reading.beaconId] ?? 0.0) + reading.rssi;
      counts[reading.beaconId] = (counts[reading.beaconId] ?? 0) + 1;
    }

    final contributing = <(BeaconDefinition, double)>[];
    for (final beacon in configured) {
      final count = counts[beacon.id];
      if (count == null || count == 0) continue;
      final avgRssi = averages[beacon.id]! / count;
      final distance = distanceFromRssi(avgRssi, beacon.txPower);
      contributing.add((beacon, distance));
    }

    final beaconCount = contributing.length;
    if (beaconCount < BeaconConfig.minBeaconsForFix) {
      return PositionEstimate(
        position: null,
        confidence: 0.0,
        beaconCount: beaconCount,
      );
    }

    // Weighted centroid with weight = 1/d² (closer beacons dominate).
    var weightSum = 0.0;
    var xSum = 0.0;
    var ySum = 0.0;
    var floorVotes = <int, double>{};
    for (final (beacon, distance) in contributing) {
      final weight = 1.0 / (distance * distance + 0.01);
      weightSum += weight;
      xSum += beacon.x * weight;
      ySum += beacon.y * weight;
      floorVotes[beacon.floor] = (floorVotes[beacon.floor] ?? 0.0) + weight;
    }

    final x = IndoorPosition.clampCoordinate(xSum / weightSum);
    final y = IndoorPosition.clampCoordinate(ySum / weightSum);

    int floor = contributing.first.$1.floor;
    var floorVote = -1.0;
    floorVotes.forEach((candidate, vote) {
      if (vote > floorVote) {
        floorVote = vote;
        floor = candidate;
      }
    });

    // Confidence: base on beacon count, scaled by average signal strength.
    final avgDistance =
        contributing.map((c) => c.$2).reduce((a, b) => a + b) / beaconCount;
    // 1 beacon ≈ low, 3+ ≈ high; strong signals (small distances) add to it.
    final confidence =
        ((beaconCount - BeaconConfig.minBeaconsForFix + 1) /
                2.0 *
                (1.0 / (1.0 + avgDistance / 10.0)))
            .clamp(0.0, 1.0);

    return PositionEstimate(
      position: IndoorPosition(
        x: x,
        y: y,
        floor: floor,
        // Rough error estimate: weighted by distance spread of contributors.
        accuracy: _estimateAccuracy(contributing),
        timestamp: DateTime.now(),
        source: PositionSource.ble,
      ),
      confidence: confidence,
      beaconCount: beaconCount,
    );
  }

  /// Rough accuracy in meters: average contributor distance scaled down by
  /// the number of beacons (more beacons → better).
  static double _estimateAccuracy(
    List<(BeaconDefinition, double)> contributing,
  ) {
    final avgDistance =
        contributing.map((c) => c.$2).reduce((a, b) => a + b) /
        contributing.length;
    return avgDistance / math.sqrt(contributing.length);
  }
}
