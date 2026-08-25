// lib/config/starting_locations.dart
import '../models/starting_location.dart';

/// Centralized configuration of all QR starting locations.
///
/// COORDINATE CALIBRATION
/// ──────────────────────
/// `x` / `y` are NORMALIZED coordinates (0.0..1.0) over the Ground Floor
/// plan image (`assets/images/ground_floor.png`, 1485x704 px). They share
/// the exact same coordinate system as [NavigationGraph] nodes and
/// [IndoorPosition], so the "You are here" marker is anchored to the same
/// physical spot regardless of zoom, pan, rotation or screen size.
///
/// The values below are seeded from the matching yellow entry nodes in
/// [NavigationGraph.groundNodes]. To calibrate: open
/// assets/images/ground_floor.png in any image editor, divide the target
/// pixel position by 1485 (x) and 704 (y), and update the values here.
/// Nothing else needs to change.
class StartingLocations {
  StartingLocations._();

  static const String mainBuilding = 'MAIN_BUILDING';

  /// Floor index of the Ground Floor.
  static const int groundFloor = 0;

  /// All Ground Floor QR starting locations.
  ///
  /// Each entry maps 1:1 to a unique QR code; never reuse qrData across
  /// locations.
  static const List<StartingLocation> groundFloorLocations = [
    StartingLocation(
      id: 'GF_MAIN_ENTRANCE',
      name: 'Main Entrance',
      building: mainBuilding,
      floor: groundFloor,
      x: 0.468, // CALIBRATE
      y: 0.950, // CALIBRATE
      navNodeId: 'gf_v_100',
    ),
    StartingLocation(
      id: 'GF_LOBBY_LEFT_STAIRCASE',
      name: 'Lobby Left Staircase',
      building: mainBuilding,
      floor: groundFloor,
      x: 0.435, // CALIBRATE
      y: 0.560, // CALIBRATE
      navNodeId: 'gf_start_lobby_left',
    ),
    StartingLocation(
      id: 'GF_LOBBY_RIGHT_STAIRCASE',
      name: 'Lobby Right Staircase',
      building: mainBuilding,
      floor: groundFloor,
      x: 0.565, // CALIBRATE
      y: 0.560, // CALIBRATE
      navNodeId: 'gf_start_lobby_right',
    ),
    StartingLocation(
      id: 'GF_LEFT_WING_STAIRCASE',
      name: 'Left Wing Staircase',
      building: mainBuilding,
      floor: groundFloor,
      x: 0.095, // CALIBRATE
      y: 0.130, // CALIBRATE
      navNodeId: 'gf_start_stairs_left_top',
    ),
    StartingLocation(
      id: 'GF_RIGHT_WING_STAIRCASE',
      name: 'Right Wing Staircase',
      building: mainBuilding,
      floor: groundFloor,
      x: 0.895, // CALIBRATE
      y: 0.075, // CALIBRATE
      navNodeId: 'gf_start_stairs_right_top',
    ),
    StartingLocation(
      id: 'GF_LEFT_SIDE_DOOR',
      name: 'Left Side Door',
      building: mainBuilding,
      floor: groundFloor,
      x: 0.065, // CALIBRATE
      y: 0.370, // CALIBRATE
      navNodeId: 'gf_start_left_mid',
    ),
    StartingLocation(
      id: 'GF_RIGHT_SIDE_DOOR',
      name: 'Right Side Door',
      building: mainBuilding,
      floor: groundFloor,
      x: 0.960, // CALIBRATE
      y: 0.370, // CALIBRATE
      navNodeId: 'gf_start_right_mid',
    ),
  ];

  /// Looks a starting location up by its unique location ID.
  static StartingLocation? byId(String locationId) {
    for (final location in groundFloorLocations) {
      if (location.id == locationId) return location;
    }
    return null;
  }

  /// Validates raw QR content and resolves it to a configured starting
  /// location. Returns null for invalid or unknown Campus Guide codes and
  /// for any unrelated QR payload; callers must NOT change the current
  /// position when null is returned.
  static StartingLocation? fromQrData(String raw) {
    final qr = CampusGuideQr.tryParse(raw);
    if (qr == null || qr.building != mainBuilding) return null;
    return byId(qr.locationId);
  }
}
