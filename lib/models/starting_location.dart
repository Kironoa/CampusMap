// lib/models/starting_location.dart
import 'dart:convert';

import '../features/live_navigation/models/geo_math.dart';
import '../services/indoor_positioning/indoor_position.dart';

/// Structured payload encoded inside a Campus Guide starting-point QR code.
///
/// Example:
/// ```json
/// {
///   "type": "campus_guide_starting_point",
///   "building": "MAIN_BUILDING",
///   "floor": 0,
///   "location_id": "GF_MAIN_ENTRANCE"
/// }
/// ```
class CampusGuideQr {
  /// Marker that identifies a QR code as belonging to Campus Guide.
  static const String validType = 'campus_guide_starting_point';

  final String type;
  final String building;
  final int floor;
  final String locationId;

  const CampusGuideQr({
    required this.type,
    required this.building,
    required this.floor,
    required this.locationId,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'building': building,
    'floor': floor,
    'location_id': locationId,
  };

  String encode() => jsonEncode(toJson());

  /// Parses and validates a raw QR string. Returns null when the payload is
  /// not a well-formed Campus Guide starting-point QR code.
  static CampusGuideQr? tryParse(String raw) {
    final Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      json = decoded;
    } on FormatException {
      return null;
    }

    if (json['type'] != validType) return null;

    final building = json['building'];
    final locationId = json['location_id'];
    final floor = json['floor'];
    if (building is! String ||
        building.isEmpty ||
        locationId is! String ||
        locationId.isEmpty) {
      return null;
    }
    if (floor is! int) return null;

    return CampusGuideQr(
      type: validType,
      building: building,
      floor: floor,
      locationId: locationId,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CampusGuideQr &&
      other.type == type &&
      other.building == building &&
      other.floor == floor &&
      other.locationId == locationId;

  @override
  int get hashCode => Object.hash(type, building, floor, locationId);

  @override
  String toString() =>
      'CampusGuideQr(building: $building, floor: $floor, locationId: $locationId)';
}

/// A physical scanning point (entrance / staircase / door) with a fixed
/// position on the floor-plan coordinate system.
///
/// Coordinates are NORMALIZED 0.0..1.0 over the floor-plan image for [floor],
/// exactly like [NavigationGraph] nodes and [IndoorPosition]. The marker
/// drawn from these coordinates stays anchored to the physical spot under
/// zoom, pan, rotation and resolution changes.
class StartingLocation {
  final String id;
  final String name;
  final String building;

  /// Floor index (0 = Ground Floor).
  final int floor;

  /// Normalized x on the floor-plan image (0.0..1.0). CALIBRATE on site.
  final double x;

  /// Normalized y on the floor-plan image (0.0..1.0). CALIBRATE on site.
  final double y;

  /// Optional navigation-graph node this point is anchored to.
  final String? navNodeId;

  /// Outdoor GPS coordinate (latitude, longitude) for this starting point.
  /// Used when this location is scanned as a starting point for Live Navigation (outdoor).
  /// Should be the nearest campus entrance/gate or building outdoor coordinate.
  final NavLatLng? outdoorPosition;

  const StartingLocation({
    required this.id,
    required this.name,
    required this.building,
    required this.floor,
    required this.x,
    required this.y,
    this.navNodeId,
    this.outdoorPosition,
  });

  /// The exact data to encode in this location's QR code.
  String get qrData => CampusGuideQr(
    type: CampusGuideQr.validType,
    building: building,
    floor: floor,
    locationId: id,
  ).encode();

  /// Converts this location into an exact indoor position used as the
  /// route origin / map marker anchor.
  IndoorPosition toIndoorPosition({double accuracy = 0.5}) => IndoorPosition(
    x: IndoorPosition.clampCoordinate(x),
    y: IndoorPosition.clampCoordinate(y),
    floor: floor,
    accuracy: accuracy,
    timestamp: DateTime.now(),
    source: PositionSource.manual,
  );

  @override
  bool operator ==(Object other) =>
      other is StartingLocation &&
      other.id == id &&
      other.name == name &&
      other.building == building &&
      other.floor == floor &&
      other.x == x &&
      other.y == y &&
      other.outdoorPosition == outdoorPosition;

  @override
  int get hashCode => Object.hash(id, name, building, floor, x, y, outdoorPosition);

  @override
  String toString() =>
      'StartingLocation($id, "$name", floor $floor, x: $x, y: $y, outdoor: $outdoorPosition)';
}
