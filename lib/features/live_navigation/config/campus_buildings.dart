// lib/features/live_navigation/config/campus_buildings.dart
//
// Single source of truth for campus building footprints (outdoor geofences)
// and entrance gates.
//
// - Coordinates are exact user-supplied values in (latitude, longitude).
//   Do NOT modify, approximate, or replace them with guessed values.
// - Same data drives the MapLibre overlays, the enter-building geofence,
//   and the tap popups so visuals and triggers cannot drift apart.
// - Append more buildings following the same pattern (id, name, outline,
//   floors). Per-building indoor floor-plan images are a separate step —
//   FloorPlanScreen currently shows the Main Building plans for every
//   building until those images are supplied.
//
// Main Building polygon (12 vertices, given order, closed by repeating first):
//   (8.06543,123.75679), (8.06524,123.75696), (8.06436,123.75592),
//   (8.06458,123.75576), (8.06489,123.75613), (8.06502,123.75604),
//   (8.06507,123.75610), (8.06511,123.75606), (8.06521,123.75618),
//   (8.06517,123.75622), (8.06523,123.75629), (8.06513,123.75639)
import '../models/geo_math.dart';

/// One campus building footprint.
class CampusBuilding {
  const CampusBuilding({
    required this.id,
    required this.name,
    required this.outline,
    required this.ringClosed,
    required this.imageAsset,
    this.floors = 1,
    this.initialFloor = 0,
  });

  /// Stable id, e.g. 'main'.
  final String id;

  /// Display name, e.g. 'Main Building'. Matches the photo filename
  /// (assets/<name>.jpg) — keep them in sync when renaming.
  final String name;

  /// Vertices in supplied order (no duplicate closing point).
  final List<NavLatLng> outline;

  /// Closed exterior ring (first point repeated at the end).
  final List<NavLatLng> ringClosed;

  /// Bundled photo shown when the building is tapped on the map.
  final String imageAsset;

  /// Number of indoor floors (FloorPlanScreen has 3 for Main).
  final int floors;

  /// Floor to open first in indoor mode.
  final int initialFloor;

  /// Label anchor: arithmetic mean of outline vertices. Verified inside
  /// each footprint in tests; used for the map name label. Same data as the
  /// geofence so label and trigger cannot drift apart.
  NavLatLng get labelPoint {
    var lat = 0.0;
    var lon = 0.0;
    for (final p in outline) {
      lat += p.latitude;
      lon += p.longitude;
    }
    return NavLatLng(lat / outline.length, lon / outline.length);
  }
}

class CampusBuildings {
  CampusBuildings._();

  /// Main Building footprint — exact supplied coordinates.
  static const CampusBuilding mainBuilding = CampusBuilding(
    id: 'main',
    name: 'Main Building',
    imageAsset: 'assets/Main Building.jpg',
    outline: <NavLatLng>[
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
    ],
    ringClosed: <NavLatLng>[
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
      NavLatLng(8.06543, 123.75679),
    ],
    floors: 3,
    initialFloor: 0,
  );

  /// Annex Building footprint — exact supplied coordinates (8 vertices).
  static const CampusBuilding annexBuilding = CampusBuilding(
    id: 'annex',
    name: 'Annex Building',
    imageAsset: 'assets/Annex Building.jpg',
    outline: <NavLatLng>[
      NavLatLng(8.06562, 123.75741),
      NavLatLng(8.06554, 123.75731),
      NavLatLng(8.06524, 123.75756),
      NavLatLng(8.06522, 123.75754),
      NavLatLng(8.06513, 123.75762),
      NavLatLng(8.06515, 123.75764),
      NavLatLng(8.06486, 123.75790),
      NavLatLng(8.06494, 123.75799),
    ],
    ringClosed: <NavLatLng>[
      NavLatLng(8.06562, 123.75741),
      NavLatLng(8.06554, 123.75731),
      NavLatLng(8.06524, 123.75756),
      NavLatLng(8.06522, 123.75754),
      NavLatLng(8.06513, 123.75762),
      NavLatLng(8.06515, 123.75764),
      NavLatLng(8.06486, 123.75790),
      NavLatLng(8.06494, 123.75799),
      NavLatLng(8.06562, 123.75741),
    ],
    // TODO: update floors/initialFloor when Annex indoor plans are supplied.
    // FloorPlanScreen currently shows Main Building plans for every building.
    floors: 1,
    initialFloor: 0,
  );

