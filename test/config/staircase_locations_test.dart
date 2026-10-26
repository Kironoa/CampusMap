// test/config/staircase_locations_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:naviapp/config/staircase_locations.dart';
import 'package:naviapp/config/starting_locations.dart';

void main() {
  group('staircase configuration', () {
    test('every floor exposes its configured staircases', () {
      expect(StaircaseLocations.forFloor(0).length, 4);
      expect(StaircaseLocations.forFloor(1).length, 5);
      expect(StaircaseLocations.forFloor(2).length, 3);
    });

    test('only real staircases are listed', () {
      for (var floor = 0; floor < 3; floor++) {
        for (final staircase in StaircaseLocations.forFloor(floor)) {
          expect(
            staircase.name.toLowerCase(),
            contains('staircase'),
            reason: staircase.id,
          );
        }
      }
    });

    test('all staircases live on the floor they are listed under', () {
      for (var floor = 0; floor < 3; floor++) {
        for (final staircase in StaircaseLocations.forFloor(floor)) {
          expect(staircase.floor, floor, reason: staircase.id);
        }
      }
    });

    test('every staircase QR resolves back to its own location', () {
      final payloads = <String>{};
      for (var floor = 0; floor < 3; floor++) {
        for (final staircase in StaircaseLocations.forFloor(floor)) {
          final resolved = StartingLocations.fromQrData(staircase.qrData);
          expect(resolved, isNotNull, reason: staircase.id);
          expect(resolved!.id, staircase.id);
          expect(payloads.add(staircase.qrData), isTrue, reason: staircase.id);
        }
      }
    });

    test('legacy bookkeeping suffix is hidden from labels', () {
      final legacy = StartingLocations.byId('SF_BOTTOM_LEFT_STAIRCASE')!;
      expect(StaircaseLocations.labelFor(legacy), 'Bottom Left Staircase');
    });
  });
}
