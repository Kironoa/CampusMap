import 'package:flutter_test/flutter_test.dart';
import 'package:naviapp/services/indoor_positioning/indoor_position.dart';
import 'package:naviapp/services/indoor_positioning/position_filter.dart';

IndoorPosition pos(double x, double y, {int floor = 0}) => IndoorPosition(
  x: x,
  y: y,
  floor: floor,
  accuracy: 2.0,
  timestamp: DateTime(2026, 8, 20, 12, 0, 0),
  source: PositionSource.ble,
);

void main() {
  group('PositionFilter.ema', () {
    test('returns the sample unchanged when there is no previous position', () {
      final next = pos(0.4, 0.3);
      final result = PositionFilter.ema(previous: null, next: next, alpha: 0.4);
      expect(result.x, 0.4);
      expect(result.y, 0.3);
    });

    test('alpha 1.0 is passthrough (no smoothing)', () {
      final previous = pos(0.0, 0.0);
      final next = pos(1.0, 1.0);
      final result = PositionFilter.ema(
        previous: previous,
        next: next,
        alpha: 1.0,
      );
      expect(result.x, 1.0);
      expect(result.y, 1.0);
    });

    test('alpha 0.5 moves halfway toward the new sample', () {
      final previous = pos(0.0, 0.0);
      final next = pos(1.0, 0.0);
      final result = PositionFilter.ema(
        previous: previous,
        next: next,
        alpha: 0.5,
      );
      expect(result.x, closeTo(0.5, 0.0001));
      expect(result.y, closeTo(0.0, 0.0001));
    });

    test('low alpha smooths more aggressively', () {
      final previous = pos(0.0, 0.0);
      final next = pos(1.0, 0.0);
      final result = PositionFilter.ema(
        previous: previous,
        next: next,
        alpha: 0.1,
      );
      expect(result.x, closeTo(0.1, 0.0001));
    });

    test('floor always follows the newest sample', () {
      final previous = pos(0.2, 0.2, floor: 0);
      final next = pos(0.8, 0.8, floor: 2);
      final result = PositionFilter.ema(
        previous: previous,
        next: next,
        alpha: 0.4,
      );
      expect(result.floor, 2);
    });

    test('keeps source and timestamp of the newest sample', () {
      final previous = pos(0.2, 0.2);
      final next = pos(0.8, 0.8);
      final result = PositionFilter.ema(
        previous: previous,
        next: next,
        alpha: 0.4,
      );
      expect(result.source, PositionSource.ble);
      expect(result.timestamp, next.timestamp);
    });
  });

  group('PositionFilter.smoothList', () {
    test('smooths a sequence progressively', () {
      final raw = [pos(0.0, 0.0), pos(1.0, 0.0), pos(1.0, 0.0)];
      final smoothed = PositionFilter.smoothList(raw, alpha: 0.5);
      expect(smoothed.length, 3);
      expect(smoothed[0].x, 0.0);
      expect(smoothed[1].x, closeTo(0.5, 0.0001));
      expect(smoothed[2].x, closeTo(0.75, 0.0001));
    });

    test('returns empty for empty input', () {
      expect(PositionFilter.smoothList(const []), isEmpty);
    });
  });
}