  /// Tangub Asenso Building footprint (4 vertices).
  ///
  /// NOTE: supplied first point "8.6457, 123.75572" is ~64 km north of campus
  /// (0.58 deg latitude off) and looks like a dropped "0" for 8.06457.
  /// Stored here as 8.06457 — reply with the correct value if different and
  /// it is a one-line fix.
  static const CampusBuilding tangubAsensoBuilding = CampusBuilding(
    id: 'tangub_asenso',
    name: 'Tangub Asenso Building',
    imageAsset: 'assets/Tangub Asenso Building.jpg',
    outline: <NavLatLng>[
      NavLatLng(8.06457, 123.75572),
      NavLatLng(8.06438, 123.75589),
      NavLatLng(8.06401, 123.75546),
      NavLatLng(8.06421, 123.75529),
    ],
    ringClosed: <NavLatLng>[
      NavLatLng(8.06457, 123.75572),
      NavLatLng(8.06438, 123.75589),
      NavLatLng(8.06401, 123.75546),
      NavLatLng(8.06421, 123.75529),
      NavLatLng(8.06457, 123.75572),
    ],
    // TODO: update floors/initialFloor when Tangub indoor plans are supplied.
    floors: 1,
    initialFloor: 0,
  );

  /// All known buildings — map overlay loops this, geofence checks in order.
  static const List<CampusBuilding> all = <CampusBuilding>[
    mainBuilding,
    annexBuilding,
    tangubAsensoBuilding,
  ];

  /// Tap radius for entrance markers (meters). Taps within this distance of
  /// an entrance open its info card instead of dropping a destination pin.
  static const double entranceTapRadiusMeters = 30.0;

  /// Returns the first building containing [point], or null when outdoors.
  static CampusBuilding? containing(NavLatLng point) {
    for (final b in all) {
      if (isPointInRing(point, b.outline)) return b;
    }
    return null;
  }

  /// Ray-casting point-in-ring test (lon = x, lat = y).
  /// Pure Dart so it stays unit-testable on the VM.
  static bool isPointInRing(NavLatLng point, List<NavLatLng> ring) {
    if (ring.length < 3) return false;
    var inside = false;
    var j = ring.length - 1;
    for (var i = 0; i < ring.length; j = i++) {
      final yi = ring[i].latitude;
      final xi = ring[i].longitude;
      final yj = ring[j].latitude;
      final xj = ring[j].longitude;
      if ((yi > point.latitude) != (yj > point.latitude)) {
        final xIntersect =
            (xj - xi) * (point.latitude - yi) / (yj - yi) + xi;
        if (point.longitude < xIntersect) inside = !inside;
      }
    }
    return inside;
  }
}

/// One campus gate: who may pass and how.
class CampusEntrance {
  const CampusEntrance({
    required this.id,
    required this.name,
    required this.location,
    required this.access,
  });

  /// Stable id, e.g. 'entrance_1'.
  final String id;

  /// Display name, e.g. 'Entrance 1'.
  final String name;

  /// Gate position (latitude, longitude) — exact supplied coordinates.
  final NavLatLng location;

  /// Who may use it and how (person / vehicle / exit-only ...).
  final String access;
}

class CampusEntrances {
  CampusEntrances._();

  /// Gate 1 — students only.
  static const CampusEntrance entrance1 = CampusEntrance(
    id: 'entrance_1',
    name: 'Gate 1',
    location: NavLatLng(8.06476, 123.75527),
    access: 'Students only (entrance and exit).',
  );

  /// Gate 2 — vehicle only.
  static const CampusEntrance entrance2 = CampusEntrance(
    id: 'entrance_2',
    name: 'Gate 2',
    location: NavLatLng(8.06525, 123.75586),
    access: 'Vehicles only.',
  );

  /// Gate 3 — vehicle exit; visitors, interns and faculty on foot;
  /// students may exit here too.
  static const CampusEntrance entrance3 = CampusEntrance(
    id: 'entrance_3',
    name: 'Gate 3',
    location: NavLatLng(8.06548, 123.75611),
    access:
        'Vehicle exit. Visitors, interns and faculty entrance on foot. '
        'Students may also exit here.',
  );

  /// Gate 4 — vehicle exit; people may enter or exit on foot too.
  static const CampusEntrance entrance4 = CampusEntrance(
    id: 'entrance_4',
    name: 'Gate 4',
    location: NavLatLng(8.06594, 123.75665),
    access: 'Vehicle exit. People may enter or exit on foot too.',
  );

  /// Gate 5 — open to everyone on foot, both directions.
  static const CampusEntrance entrance5 = CampusEntrance(
    id: 'entrance_5',
    name: 'Gate 5',
    location: NavLatLng(8.06346, 123.75602),
    access: 'Entrance and exit for everyone on foot.',
  );

  /// All known gates in numbered order.
  static const List<CampusEntrance> all = <CampusEntrance>[
    entrance1,
    entrance2,
    entrance3,
    entrance4,
    entrance5,
  ];

  /// Nearest entrance within [radiusMeters] of [point], or null.
  static CampusEntrance? nearestWithin(
    NavLatLng point, [
    double radiusMeters = CampusBuildings.entranceTapRadiusMeters,
  ]) {
    CampusEntrance? best;
    var bestDist = radiusMeters;
    for (final e in all) {
      final d = GeoMath.distanceMeters(point, e.location);
      if (d <= bestDist) {
        bestDist = d;
        best = e;
      }
    }
    return best;
  }
}
