// lib/services/indoor_positioning/rssi_buffer.dart
import 'beacon_config.dart';

class _Sample {
  final double rssi;
  final DateTime at;

  const _Sample(this.rssi, this.at);
}

/// Sliding window of raw RSSI samples per beacon.
///
/// RSSI is extremely noisy, so raw advertisements are averaged before they
/// reach the estimator. [readings] returns one average per beacon that has
/// at least one sample inside the time window.
class RssiBuffer {
  RssiBuffer({
    this.maxSamplesPerBeacon = BeaconConfig.maxSamplesPerBeacon,
    this.window = BeaconConfig.rssiWindow,
  });

  /// Max samples kept per beacon (oldest dropped first).
  final int maxSamplesPerBeacon;

  /// How long a sample stays relevant before it is dropped.
  final Duration window;

  final Map<String, List<_Sample>> _samples = {};

  /// Records one advertisement. Samples older than [window] are pruned and
  /// the newest [maxSamplesPerBeacon] are kept.
  void add(String beaconId, double rssi, {DateTime? at}) {
    final time = at ?? DateTime.now();
    _samples.putIfAbsent(beaconId, () => []).add(_Sample(rssi, time));
    _prune(beaconId, time);
  }

  void _prune(String beaconId, DateTime now) {
    final list = _samples[beaconId]!;
    final cutoff = now.subtract(window);
    list.removeWhere((s) => s.at.isBefore(cutoff));
    while (list.length > maxSamplesPerBeacon) {
      list.removeAt(0);
    }
  }

  /// One averaged [RssiReading] per beacon with live samples.
  ///
  /// The timestamp is the newest sample's time, so windowing stays simple
  /// for consumers (like the estimator) that read it on demand.
  List<RssiReading> readings() {
    final out = <RssiReading>[];
    _samples.forEach((beaconId, list) {
      if (list.isEmpty) return;
      final sum = list.fold<double>(0.0, (acc, s) => acc + s.rssi);
      out.add(RssiReading(
        beaconId: beaconId,
        rssi: sum / list.length,
        timestamp: list.last.at,
      ));
    });
    return out;
  }

  /// Number of beacons that currently have at least one live sample.
  int get activeBeaconCount =>
      _samples.values.where((list) => list.isNotEmpty).length;

  void clear() => _samples.clear();
}