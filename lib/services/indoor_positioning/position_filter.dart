// lib/services/indoor_positioning/position_filter.dart
import 'indoor_position.dart';

/// Smoothing for noisy position estimates (BLE RSSI fluctuates heavily).
///
/// First version uses an exponential moving average (EMA) per coordinate —
/// simple, zero-dependency and configurable. A Kalman filter can replace
/// this later without touching the providers.
class PositionFilter {
  PositionFilter._();

  /// EMA smoothing of the x/y coordinates.
  ///
  /// [alpha] is the weight given to the new sample (0..1). Low alpha =
  /// very smooth but laggy; 1.0 = no smoothing (passthrough). The floor is
  /// always taken from the newest sample; accuracy is averaged.
  static IndoorPosition ema({
    required IndoorPosition next,
    IndoorPosition? previous,
    double alpha = 0.4,
  }) {
    if (previous == null || alpha >= 1.0) return next;
    final a = alpha.clamp(0.0, 1.0);
    return IndoorPosition(
      x: previous.x + (next.x - previous.x) * a,
      y: previous.y + (next.y - previous.y) * a,
      floor: next.floor,
      accuracy: (previous.accuracy + next.accuracy) / 2.0,
      timestamp: next.timestamp,
      source: next.source,
    );
  }

  /// Convenience: applies [ema] to a stream of positions using a
  /// stateful EMA over time. Returns the same list, smoothed.
  static List<IndoorPosition> smoothList(
    List<IndoorPosition> positions, {
    double alpha = 0.4,
  }) {
    if (positions.isEmpty) return const [];
    final result = <IndoorPosition>[];
    IndoorPosition? previous;
    for (final position in positions) {
      final smoothed = ema(previous: previous, next: position, alpha: alpha);
      result.add(smoothed);
      previous = smoothed;
    }
    return result;
  }
}
