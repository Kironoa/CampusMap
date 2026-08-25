// test/models/starting_location_qr_test.dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:naviapp/config/starting_locations.dart';
import 'package:naviapp/models/starting_location.dart';
import 'package:naviapp/providers/user_location_provider.dart';
import 'package:naviapp/services/indoor_positioning/indoor_position.dart';

void main() {
  group('starting location configuration', () {
    test('exactly the seven Ground Floor locations are configured', () {
      const ids = [
        'GF_MAIN_ENTRANCE',
        'GF_LOBBY_LEFT_STAIRCASE',
        'GF_LOBBY_RIGHT_STAIRCASE',
        'GF_LEFT_WING_STAIRCASE',
        'GF_RIGHT_WING_STAIRCASE',
        'GF_LEFT_SIDE_DOOR',
        'GF_RIGHT_SIDE_DOOR',
      ];
      expect(StartingLocations.groundFloorLocations.length, 7);
      expect(
        StartingLocations.groundFloorLocations.map((l) => l.id).toSet(),
        ids.toSet(),
      );
    });

    test('all locations are on the ground floor of the main building', () {
      for (final location in StartingLocations.groundFloorLocations) {
        expect(location.floor, 0, reason: location.id);
        expect(location.building, 'MAIN_BUILDING', reason: location.id);
      }
    });

    test('coordinates are normalized and distinct per location', () {
      final seen = <String>{};
      for (final location in StartingLocations.groundFloorLocations) {
        expect(location.x, inInclusiveRange(0.0, 1.0), reason: location.id);
        expect(location.y, inInclusiveRange(0.0, 1.0), reason: location.id);
        final key = '${location.x},${location.y}';
        expect(seen.contains(key), isFalse,
            reason:
                '${location.id} shares its coordinates with another location');
        seen.add(key);
      }
    });
  });

  group('QR payload generation', () {
    test('Main Entrance payload matches the Campus Guide schema', () {
      final mainEntrance = StartingLocations.byId('GF_MAIN_ENTRANCE');
      expect(mainEntrance, isNotNull);
      expect(mainEntrance!.name, 'Main Entrance');
      expect(jsonDecode(mainEntrance.qrData), {
        'type': 'campus_guide_starting_point',
        'building': 'MAIN_BUILDING',
        'floor': 0,
        'location_id': 'GF_MAIN_ENTRANCE',
      });
    });

    test('every generated QR payload carries its own unique location ID', () {
      final payloads = <String>{};
      for (final location in StartingLocations.groundFloorLocations) {
        final json = jsonDecode(location.qrData) as Map<String, dynamic>;
        expect(json['type'], CampusGuideQr.validType, reason: location.id);
        expect(json['location_id'], location.id, reason: location.id);
        expect(payloads.contains(location.qrData), isFalse,
            reason: "${location.id} reuses another location's QR data");
        payloads.add(location.qrData);
      }
      expect(payloads.length, 7);
    });

    test('CampusGuideQr round-trips through encode/tryParse', () {
      const original = CampusGuideQr(
        type: CampusGuideQr.validType,
        building: 'MAIN_BUILDING',
        floor: 0,
        locationId: 'GF_MAIN_ENTRANCE',
      );
      final parsed = CampusGuideQr.tryParse(original.encode());
      expect(parsed, original);
    });
  });

  group('QR validation (scan flow)', () {
    test('each of the seven codes resolves to its own location', () {
      for (final expected in StartingLocations.groundFloorLocations) {
        final resolved = StartingLocations.fromQrData(expected.qrData);
        expect(resolved, isNotNull, reason: expected.id);
        expect(resolved!.id, expected.id);
        expect(resolved.name, expected.name);
        expect(resolved.x, expected.x);
        expect(resolved.y, expected.y);
        expect(resolved.floor, 0);
      }
    });

    test('rejects unrelated QR payloads without throwing', () {
      const unrelated = [
        'https://example.com/some-website',
        'WIFI:T:WPA;S:MyNetwork;P:password;;',
        'just some plain text',
        '',
        '{"type": "OTHER_APP_PAYLOAD", "data": 123}',
        // missing location_id:
        '{"type": "campus_guide_starting_point", "building": "MAIN_BUILDING", "floor": 0}',
        // non-integer floor:
        '{"type": "campus_guide_starting_point", "building": "MAIN_BUILDING", "floor": "zero", "location_id": "GF_MAIN_ENTRANCE"}',
        // wrong building:
        '{"type": "campus_guide_starting_point", "building": "OTHER_BUILDING", "floor": 0, "location_id": "GF_MAIN_ENTRANCE"}',
        // unknown id:
        '{"type": "campus_guide_starting_point", "building": "MAIN_BUILDING", "floor": 0, "location_id": "GF_UNKNOWN_PLACE"}',
        '{broken json',
      ];
      for (final raw in unrelated) {
        expect(StartingLocations.fromQrData(raw), isNull, reason: raw);
      }
    });
  });

  group('toIndoorPosition', () {
    test('produces an exact manual position on the configured spot', () {
      final location = StartingLocations.byId('GF_LEFT_WING_STAIRCASE')!;
      final position = location.toIndoorPosition();
      expect(position.source, PositionSource.manual);
      expect(position.floor, 0);
      expect(position.x, closeTo(location.x, 1e-9));
      expect(position.y, closeTo(location.y, 1e-9));
    });
  });

  group('UserLocationProvider', () {
    test('a valid scan pins the position to that location', () {
      final provider = UserLocationProvider();
      final location = StartingLocations.byId('GF_LOBBY_RIGHT_STAIRCASE')!;

      provider.setFromStartingLocation(location);

      expect(provider.hasManualPosition, isTrue);
      expect(provider.startingLocation!.id, 'GF_LOBBY_RIGHT_STAIRCASE');
      expect(provider.position!.x, location.x);
      expect(provider.position!.y, location.y);
      expect(provider.position!.floor, 0);
    });

    test('live updates do not override a pinned QR position', () {
      final provider = UserLocationProvider();
      final entrance = StartingLocations.byId('GF_MAIN_ENTRANCE')!;
      provider.setFromStartingLocation(entrance);

      provider.updateFromLivePosition(IndoorPosition(
        x: 0.1,
        y: 0.9,
        floor: 2,
        accuracy: 3,
        timestamp: DateTime(2026, 8, 25),
        source: PositionSource.mock,
      ));

      expect(provider.position!.x, entrance.x);
      expect(provider.position!.y, entrance.y);
      expect(provider.position!.floor, 0);
    });

    test('clear removes the pin so live positioning resumes', () {
      final provider = UserLocationProvider()
        ..setFromStartingLocation(StartingLocations.byId('GF_LEFT_SIDE_DOOR')!)
        ..clear();
      expect(provider.hasManualPosition, isFalse);
      expect(provider.startingLocation, isNull);
      expect(provider.position, isNull);
    });
  });
}
