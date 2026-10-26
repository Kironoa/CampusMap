// lib/config/starting_locations.dart
import '../models/starting_location.dart';
import '../features/live_navigation/models/geo_math.dart';

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

  /// Floor index of the 2nd Floor.
  static const int secondFloor = 1;

  /// Floor index of the 3rd Floor.
  static const int thirdFloor = 2;

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
      outdoorPosition: NavLatLng(8.06548, 123.75611), // Gate 3
    ),
    StartingLocation(
      id: 'GF_LOBBY_LEFT_STAIRCASE',
      name: 'Lobby Left Staircase',
      building: mainBuilding,
      floor: groundFloor,
      x: 0.435, // CALIBRATE
      y: 0.560, // CALIBRATE
      navNodeId: 'gf_start_lobby_left',
      outdoorPosition: NavLatLng(8.06525, 123.75586), // Gate 2
    ),
    StartingLocation(
      id: 'GF_LOBBY_RIGHT_STAIRCASE',
      name: 'Lobby Right Staircase',
      building: mainBuilding,
      floor: groundFloor,
      x: 0.565, // CALIBRATE
      y: 0.560, // CALIBRATE
      navNodeId: 'gf_start_lobby_right',
      outdoorPosition: NavLatLng(8.06594, 123.75665), // Gate 4
    ),
    StartingLocation(
      id: 'GF_LEFT_WING_STAIRCASE',
      name: 'Left Wing Staircase',
      building: mainBuilding,
      floor: groundFloor,
      x: 0.095, // CALIBRATE
      y: 0.130, // CALIBRATE
      navNodeId: 'gf_start_stairs_left_top',
      outdoorPosition: NavLatLng(8.06476, 123.75527), // Gate 1
    ),
    StartingLocation(
      id: 'GF_RIGHT_WING_STAIRCASE',
      name: 'Right Wing Staircase',
      building: mainBuilding,
      floor: groundFloor,
      x: 0.895, // CALIBRATE
      y: 0.075, // CALIBRATE
      navNodeId: 'gf_start_stairs_right_top',
      outdoorPosition: NavLatLng(8.06594, 123.75665), // Gate 4
    ),
    StartingLocation(
      id: 'GF_LEFT_SIDE_DOOR',
      name: 'Left Side Door',
      building: mainBuilding,
      floor: groundFloor,
      x: 0.065, // CALIBRATE
      y: 0.370, // CALIBRATE
      navNodeId: 'gf_start_left_mid',
      outdoorPosition: NavLatLng(8.06476, 123.75527), // Gate 1
    ),
    StartingLocation(
      id: 'GF_RIGHT_SIDE_DOOR',
      name: 'Right Side Door',
      building: mainBuilding,
      floor: groundFloor,
      x: 0.960, // CALIBRATE
      y: 0.370, // CALIBRATE
      navNodeId: 'gf_start_right_mid',
      outdoorPosition: NavLatLng(8.06594, 123.75665), // Gate 4
    ),
  ];

  /// All 2nd Floor QR starting locations.
  ///
  /// Each entry maps 1:1 to a unique QR code; never reuse qrData across
  /// locations.
  static const List<StartingLocation> secondFloorLocations = [
    // QR START 1 — UPPER LEFT: SHS Lobby / upper-left entrance
    // Pixel: x=124, y=166 → Normalized: 0.08470, 0.23056
    // QR Payload: 2F_START_01
    StartingLocation(
      id: '2F_START_01',
      name: 'Upper Left / SHS Lobby',
      building: mainBuilding,
      floor: secondFloor,
      x: 0.08470,
      y: 0.23056,
      navNodeId: 'sf_start_qr_01',
      outdoorPosition: NavLatLng(8.06476, 123.75527), // Gate 1
    ),

    // QR START 2 — UPPER RIGHT: Sub-Lobby / upper-right entrance
    // Pixel: x=1349, y=166 → Normalized: 0.92145, 0.23056
    // QR Payload: 2F_START_02
    StartingLocation(
      id: '2F_START_02',
      name: 'Upper Right / Sub-Lobby',
      building: mainBuilding,
      floor: secondFloor,
      x: 0.92145,
      y: 0.23056,
      navNodeId: 'sf_start_qr_02',
      outdoorPosition: NavLatLng(8.06594, 123.75665), // Gate 4
    ),

    // QR START 3 — LOWER LEFT: Lower-left staircase entrance
    // Pixel: x=111, y=285 → Normalized: 0.07582, 0.39583
    // QR Payload: 2F_START_03
    StartingLocation(
      id: '2F_START_03',
      name: 'Lower Left Staircase',
      building: mainBuilding,
      floor: secondFloor,
      x: 0.07582,
      y: 0.39583,
      navNodeId: 'sf_start_qr_03',
      outdoorPosition: NavLatLng(8.06476, 123.75527), // Gate 1
    ),

    // QR START 4 — LOWER RIGHT: Lower-right staircase entrance
    // Pixel: x=1360, y=284 → Normalized: 0.92896, 0.39444
    // QR Payload: 2F_START_04
    StartingLocation(
      id: '2F_START_04',
      name: 'Lower Right Staircase',
      building: mainBuilding,
      floor: secondFloor,
      x: 0.92896,
      y: 0.39444,
      navNodeId: 'sf_start_qr_04',
      outdoorPosition: NavLatLng(8.06594, 123.75665), // Gate 4
    ),

    // QR START 5 — CENTER: Central staircase / central lower entrance
    // Pixel: x=718, y=375 → Normalized: 0.49029, 0.52083
    // QR Payload: 2F_START_05
    StartingLocation(
      id: '2F_START_05',
      name: 'Central Staircase',
      building: mainBuilding,
      floor: secondFloor,
      x: 0.49029,
      y: 0.52083,
      navNodeId: 'sf_start_qr_05',
      outdoorPosition: NavLatLng(8.06548, 123.75611), // Gate 3
    ),

    // LEGACY STARTING POINTS (kept for floor transitions compatibility)
    StartingLocation(
      id: 'SF_LEFT_STAIRCASE',
      name: 'Left Staircase (Legacy)',
      building: mainBuilding,
      floor: secondFloor,
      x: 0.065,
      y: 0.500,
      navNodeId: 'sf_start_left_mid',
      outdoorPosition: NavLatLng(8.06476, 123.75527), // Gate 1
    ),
    StartingLocation(
      id: 'SF_RIGHT_STAIRCASE',
      name: 'Right Staircase (Legacy)',
      building: mainBuilding,
      floor: secondFloor,
      x: 0.960,
      y: 0.500,
      navNodeId: 'sf_start_right_mid',
      outdoorPosition: NavLatLng(8.06594, 123.75665), // Gate 4
    ),
    StartingLocation(
      id: 'SF_CENTER_STAIRCASE',
      name: 'Center Staircase (Legacy)',
      building: mainBuilding,
      floor: secondFloor,
      x: 0.468,
      y: 0.415,
      navNodeId: 'sf_start_center',
      outdoorPosition: NavLatLng(8.06548, 123.75611), // Gate 3
    ),
    StartingLocation(
      id: 'SF_BOTTOM_LEFT_STAIRCASE',
      name: 'Bottom Left Staircase (Legacy)',
      building: mainBuilding,
      floor: secondFloor,
      x: 0.435,
      y: 0.760,
      navNodeId: 'sf_start_bot_left',
      outdoorPosition: NavLatLng(8.06525, 123.75586), // Gate 2
    ),
    StartingLocation(
      id: 'SF_BOTTOM_RIGHT_STAIRCASE',
      name: 'Bottom Right Staircase (Legacy)',
      building: mainBuilding,
      floor: secondFloor,
      x: 0.595,
      y: 0.760,
      navNodeId: 'sf_start_bot_right',
      outdoorPosition: NavLatLng(8.06594, 123.75665), // Gate 4
    ),
  ];

  /// All 3rd Floor QR starting locations.
  ///
  /// Each entry maps 1:1 to a unique QR code; never reuse qrData across
  /// locations.
  static const List<StartingLocation> thirdFloorLocations = [
    StartingLocation(
      id: 'TF_LEFT_STAIRCASE',
      name: 'Left Staircase',
      building: mainBuilding,
      floor: thirdFloor,
      x: 0.065, // CALIBRATE
      y: 0.420, // CALIBRATE
      navNodeId: 'tf_start_left',
      outdoorPosition: NavLatLng(8.06476, 123.75527), // Gate 1
    ),
    StartingLocation(
      id: 'TF_ELEVATOR',
      name: 'Elevator',
      building: mainBuilding,
      floor: thirdFloor,
      x: 0.490, // CALIBRATE
      y: 0.300, // CALIBRATE
      navNodeId: 'tf_start_elevator',
      outdoorPosition: NavLatLng(8.06548, 123.75611), // Gate 3
    ),
    StartingLocation(
      id: 'TF_RIGHT_STAIRCASE',
      name: 'Right Staircase',
      building: mainBuilding,
      floor: thirdFloor,
      x: 0.960, // CALIBRATE
      y: 0.420, // CALIBRATE
      navNodeId: 'tf_start_right',
      outdoorPosition: NavLatLng(8.06594, 123.75665), // Gate 4
    ),
    StartingLocation(
      id: 'TF_TOP_LEFT_STAIRCASE',
      name: 'Top Left Staircase',
      building: mainBuilding,
      floor: thirdFloor,
      x: 0.380, // CALIBRATE
      y: 0.080, // CALIBRATE
      navNodeId: 'tf_start_top_left',
      outdoorPosition: NavLatLng(8.06476, 123.75527), // Gate 1
    ),
  ];

  /// Looks a starting location up by its unique location ID across all floors.
  static StartingLocation? byId(String locationId) {
    for (final location in groundFloorLocations) {
      if (location.id == locationId) return location;
    }
    for (final location in secondFloorLocations) {
      if (location.id == locationId) return location;
    }
    for (final location in thirdFloorLocations) {
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
