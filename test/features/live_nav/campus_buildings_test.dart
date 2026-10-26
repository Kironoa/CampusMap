// test/features/live_nav/campus_buildings_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:naviapp/features/live_navigation/config/campus_buildings.dart';
import 'package:naviapp/features/live_navigation/models/geo_math.dart';

void main() {
  group('CampusBuildings Main Building (exact supplied coordinates)', () {
    test('12 outline vertices match supplied values in order', () {
      const expected = <NavLatLng>[
        NavLatLng(8.06543, 123.75679),
        NavLatLng(8.06524, 123.75696),
        NavLatLng(8.06436, 123.75592),
        NavLatLng(8.06458, 123.75576),
        NavLatLng(8.06489, 123.75613),
        NavLatLng(8.06502, 123.75604),
        NavLatLng(8.06507, 123.75610),
        NavLatLng(8.06511, 123.75606),
        NavLatLng(8.06521, 123.75618),
        NavLatLng(8.06517, 123.75622),
        NavLatLng(8.06523, 123.75629),
        NavLatLng(8.06513, 123.75639),
      ];
      expect(CampusBuildings.mainBuilding.outline, expected);
    });

    test('ring is closed (13 points, first == last)', () {
      final ring = CampusBuildings.mainBuilding.ringClosed;
      expect(ring.length, 13);
      expect(ring.first, const NavLatLng(8.06543, 123.75679));
      expect(ring.last, ring.first);
      // Outline + closing point == ring.
      expect(
        ring.sublist(0, 12),
        CampusBuildings.mainBuilding.outline,
      );
    });

    test('inside point is detected, far point is outside', () {
      // Centroid of the 12 vertices (verified inside via ray casting).
      const inside = NavLatLng(8.065037, 123.756237);
      expect(
        CampusBuildings.isPointInRing(
          inside,
          CampusBuildings.mainBuilding.outline,
        ),
        isTrue,
      );
      expect(
        CampusBuildings.containing(inside)?.id,
        'main',
      );
      // Tangub City fallback — far outside the building.
      const outside = NavLatLng(8.0625, 123.7458);
      expect(
        CampusBuildings.isPointInRing(
          outside,
          CampusBuildings.mainBuilding.outline,
        ),
        isFalse,
      );
      expect(CampusBuildings.containing(outside), isNull);
    });

    test('labelPoint is the centroid and lies inside', () {
      expect(
        CampusBuildings.mainBuilding.labelPoint.latitude,
        closeTo(8.065037, 1e-6),
      );
      expect(
        CampusBuildings.mainBuilding.labelPoint.longitude,
        closeTo(123.756237, 1e-6),
      );
      expect(
        CampusBuildings.isPointInRing(
          CampusBuildings.mainBuilding.labelPoint,
          CampusBuildings.mainBuilding.outline,
        ),
        isTrue,
      );
      expect(
        CampusBuildings.annexBuilding.labelPoint.latitude,
        closeTo(8.0652125, 1e-6),
      );
      expect(
        CampusBuildings.annexBuilding.labelPoint.longitude,
        closeTo(123.75762125, 1e-6),
      );
      expect(
        CampusBuildings.isPointInRing(
          CampusBuildings.annexBuilding.labelPoint,
          CampusBuildings.annexBuilding.outline,
        ),
        isTrue,
      );
      expect(
        CampusBuildings.tangubAsensoBuilding.labelPoint.latitude,
        closeTo(8.0642925, 1e-6),
      );
      expect(
        CampusBuildings.tangubAsensoBuilding.labelPoint.longitude,
        closeTo(123.75559, 1e-6),
      );
      expect(
        CampusBuildings.isPointInRing(
          CampusBuildings.tangubAsensoBuilding.labelPoint,
          CampusBuildings.tangubAsensoBuilding.outline,
        ),
        isTrue,
      );
    });

    test('generic ray casting works on a unit square', () {
      const square = <NavLatLng>[
        NavLatLng(0, 0),
        NavLatLng(0, 1),
        NavLatLng(1, 1),
        NavLatLng(1, 0),
      ];
      expect(
        CampusBuildings.isPointInRing(const NavLatLng(0.5, 0.5), square),
        isTrue,
      );
      expect(
        CampusBuildings.isPointInRing(const NavLatLng(2, 2), square),
        isFalse,
      );
      expect(CampusBuildings.isPointInRing(const NavLatLng(0, 0), []), isFalse);
    });

    test('building metadata for indoor handoff', () {
      expect(CampusBuildings.mainBuilding.id, 'main');
      expect(CampusBuildings.mainBuilding.name, 'Main Building');
      expect(
        CampusBuildings.mainBuilding.imageAsset,
        'assets/Main Building.jpg',
      );
      expect(CampusBuildings.mainBuilding.floors, 3);
      expect(CampusBuildings.mainBuilding.initialFloor, 0);
      expect(CampusBuildings.annexBuilding.id, 'annex');
      expect(CampusBuildings.annexBuilding.name, 'Annex Building');
      expect(
        CampusBuildings.annexBuilding.imageAsset,
        'assets/Annex Building.jpg',
      );
      expect(
        CampusBuildings.tangubAsensoBuilding.imageAsset,
        'assets/Tangub Asenso Building.jpg',
      );
      expect(CampusBuildings.all.length, 3);
    });
  });

  group('CampusBuildings Annex Building (exact supplied coordinates)', () {
    test('8 outline vertices match supplied values in order', () {
      const expected = <NavLatLng>[
        NavLatLng(8.06562, 123.75741),
        NavLatLng(8.06554, 123.75731),
        NavLatLng(8.06524, 123.75756),
        NavLatLng(8.06522, 123.75754),
        NavLatLng(8.06513, 123.75762),
        NavLatLng(8.06515, 123.75764),
        NavLatLng(8.06486, 123.75790),
        NavLatLng(8.06494, 123.75799),
      ];
      expect(CampusBuildings.annexBuilding.outline, expected);
    });

    test('ring is closed (9 points, first == last)', () {
      final ring = CampusBuildings.annexBuilding.ringClosed;
      expect(ring.length, 9);
      expect(ring.first, const NavLatLng(8.06562, 123.75741));
      expect(ring.last, ring.first);
      expect(ring.sublist(0, 8), CampusBuildings.annexBuilding.outline);
    });

    test('inside centroid detected, geofences do not overlap Main', () {
      // Centroid of the 8 vertices (verified inside via ray casting).
      const inside = NavLatLng(8.0652125, 123.75762125);
      expect(
        CampusBuildings.isPointInRing(
          inside,
          CampusBuildings.annexBuilding.outline,
        ),
        isTrue,
      );
      expect(CampusBuildings.containing(inside)?.id, 'annex');
      // Main centroid is not inside Admin and vice versa.
      const mainInside = NavLatLng(8.065037, 123.756237);
      expect(
        CampusBuildings.isPointInRing(
          mainInside,
          CampusBuildings.annexBuilding.outline,
        ),
        isFalse,
      );
      expect(
        CampusBuildings.isPointInRing(
          inside,
          CampusBuildings.mainBuilding.outline,
        ),
        isFalse,
      );
    });
  });

  group('CampusEntrances (exact supplied coordinates)', () {
    test('5 gates in numbered order with rules', () {
      expect(CampusEntrances.all.length, 5);
      expect(CampusEntrances.entrance1.name, 'Gate 1');
      expect(
        CampusEntrances.entrance1.location,
        const NavLatLng(8.06476, 123.75527),
      );
      expect(CampusEntrances.entrance1.access, contains('Students only'));
      expect(
        CampusEntrances.entrance2.location,
        const NavLatLng(8.06525, 123.75586),
      );
      expect(CampusEntrances.entrance2.access, contains('Vehicles only'));
      expect(
        CampusEntrances.entrance3.location,
        const NavLatLng(8.06548, 123.75611),
      );
      expect(CampusEntrances.entrance3.access, contains('Visitors'));
      expect(
        CampusEntrances.entrance4.location,
        const NavLatLng(8.06594, 123.75665),
      );
      expect(
        CampusEntrances.entrance5.location,
        const NavLatLng(8.06346, 123.75602),
      );
      expect(CampusEntrances.entrance5.access, contains('everyone'));
      for (final e in CampusEntrances.all) {
        expect(e.access.isNotEmpty, isTrue);
      }
    });

    test('nearestWithin finds the gate, far point finds none', () {
      expect(
        CampusEntrances.nearestWithin(
          const NavLatLng(8.06476, 123.75527),
        )?.id,
        'entrance_1',
      );
      expect(
        CampusEntrances.nearestWithin(
          const NavLatLng(8.0625, 123.7458),
        ),
        isNull,
      );
      // ~15 m north of Entrance 1 is inside the 30 m tap radius.
      expect(
        CampusEntrances.nearestWithin(
          const NavLatLng(8.06490, 123.75527),
        )?.id,
        'entrance_1',
      );
    });
  });

  group('CampusBuildings Tangub Asenso Building', () {
    test('4 outline vertices (first point: 8.06457 corrected from 8.6457)', () {
      const expected = <NavLatLng>[
        NavLatLng(8.06457, 123.75572),
        NavLatLng(8.06438, 123.75589),
        NavLatLng(8.06401, 123.75546),
        NavLatLng(8.06421, 123.75529),
      ];
      expect(CampusBuildings.tangubAsensoBuilding.outline, expected);
    });

    test('ring is closed (5 points, first == last)', () {
      final ring = CampusBuildings.tangubAsensoBuilding.ringClosed;
      expect(ring.length, 5);
      expect(ring.first, const NavLatLng(8.06457, 123.75572));
      expect(ring.last, ring.first);
      expect(ring.sublist(0, 4), CampusBuildings.tangubAsensoBuilding.outline);
    });

    test('inside centroid detected, far point outside', () {
      const inside = NavLatLng(8.0642925, 123.75559);
      expect(
        CampusBuildings.isPointInRing(
          inside,
          CampusBuildings.tangubAsensoBuilding.outline,
        ),
        isTrue,
      );
      expect(CampusBuildings.containing(inside)?.id, 'tangub_asenso');
      const outside = NavLatLng(8.0625, 123.7458);
      expect(
        CampusBuildings.isPointInRing(
          outside,
          CampusBuildings.tangubAsensoBuilding.outline,
        ),
        isFalse,
      );
    });
  });
}
