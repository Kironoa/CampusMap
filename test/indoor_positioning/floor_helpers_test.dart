import 'package:flutter_test/flutter_test.dart';
import 'package:naviapp/services/indoor_positioning/floor_helpers.dart';

void main() {
  group('FloorInfo', () {
    test('maps zero-based indexes to names (0 = Ground)', () {
      expect(FloorInfo.name(0), 'Ground Floor');
      expect(FloorInfo.name(1), '2nd Floor');
      expect(FloorInfo.name(2), '3rd Floor');
    });

    test('indexFromName round-trips', () {
      expect(FloorInfo.indexFromName('Ground Floor'), 0);
      expect(FloorInfo.indexFromName('2nd Floor'), 1);
      expect(FloorInfo.indexFromName('3rd Floor'), 2);
      expect(FloorInfo.indexFromName('Basement'), isNull);
    });

    test('displayNumber is 1-based', () {
      expect(FloorInfo.displayNumber(0), '1st');
      expect(FloorInfo.displayNumber(1), '2nd');
      expect(FloorInfo.displayNumber(2), '3rd');
    });

    test('name handles out-of-range indexes without crashing', () {
      expect(FloorInfo.name(-1), 'Floor -1');
      expect(FloorInfo.name(5), 'Floor 5');
    });
  });
}