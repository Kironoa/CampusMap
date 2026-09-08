// lib/services/navigation_graph.dart
import 'dart:ui';

class NavNode {
  final String id;
  final Offset pos;
  const NavNode(this.id, this.pos);
}

class NavEdge {
  final String from;
  final String to;
  const NavEdge(this.from, this.to);
}

/// A connection between two floors (stairs / elevator).
///
/// PLACEHOLDER DATA — the node pairs below were derived from the existing
/// "starting point" nodes of each floor and MUST be verified against the
/// real building (which staircase connects to which landing). Adjust
/// `fromNode`/`toNode` after a physical survey.
class FloorTransition {
  final int fromFloor;
  final String fromNode;
  final int toFloor;
  final String toNode;

  const FloorTransition({
    required this.fromFloor,
    required this.fromNode,
    required this.toFloor,
    required this.toNode,
  });
}

class NavigationGraph {
  /// Global debug flag for navigation graph visualization.
  /// Set to true to enable debug rendering of nodes, edges, and room destinations.
  static bool showNavigationDebug = false;

  /// Cross-floor transitions (stairs) used by multi-floor routing.
  ///
  /// PLACEHOLDER — verify each staircase connection on site before
  /// relying on cross-floor routes.
  static const List<FloorTransition> floorTransitions = [
    // Ground → 2nd floor
    FloorTransition(
      fromFloor: 0,
      fromNode: 'gf_start_stairs_left_top',
      toFloor: 1,
      toNode: 'sf_start_left_mid',
    ),
    FloorTransition(
      fromFloor: 0,
      fromNode: 'gf_start_stairs_right_top',
      toFloor: 1,
      toNode: 'sf_start_right_mid',
    ),
    FloorTransition(
      fromFloor: 0,
      fromNode: 'gf_start_lobby_left',
      toFloor: 1,
      toNode: 'sf_start_bot_left',
    ),
    FloorTransition(
      fromFloor: 0,
      fromNode: 'gf_start_lobby_right',
      toFloor: 1,
      toNode: 'sf_start_bot_right',
    ),
    // 2nd → 3rd floor
    FloorTransition(
      fromFloor: 1,
      fromNode: 'sf_start_left_mid',
      toFloor: 2,
      toNode: 'tf_start_left',
    ),
    FloorTransition(
      fromFloor: 1,
      fromNode: 'sf_start_right_mid',
      toFloor: 2,
      toNode: 'tf_start_right',
    ),
    FloorTransition(
      fromFloor: 1,
      fromNode: 'sf_start_center',
      toFloor: 2,
      toNode: 'tf_start_top_left',
    ),
  ];

  // ════════════════════════════════════════════════════
  //  GROUND FLOOR
  // ════════════════════════════════════════════════════
  static const List<NavNode> groundNodes = [
    // Ground-floor destination coordinates are normalized from the supplied
    // 1485 x 704 floor-plan image. Room endpoints are placed at the geometric
    // center of each visible room/area, not at the doorway.

    // ── Entry / Starting points (yellow) ──
    NavNode('gf_start_stairs_left_top', Offset(0.095, 0.130)),
    NavNode('gf_start_stairs_right_top', Offset(0.895, 0.075)),
    NavNode('gf_start_left_mid', Offset(0.065, 0.370)),
    NavNode('gf_start_right_mid', Offset(0.960, 0.370)),
    NavNode('gf_start_lobby_left', Offset(0.435, 0.560)),
    NavNode('gf_start_lobby_center', Offset(0.468, 0.560)),
    NavNode('gf_start_lobby_right', Offset(0.565, 0.560)),

    // ── Horizontal corridor nodes (y≈0.305) ──
    NavNode('gf_h_000', Offset(0.030, 0.305)),
    NavNode('gf_h_010', Offset(0.065, 0.305)),
    NavNode('gf_h_020', Offset(0.095, 0.305)),
    NavNode('gf_h_030', Offset(0.130, 0.305)),
    NavNode('gf_h_040', Offset(0.180, 0.305)),
    NavNode('gf_h_050', Offset(0.230, 0.305)),
    NavNode('gf_h_060', Offset(0.280, 0.305)),
    NavNode('gf_h_070', Offset(0.325, 0.305)),
    NavNode('gf_h_080', Offset(0.375, 0.305)),
    NavNode('gf_h_090', Offset(0.420, 0.305)),
    NavNode('gf_h_100', Offset(0.468, 0.305)),
    NavNode('gf_h_110', Offset(0.510, 0.305)),
    NavNode('gf_h_120', Offset(0.560, 0.305)),
    NavNode('gf_h_130', Offset(0.610, 0.305)),
    NavNode('gf_h_140', Offset(0.655, 0.305)),
    NavNode('gf_h_150', Offset(0.700, 0.305)),
    NavNode('gf_h_160', Offset(0.750, 0.305)),
    NavNode('gf_h_170', Offset(0.800, 0.305)),
    NavNode('gf_h_180', Offset(0.845, 0.305)),
    NavNode('gf_h_190', Offset(0.895, 0.305)),
    NavNode('gf_h_200', Offset(0.940, 0.305)),
    NavNode('gf_h_210', Offset(0.980, 0.305)),

    // ── Vertical spine (x≈0.468, going down from corridor to driveway) ──
    NavNode('gf_v_000', Offset(0.468, 0.305)),
    NavNode('gf_v_010', Offset(0.468, 0.370)),
    NavNode('gf_v_020', Offset(0.468, 0.430)),
    NavNode('gf_v_030', Offset(0.468, 0.480)),
    NavNode('gf_v_040', Offset(0.468, 0.530)),
    NavNode('gf_v_main_lobby_entrance', Offset(0.468, 0.560)),
    NavNode('gf_v_050', Offset(0.468, 0.580)),
    NavNode('gf_v_060', Offset(0.468, 0.640)),
    NavNode('gf_v_070', Offset(0.468, 0.720)),
    NavNode('gf_v_080', Offset(0.468, 0.800)),
    NavNode('gf_v_090', Offset(0.468, 0.870)),
    NavNode('gf_v_100', Offset(0.503704, 0.910511)),

    // ── Entry connections from yellow starts into corridor ──
    NavNode('gf_conn_stairs_lt', Offset(0.095, 0.305)),
    NavNode('gf_conn_stairs_rt', Offset(0.895, 0.305)),

    // ── Room stub nodes (accessible directly from corridor) ──
    NavNode('gf_room_ics', Offset(0.079798, 0.200994)),
    NavNode('gf_room_training', Offset(0.129293, 0.200994)),
    NavNode('gf_room_ihs', Offset(0.178451, 0.200994)),
    NavNode('gf_room_ibfs', Offset(0.226936, 0.200994)),
    NavNode('gf_room_ite', Offset(0.275758, 0.200994)),
    NavNode('gf_room_restroom_tc', Offset(0.373064, 0.200994)),
    NavNode('gf_room_ias', Offset(0.424916, 0.200994)),
    NavNode('gf_room_medical', Offset(0.577104, 0.200994)),
    NavNode('gf_room_restroom_tr', Offset(0.629630, 0.200994)),
    NavNode('gf_room_mb105', Offset(0.678788, 0.200994)),
    NavNode('gf_room_mb103', Offset(0.727609, 0.200994)),
    NavNode('gf_room_mpr', Offset(0.777104, 0.200994)),
    NavNode('gf_room_midwifery', Offset(0.850842, 0.200994)),
    NavNode('gf_room_pfom', Offset(0.923569, 0.200994)),
    NavNode('gf_room_toilet_left', Offset(0.030640, 0.062500)),
    NavNode('gf_room_toilet_right', Offset(0.971044, 0.062500)),
    NavNode('gf_room_cr_l1', Offset(0.165320, 0.062500)),
    NavNode('gf_room_cr_l2', Offset(0.189899, 0.062500)),
    NavNode('gf_room_cr_r1', Offset(0.813805, 0.062500)),
    NavNode('gf_room_cr_r2', Offset(0.838384, 0.062500)),
    // Bottom row (y≈0.420, accessed by stepping off corridor downward)
    NavNode('gf_room_sldo', Offset(0.031313, 0.419034)),
    NavNode('gf_room_icje', Offset(0.129630, 0.419034)),
    NavNode('gf_room_crim_lab', Offset(0.203030, 0.419034)),
    NavNode('gf_room_vp_admin', Offset(0.300673, 0.419034)),
    NavNode('gf_room_registrar', Offset(0.373401, 0.419034)),
    NavNode('gf_room_record', Offset(0.425589, 0.419034)),
    NavNode('gf_room_ciso', Offset(0.578114, 0.419034)),
    NavNode('gf_room_avr', Offset(0.667003, 0.419034)),
    NavNode('gf_room_dressing', Offset(0.740404, 0.419034)),
    NavNode('gf_room_music', Offset(0.777441, 0.419034)),
    NavNode('gf_room_dance', Offset(0.851178, 0.419034)),
    NavNode('gf_room_barracks', Offset(0.972391, 0.419034)),
    NavNode('gf_room_elevator', Offset(0.502020, 0.419034)),
    // Lobby section (accessed via vertical spine)
    NavNode('gf_room_scholarship', Offset(0.420202, 0.591619)),
    NavNode('gf_room_ojt', Offset(0.420202, 0.700284)),
    NavNode('gf_room_accreditation', Offset(0.584848, 0.647017)),
    NavNode('gf_room_main_lobby', Offset(0.502357, 0.688210)),
  ];

  static const List<NavEdge> groundEdges = [
    // ── Horizontal corridor ──
    NavEdge('gf_h_000', 'gf_h_010'), NavEdge('gf_h_010', 'gf_h_020'),
    NavEdge('gf_h_020', 'gf_h_030'), NavEdge('gf_h_030', 'gf_h_040'),
    NavEdge('gf_h_040', 'gf_h_050'), NavEdge('gf_h_050', 'gf_h_060'),
    NavEdge('gf_h_060', 'gf_h_070'), NavEdge('gf_h_070', 'gf_h_080'),
    NavEdge('gf_h_080', 'gf_h_090'), NavEdge('gf_h_090', 'gf_h_100'),
    NavEdge('gf_h_100', 'gf_h_110'), NavEdge('gf_h_110', 'gf_h_120'),
    NavEdge('gf_h_120', 'gf_h_130'), NavEdge('gf_h_130', 'gf_h_140'),
    NavEdge('gf_h_140', 'gf_h_150'), NavEdge('gf_h_150', 'gf_h_160'),
    NavEdge('gf_h_160', 'gf_h_170'), NavEdge('gf_h_170', 'gf_h_180'),
    NavEdge('gf_h_180', 'gf_h_190'), NavEdge('gf_h_190', 'gf_h_200'),
    NavEdge('gf_h_200', 'gf_h_210'),
    // ── Entry yellow nodes connect to nearest corridor node ──
    NavEdge('gf_start_stairs_left_top', 'gf_conn_stairs_lt'),
    NavEdge('gf_conn_stairs_lt', 'gf_h_020'),
    NavEdge('gf_start_stairs_right_top', 'gf_conn_stairs_rt'),
    NavEdge('gf_conn_stairs_rt', 'gf_h_190'),
    NavEdge('gf_start_left_mid', 'gf_h_010'),
    NavEdge('gf_start_right_mid', 'gf_h_210'),
    NavEdge('gf_start_lobby_left', 'gf_v_040'),
    NavEdge('gf_start_lobby_center', 'gf_v_050'),
    NavEdge('gf_start_lobby_right', 'gf_v_040'),
    // ── Vertical spine (gf_h_100 == gf_v_000, share position) ──
    NavEdge('gf_h_100', 'gf_v_010'),
    NavEdge('gf_v_010', 'gf_v_020'), NavEdge('gf_v_020', 'gf_v_030'),
    NavEdge('gf_v_030', 'gf_v_040'),
    NavEdge('gf_v_040', 'gf_v_main_lobby_entrance'),
    NavEdge('gf_v_main_lobby_entrance', 'gf_v_050'),
    NavEdge('gf_v_050', 'gf_v_060'),
    NavEdge('gf_v_060', 'gf_v_070'),
    NavEdge('gf_v_070', 'gf_v_080'), NavEdge('gf_v_080', 'gf_v_090'),
    NavEdge('gf_v_090', 'gf_v_100'),
    // ── Top-row room stubs (off horizontal corridor going up) ──
    NavEdge('gf_h_030', 'gf_room_ics'),
    NavEdge('gf_h_040', 'gf_room_training'),
    NavEdge('gf_h_050', 'gf_room_ihs'),
    NavEdge('gf_h_060', 'gf_room_ibfs'),
    NavEdge('gf_h_080', 'gf_room_ite'),
    NavEdge('gf_h_100', 'gf_room_restroom_tc'),
    NavEdge('gf_h_090', 'gf_room_ias'),
    NavEdge('gf_h_130', 'gf_room_medical'),
    NavEdge('gf_h_190', 'gf_room_restroom_tr'),
    NavEdge('gf_h_150', 'gf_room_mb105'),
    NavEdge('gf_h_160', 'gf_room_mb103'),
    NavEdge('gf_h_170', 'gf_room_mpr'),
    NavEdge('gf_h_180', 'gf_room_midwifery'),
    NavEdge('gf_h_210', 'gf_room_pfom'),
    NavEdge('gf_h_000', 'gf_room_toilet_left'),
    NavEdge('gf_h_200', 'gf_room_toilet_right'),
    NavEdge('gf_h_040', 'gf_room_cr_l1'),
    NavEdge('gf_h_040', 'gf_room_cr_l2'),
    NavEdge('gf_h_190', 'gf_room_cr_r1'),
    NavEdge('gf_h_190', 'gf_room_cr_r2'),
    // ── Bottom-row room stubs (off horizontal corridor going down) ──
    NavEdge('gf_h_000', 'gf_room_sldo'),
    NavEdge('gf_h_020', 'gf_room_icje'),
    NavEdge('gf_h_040', 'gf_room_crim_lab'),
    NavEdge('gf_h_060', 'gf_room_vp_admin'),
    NavEdge('gf_h_080', 'gf_room_registrar'),
    NavEdge('gf_h_090', 'gf_room_record'),
    NavEdge('gf_h_110', 'gf_room_ciso'),
    NavEdge('gf_h_130', 'gf_room_avr'),
    NavEdge('gf_h_150', 'gf_room_dressing'),
    NavEdge('gf_h_160', 'gf_room_music'),
    NavEdge('gf_h_180', 'gf_room_dance'),
    NavEdge('gf_h_210', 'gf_room_barracks'),
    NavEdge('gf_v_010', 'gf_room_elevator'),
    // ── Lobby room stubs (off vertical spine) ──
    NavEdge('gf_v_030', 'gf_room_scholarship'),
    NavEdge('gf_v_040', 'gf_room_ojt'),
    NavEdge('gf_v_030', 'gf_room_accreditation'),
    NavEdge('gf_v_main_lobby_entrance', 'gf_room_main_lobby'),
  ];

  // ════════════════════════════════════════════════════
  //  2ND FLOOR
  // ════════════════════════════════════════════════════
  static const List<NavNode> secondNodes = [
    // =========================================================
    // QR STARTING POINTS (User current location from QR scan)
    // =========================================================
    // START 1 — UPPER LEFT: SHS Lobby / upper-left entrance
    // Pixel: x=124, y=166 → Normalized: 124/1464=0.08470, 166/720=0.23056
    NavNode('sf_start_qr_01', Offset(0.08470, 0.23056)),

    // START 2 — UPPER RIGHT: Sub-Lobby / upper-right entrance
    // Pixel: x=1349, y=166 → Normalized: 1349/1464=0.92145, 166/720=0.23056
    NavNode('sf_start_qr_02', Offset(0.92145, 0.23056)),

    // START 3 — LOWER LEFT: Lower-left staircase entrance
    // Pixel: x=111, y=285 → Normalized: 111/1464=0.07582, 285/720=0.39583
    NavNode('sf_start_qr_03', Offset(0.07582, 0.39583)),

    // START 4 — LOWER RIGHT: Lower-right staircase entrance
    // Pixel: x=1360, y=284 → Normalized: 1360/1464=0.92896, 284/720=0.39444
    NavNode('sf_start_qr_04', Offset(0.92896, 0.39444)),

    // START 5 — CENTER: Central staircase / central lower entrance
    // Pixel: x=718, y=375 → Normalized: 718/1464=0.49029, 375/720=0.52083
    NavNode('sf_start_qr_05', Offset(0.49029, 0.52083)),

    // =========================================================
    // LEGACY STARTING / STAIR POINTS (kept for floor transitions)
    // =========================================================
    NavNode('sf_start_left_mid', Offset(0.0745, 0.3542)),

    NavNode('sf_start_right_mid', Offset(0.9324, 0.3542)),

    NavNode('sf_start_center', Offset(0.5000, 0.3542)),

    NavNode('sf_start_bot_left', Offset(0.4201, 0.7986)),

    NavNode('sf_start_bot_right', Offset(0.5874, 0.7986)),

    // =========================================================
    // MAIN HORIZONTAL CORRIDOR
    // Actual corridor centerline is approximately y = 255 px.
    // Normalized y = 255 / 720 = 0.3542
    // =========================================================
    NavNode('sf_h_000', Offset(0.020, 0.3542)),
    NavNode('sf_h_010', Offset(0.059, 0.3542)),
    NavNode('sf_h_020', Offset(0.089, 0.3542)),
    NavNode('sf_h_030', Offset(0.107, 0.3542)),
    NavNode('sf_h_040', Offset(0.203, 0.3542)),
    NavNode('sf_h_050', Offset(0.253, 0.3542)),
    NavNode('sf_h_060', Offset(0.303, 0.3542)),
    NavNode('sf_h_070', Offset(0.351, 0.3542)),
    NavNode('sf_h_080', Offset(0.395, 0.3542)),
    NavNode('sf_h_090', Offset(0.457, 0.3542)),
    NavNode('sf_h_100', Offset(0.549, 0.3542)),
    NavNode('sf_h_110', Offset(0.625, 0.3542)),
    NavNode('sf_h_120', Offset(0.659, 0.3542)),
    NavNode('sf_h_130', Offset(0.665, 0.3542)),
    NavNode('sf_h_140', Offset(0.749, 0.3542)),
    NavNode('sf_h_150', Offset(0.805, 0.3542)),
    NavNode('sf_h_160', Offset(0.848, 0.3542)),
    NavNode('sf_h_170', Offset(0.900, 0.3542)),
    NavNode('sf_h_180', Offset(0.929, 0.3542)),
    NavNode('sf_h_190', Offset(0.980, 0.3542)),

    // =========================================================
    // CENTRAL LOWER CORRIDOR
    // =========================================================
    NavNode('sf_cv_000', Offset(0.500, 0.3542)),
    NavNode('sf_cv_010', Offset(0.500, 0.430)),
    NavNode('sf_cv_020', Offset(0.500, 0.500)),
    NavNode('sf_cv_030', Offset(0.500, 0.570)),
    NavNode('sf_cv_040', Offset(0.500, 0.640)),
    NavNode('sf_cv_050', Offset(0.500, 0.710)),
    NavNode('sf_cv_060', Offset(0.500, 0.780)),
    NavNode('sf_cv_070', Offset(0.500, 0.800)),

    // =========================================================
    // CENTRAL STAIRCASE / ACCESS
    // =========================================================
    NavNode('sf_center_left_entrance', Offset(0.4645, 0.3542)),

    NavNode('sf_center_left_010', Offset(0.4645, 0.420)),

    NavNode('sf_center_left_020', Offset(0.4645, 0.500)),

    NavNode('sf_center_right_entrance', Offset(0.5485, 0.3542)),

    NavNode('sf_center_right_010', Offset(0.5485, 0.420)),

    NavNode('sf_center_right_020', Offset(0.5485, 0.500)),

    // =========================================================
    // TOP-ROW ROOMS
    // Destination nodes are placed at the geometric center of each
    // visible room/area. Path edges may cross the room interior; the
    // destination endpoint is intentionally NOT placed at the doorway.
    // =========================================================
    NavNode('sf_room_guidance_test', Offset(0.033811, 0.261111)),

    NavNode('sf_room_sub_lobby', Offset(0.082992, 0.261111)),

    NavNode('sf_room_comp_lab', Offset(0.153347, 0.261111)),

    NavNode('sf_room_comp_room1', Offset(0.225751, 0.261111)),

    NavNode('sf_room_comp_room2', Offset(0.274249, 0.261111)),

    NavNode('sf_room_comp_room3', Offset(0.322746, 0.261111)),

    NavNode('sf_room_restroom_l1', Offset(0.359290, 0.261111)),

    NavNode('sf_room_restroom_l2', Offset(0.383538, 0.261111)),

    NavNode('sf_room_vip_lounge', Offset(0.526639, 0.261111)),

    NavNode('sf_room_restroom_r1', Offset(0.614413, 0.261111)),

    NavNode('sf_room_restroom_r2', Offset(0.639003, 0.261111)),

    NavNode('sf_room_faculty_lounge', Offset(0.699795, 0.261111)),

    NavNode('sf_room_speech_lab', Offset(0.821721, 0.261111)),

    NavNode('sf_room_bseed_top', Offset(0.967213, 0.261111)),

    // =========================================================
    // MAIN STAGE
    // =========================================================
    NavNode('sf_room_main_stage', Offset(0.498975, 0.127778)),

    // =========================================================
    // BLEACHERS
    // =========================================================
    NavNode('sf_room_bleacher_left', Offset(0.250683, 0.127778)),

    NavNode('sf_room_bleacher_right', Offset(0.748634, 0.127778)),

    // =========================================================
    // BOTTOM-ROW ROOMS
    // =========================================================
    NavNode('sf_room_guidance_counsel', Offset(0.033811, 0.448611)),

    NavNode('sf_room_moot_court', Offset(0.081626, 0.448611)),

    NavNode('sf_room_business', Offset(0.153347, 0.448611)),

    NavNode('sf_room_classroom_l', Offset(0.250000, 0.448611)),

    NavNode('sf_room_classroom_c', Offset(0.322746, 0.448611)),

    NavNode('sf_room_classroom_r', Offset(0.371243, 0.448611)),

    NavNode('sf_room_board', Offset(0.574795, 0.448611)),

    NavNode('sf_room_hrmo', Offset(0.626708, 0.448611)),

    NavNode('sf_room_faculty', Offset(0.699795, 0.448611)),

    NavNode('sf_room_supply', Offset(0.772883, 0.448611)),

    NavNode('sf_room_vp_planning', Offset(0.821721, 0.448611)),

    NavNode('sf_room_evp', Offset(0.870560, 0.448611)),

    NavNode('sf_room_bseed_bot', Offset(0.967213, 0.448611)),

    // =========================================================
    // LOWER CENTRAL OFFICES
    // =========================================================
    NavNode('sf_room_deans', Offset(0.423156, 0.582639)),

    NavNode('sf_room_vpaa', Offset(0.423156, 0.705556)),

    NavNode('sf_room_president', Offset(0.574795, 0.645139)),

    // =========================================================
    // DECK CANOPY
    // =========================================================
    NavNode('sf_room_deck_canopy', Offset(0.498975, 0.918750)),
  ];

  static const List<NavEdge> secondEdges = [
    // =========================================================
    // QR STARTING POINT CONNECTIONS
    // =========================================================
    // START 1 — UPPER LEFT (SHS Lobby) → connects to main corridor near left end
    NavEdge('sf_start_qr_01', 'sf_h_010'),

    // START 2 — UPPER RIGHT (Sub-Lobby) → connects to main corridor near right end
    NavEdge('sf_start_qr_02', 'sf_h_180'),

    // START 3 — LOWER LEFT (Lower-left staircase) → connects to lower corridor area
    NavEdge('sf_start_qr_03', 'sf_h_010'),

    // START 4 — LOWER RIGHT (Lower-right staircase) → connects to lower corridor area
    NavEdge('sf_start_qr_04', 'sf_h_180'),

    // START 5 — CENTER (Central staircase) → connects to central lower corridor
    NavEdge('sf_start_qr_05', 'sf_cv_030'),

    // =========================================================
    // MAIN HORIZONTAL CORRIDOR
    // =========================================================
    NavEdge('sf_h_000', 'sf_h_010'),
    NavEdge('sf_h_010', 'sf_h_020'),
    NavEdge('sf_h_020', 'sf_h_030'),
    NavEdge('sf_h_030', 'sf_h_040'),
    NavEdge('sf_h_040', 'sf_h_050'),
    NavEdge('sf_h_050', 'sf_h_060'),
    NavEdge('sf_h_060', 'sf_h_070'),
    NavEdge('sf_h_070', 'sf_h_080'),
    NavEdge('sf_h_080', 'sf_h_090'),
    NavEdge('sf_h_090', 'sf_h_100'),
    NavEdge('sf_h_100', 'sf_h_110'),
    NavEdge('sf_h_110', 'sf_h_120'),
    NavEdge('sf_h_120', 'sf_h_130'),
    NavEdge('sf_h_130', 'sf_h_140'),
    NavEdge('sf_h_140', 'sf_h_150'),
    NavEdge('sf_h_150', 'sf_h_160'),
    NavEdge('sf_h_160', 'sf_h_170'),
    NavEdge('sf_h_170', 'sf_h_180'),
    NavEdge('sf_h_180', 'sf_h_190'),

    // =========================================================
    // LEFT STAIRCASE
    // =========================================================
    NavEdge('sf_start_left_mid', 'sf_h_010'),

    // =========================================================
    // RIGHT STAIRCASE
    // =========================================================
    NavEdge('sf_start_right_mid', 'sf_h_180'),

    // =========================================================
    // CENTRAL STAIRCASE
    // =========================================================
    NavEdge('sf_start_center', 'sf_center_left_entrance'),

    NavEdge('sf_center_left_entrance', 'sf_center_left_010'),

    NavEdge('sf_center_left_010', 'sf_center_left_020'),

    NavEdge('sf_center_left_020', 'sf_cv_030'),

    // =========================================================
    // CENTRAL LOWER CORRIDOR
    // =========================================================
    NavEdge('sf_cv_000', 'sf_cv_010'),
    NavEdge('sf_cv_010', 'sf_cv_020'),
    NavEdge('sf_cv_020', 'sf_cv_030'),
    NavEdge('sf_cv_030', 'sf_cv_040'),
    NavEdge('sf_cv_040', 'sf_cv_050'),
    NavEdge('sf_cv_050', 'sf_cv_060'),
    NavEdge('sf_cv_060', 'sf_cv_070'),

    // =========================================================
    // LOWER STAIR CONNECTIONS
    // =========================================================
    NavEdge('sf_cv_060', 'sf_start_bot_left'),

    NavEdge('sf_cv_060', 'sf_start_bot_right'),

    // =========================================================
    // TOP-ROW ROOMS
    // =========================================================
    NavEdge('sf_h_010', 'sf_room_guidance_test'),
    NavEdge('sf_h_020', 'sf_room_sub_lobby'),

    NavEdge('sf_h_030', 'sf_room_comp_lab'),
    NavEdge('sf_h_040', 'sf_room_comp_room1'),
    NavEdge('sf_h_050', 'sf_room_comp_room2'),
    NavEdge('sf_h_060', 'sf_room_comp_room3'),

    NavEdge('sf_h_070', 'sf_room_restroom_l1'),
    NavEdge('sf_h_080', 'sf_room_restroom_l2'),

    // VIP Lounge
    NavEdge('sf_h_090', 'sf_room_vip_lounge'),
    NavEdge('sf_h_100', 'sf_room_vip_lounge'),

    NavEdge('sf_h_110', 'sf_room_restroom_r1'),
    NavEdge('sf_h_120', 'sf_room_restroom_r2'),

    NavEdge('sf_h_130', 'sf_room_faculty_lounge'),

    NavEdge('sf_h_150', 'sf_room_speech_lab'),

    NavEdge('sf_h_180', 'sf_room_bseed_top'),

    // =========================================================
    // VIP LOUNGE → MAIN STAGE
    // =========================================================
    NavEdge('sf_room_vip_lounge', 'sf_room_main_stage'),

    // =========================================================
    // BLEACHERS
    // =========================================================
    NavEdge('sf_h_040', 'sf_room_bleacher_left'),

    NavEdge('sf_h_140', 'sf_room_bleacher_right'),

    // =========================================================
    // BOTTOM-ROW ROOMS
    // =========================================================
    NavEdge('sf_h_010', 'sf_room_guidance_counsel'),
    NavEdge('sf_h_030', 'sf_room_moot_court'),
    NavEdge('sf_h_040', 'sf_room_business'),

    NavEdge('sf_h_060', 'sf_room_classroom_l'),
    NavEdge('sf_h_070', 'sf_room_classroom_c'),
    NavEdge('sf_h_080', 'sf_room_classroom_r'),

    NavEdge('sf_h_100', 'sf_room_board'),
    NavEdge('sf_h_120', 'sf_room_hrmo'),
    NavEdge('sf_h_140', 'sf_room_faculty'),
    NavEdge('sf_h_150', 'sf_room_supply'),
    NavEdge('sf_h_160', 'sf_room_vp_planning'),
    NavEdge('sf_h_170', 'sf_room_evp'),
    NavEdge('sf_h_180', 'sf_room_bseed_bot'),

    // =========================================================
    // LOWER OFFICES
    // =========================================================
    NavEdge('sf_cv_030', 'sf_room_deans'),

    NavEdge('sf_cv_040', 'sf_room_vpaa'),

    NavEdge('sf_cv_030', 'sf_room_president'),

    // =========================================================
    // DECK CANOPY
    // =========================================================
    NavEdge('sf_cv_070', 'sf_room_deck_canopy'),
  ];

  // ═══════════���═���══════════════════════════════════════
  //  3RD FLOOR
  // ════════════════════════════════════════════════════
  static const List<NavNode> thirdNodes = [
    // ── Yellow starting points taken directly from the supplied floor plan ──
    NavNode('tf_start_left', Offset(0.075, 0.423)),
    NavNode('tf_start_elevator', Offset(0.503, 0.617)),
    NavNode('tf_start_right', Offset(0.928, 0.423)),

    // Legacy transition point retained for the existing floor-transition map.
    NavNode('tf_start_top_left', Offset(0.503, 0.617)),

    // ── Main horizontal pathway following the red centerline ──
    NavNode('tf_h_000', Offset(0.030, 0.423)),
    NavNode('tf_h_010', Offset(0.075, 0.423)),
    NavNode('tf_h_020', Offset(0.110, 0.423)),
    NavNode('tf_h_030', Offset(0.160, 0.423)),
    NavNode('tf_h_040', Offset(0.220, 0.423)),
    NavNode('tf_h_050', Offset(0.290, 0.423)),
    NavNode('tf_h_060', Offset(0.350, 0.423)),
    NavNode('tf_h_070', Offset(0.400, 0.423)),
    NavNode('tf_h_080', Offset(0.445, 0.423)),
    NavNode('tf_h_090', Offset(0.503, 0.423)),
    NavNode('tf_h_100', Offset(0.560, 0.423)),
    NavNode('tf_h_110', Offset(0.620, 0.423)),
    NavNode('tf_h_120', Offset(0.680, 0.423)),
    NavNode('tf_h_130', Offset(0.730, 0.423)),
    NavNode('tf_h_140', Offset(0.785, 0.423)),
    NavNode('tf_h_150', Offset(0.840, 0.423)),
    NavNode('tf_h_160', Offset(0.895, 0.423)),
    NavNode('tf_h_170', Offset(0.940, 0.423)),
    NavNode('tf_h_180', Offset(0.980, 0.423)),

    // ── Central route from the elevator/yellow point ──
    NavNode('tf_c_000', Offset(0.503, 0.423)),
    NavNode('tf_c_010', Offset(0.503, 0.500)),
    NavNode('tf_c_020', Offset(0.503, 0.560)),
    NavNode('tf_c_030', Offset(0.503, 0.617)),

    // ── Branches following the marked red pathway ──
    NavNode('tf_branch_left', Offset(0.579, 0.617)),
    NavNode('tf_branch_right', Offset(0.419, 0.617)),
    NavNode('tf_activity_access', Offset(0.503, 0.730)),
    NavNode('tf_prayer_access', Offset(0.579, 0.730)),
    NavNode('tf_research_access', Offset(0.419, 0.730)),

    // ── Room destinations: centered inside the actual rooms ──
    NavNode('tf_room_lrc1', Offset(0.968750, 0.512668)),
    NavNode('tf_room_library', Offset(0.752500, 0.512668)),
    NavNode('tf_room_lrc2', Offset(0.579375, 0.512668)),

    NavNode('tf_room_prayer', Offset(0.579375, 0.783905)),
    NavNode('tf_room_activity', Offset(0.503125, 0.828614)),
    NavNode('tf_room_research', Offset(0.418750, 0.783905)),

    NavNode('tf_room_restroom_l', Offset(0.443750, 0.512668)),
    NavNode('tf_room_restroom_r', Offset(0.417500, 0.512668)),
    NavNode('tf_room_classroom_1', Offset(0.368750, 0.512668)),
    NavNode('tf_room_classroom_2', Offset(0.334375, 0.512668)),
    NavNode('tf_room_classroom_3', Offset(0.296875, 0.512668)),
    NavNode('tf_room_classroom_4', Offset(0.256250, 0.512668)),
    NavNode('tf_room_classroom_5', Offset(0.215625, 0.512668)),
    NavNode('tf_room_sci_lab', Offset(0.131250, 0.512668)),
    NavNode('tf_room_classroom_6', Offset(0.034375, 0.512668)),

    NavNode('tf_room_bleacher_l', Offset(0.803125, 0.217586)),
    NavNode('tf_room_bleacher_r', Offset(0.225000, 0.217586)),
    NavNode('tf_room_main_stage', Offset(0.503125, 0.120715)),
  ];

  static const List<NavEdge> thirdEdges = [
    // ── Main horizontal pathway ──
    NavEdge('tf_h_000', 'tf_h_010'),
    NavEdge('tf_h_010', 'tf_h_020'),
    NavEdge('tf_h_020', 'tf_h_030'),
    NavEdge('tf_h_030', 'tf_h_040'),
    NavEdge('tf_h_040', 'tf_h_050'),
    NavEdge('tf_h_050', 'tf_h_060'),
    NavEdge('tf_h_060', 'tf_h_070'),
    NavEdge('tf_h_070', 'tf_h_080'),
    NavEdge('tf_h_080', 'tf_h_090'),
    NavEdge('tf_h_090', 'tf_h_100'),
    NavEdge('tf_h_100', 'tf_h_110'),
    NavEdge('tf_h_110', 'tf_h_120'),
    NavEdge('tf_h_120', 'tf_h_130'),
    NavEdge('tf_h_130', 'tf_h_140'),
    NavEdge('tf_h_140', 'tf_h_150'),
    NavEdge('tf_h_150', 'tf_h_160'),
    NavEdge('tf_h_160', 'tf_h_170'),
    NavEdge('tf_h_170', 'tf_h_180'),

    // ── Yellow starting points ──
    NavEdge('tf_start_left', 'tf_h_010'),
    NavEdge('tf_start_right', 'tf_h_170'),
    NavEdge('tf_start_elevator', 'tf_c_030'),
    NavEdge('tf_start_top_left', 'tf_c_030'),

    // ── Elevator/central pathway ──
    NavEdge('tf_h_090', 'tf_c_010'),
    NavEdge('tf_c_010', 'tf_c_020'),
    NavEdge('tf_c_020', 'tf_c_030'),

    // ── Central branches ──
    NavEdge('tf_c_030', 'tf_branch_left'),
    NavEdge('tf_c_030', 'tf_branch_right'),
    NavEdge('tf_c_030', 'tf_activity_access'),
    NavEdge('tf_branch_left', 'tf_prayer_access'),
    NavEdge('tf_branch_right', 'tf_research_access'),

    // ── Exact room-center endpoints ──
    NavEdge('tf_h_010', 'tf_room_classroom_6'),
    NavEdge('tf_h_030', 'tf_room_sci_lab'),
    NavEdge('tf_h_050', 'tf_room_classroom_5'),
    NavEdge('tf_h_060', 'tf_room_classroom_4'),
    NavEdge('tf_h_070', 'tf_room_classroom_3'),
    NavEdge('tf_h_080', 'tf_room_classroom_2'),
    NavEdge('tf_h_090', 'tf_room_classroom_1'),

    NavEdge('tf_h_100', 'tf_room_restroom_l'),
    NavEdge('tf_h_100', 'tf_room_restroom_r'),
    NavEdge('tf_h_110', 'tf_room_lrc2'),
    NavEdge('tf_h_140', 'tf_room_library'),
    NavEdge('tf_h_170', 'tf_room_lrc1'),

    NavEdge('tf_prayer_access', 'tf_room_prayer'),
    NavEdge('tf_activity_access', 'tf_room_activity'),
    NavEdge('tf_research_access', 'tf_room_research'),

    NavEdge('tf_h_140', 'tf_room_bleacher_l'),
    NavEdge('tf_h_050', 'tf_room_bleacher_r'),
    NavEdge('tf_h_090', 'tf_room_main_stage'),
  ];

  // ════════════════════════════════════════════════════
  //  ROOM → NODE MAPPING
  // ════════════════════════════════════════════════════
  static const Map<String, String> roomToNode = {
    // Ground floor
    'gf_main_lobby': 'gf_v_main_lobby_entrance',
    'gf_drive_way': 'gf_v_100',
    'gf_scholarship': 'gf_room_scholarship',
    'gf_ojt': 'gf_room_ojt',
    'gf_accreditation': 'gf_room_accreditation',
    'gf_record': 'gf_room_record',
    'gf_registrar': 'gf_room_registrar',
    'gf_vp_admin': 'gf_room_vp_admin',
    'gf_crim_lab': 'gf_room_crim_lab',
    'gf_icje': 'gf_h_020',
    'gf_sldo': 'gf_room_sldo',
    'gf_ciso': 'gf_room_ciso',
    'gf_avr': 'gf_room_avr',
    'gf_dressing': 'gf_room_dressing',
    'gf_music': 'gf_room_music',
    'gf_dance': 'gf_room_dance',
    'gf_barracks': 'gf_room_barracks',
    'gf_medical': 'gf_room_medical',
    'gf_restroom_left': 'gf_room_toilet_left',
    'gf_restroom_center': 'gf_room_restroom_tc',
    'gf_restroom_right': 'gf_room_restroom_tr',
    'gf_mb105': 'gf_room_mb105',
    'gf_mb103': 'gf_room_mb103',
    'gf_mpr': 'gf_room_mpr',
    'gf_midwifery': 'gf_room_midwifery',
    'gf_pfom': 'gf_room_pfom',
    'gf_ias': 'gf_room_ias',
    'gf_ite': 'gf_room_ite',
    'gf_ibfs': 'gf_room_ibfs',
    'gf_ihs': 'gf_room_ihs',
    'gf_training': 'gf_room_training',
    'gf_ics': 'gf_room_ics',
    'gf_cr_left1': 'gf_room_cr_l1',
    'gf_cr_left2': 'gf_room_cr_l2',
    'gf_cr_right1': 'gf_room_cr_r1',
    'gf_cr_right2': 'gf_room_cr_r2',
    'gf_elevator': 'gf_room_elevator',
    // 2nd floor
    'sf_main_stage': 'sf_room_main_stage',
    'sf_guidance_testing': 'sf_room_guidance_test',
    'sf_sub_lobby': 'sf_room_sub_lobby',
    'sf_computer_lab': 'sf_room_comp_lab',
    'sf_computer_room_1': 'sf_room_comp_room1',
    'sf_computer_room_2': 'sf_room_comp_room2',
    'sf_computer_room_3': 'sf_room_comp_room3',
    'sf_restroom_left': 'sf_room_restroom_l1',
    'sf_restroom_cl': 'sf_room_restroom_l1',
    'sf_restroom_cr': 'sf_room_restroom_l2',
    'sf_restroom_r1': 'sf_room_restroom_r1',
    'sf_restroom_r2': 'sf_room_restroom_r2',
    'sf_vip_lounge': 'sf_room_vip_lounge',
    'sf_faculty_lounge': 'sf_room_faculty_lounge',
    'sf_speech_lab': 'sf_room_speech_lab',
    'sf_bseed_left': 'sf_room_bseed_top',
    'sf_bseed_right': 'sf_room_bseed_bot',
    'sf_guidance_counsel': 'sf_room_guidance_counsel',
    'sf_moot_court': 'sf_room_moot_court',
    'sf_business_center': 'sf_room_business',
    'sf_classroom_left': 'sf_room_classroom_l',
    'sf_classroom_center': 'sf_room_classroom_c',
    'sf_classroom_right': 'sf_room_classroom_r',
    'sf_board_room': 'sf_room_board',
    'sf_hrmo': 'sf_room_hrmo',
    'sf_faculty_room': 'sf_room_faculty',
    'sf_supply': 'sf_room_supply',
    'sf_vp_planning': 'sf_room_vp_planning',
    'sf_evp': 'sf_room_evp',
    'sf_deans': 'sf_room_deans',
    'sf_vpaa': 'sf_room_vpaa',
    'sf_president': 'sf_room_president',
    'sf_deck_canopy': 'sf_room_deck_canopy',
    'sf_bleacher_left': 'sf_room_bleacher_left',
    'sf_bleacher_right': 'sf_room_bleacher_right',
    // 3rd floor
    'tf_library': 'tf_room_library',
    'tf_lrc1': 'tf_room_lrc1',
    'tf_lrc2': 'tf_room_lrc2',
    'tf_prayer': 'tf_room_prayer',
    'tf_activity': 'tf_room_activity',
    'tf_research': 'tf_room_research',
    'tf_restroom_left': 'tf_room_restroom_l',
    'tf_restroom_right': 'tf_room_restroom_r',
    'tf_classroom_1': 'tf_room_classroom_1',
    'tf_classroom_2': 'tf_room_classroom_2',
    'tf_classroom_3': 'tf_room_classroom_3',
    'tf_classroom_4': 'tf_room_classroom_4',
    'tf_classroom_5': 'tf_room_classroom_5',
    'tf_classroom_6': 'tf_room_classroom_6',
    'tf_science_lab': 'tf_room_sci_lab',
    'tf_elevator': 'tf_start_elevator',
    'tf_main_stage': 'tf_room_main_stage',
    'tf_bleacher_left': 'tf_room_bleacher_l',
    'tf_bleacher_right': 'tf_room_bleacher_r',
  };

  // ════════════════════════════════════════════════════
  //  STARTING POINTS per floor index
  // ════════════════════════════════════════════════════════════
  static const Map<int, List<Map<String, String>>> startingPoints = {
    0: [
      {'label': 'Main Entrance (Driveway)', 'nodeId': 'gf_v_100'},
      {'label': 'Lobby Left Staircase', 'nodeId': 'gf_start_lobby_left'},
      {'label': 'Lobby Right Staircase', 'nodeId': 'gf_start_lobby_right'},
      {'label': 'Left Wing Staircase', 'nodeId': 'gf_start_stairs_left_top'},
      {'label': 'Right Wing Staircase', 'nodeId': 'gf_start_stairs_right_top'},
    ],
    1: [
      {'label': 'Left Staircase', 'nodeId': 'sf_start_left_mid'},
      {'label': 'Right Staircase', 'nodeId': 'sf_start_right_mid'},
      {'label': 'Center Staircase', 'nodeId': 'sf_start_center'},
      {'label': 'Bottom Left Staircase', 'nodeId': 'sf_start_bot_left'},
      {'label': 'Bottom Right Staircase', 'nodeId': 'sf_start_bot_right'},
    ],
    2: [
      {'label': 'Left Staircase', 'nodeId': 'tf_start_left'},
      {'label': 'Elevator', 'nodeId': 'tf_start_elevator'},
      {'label': 'Right Staircase', 'nodeId': 'tf_start_right'},
      {'label': 'Top Left Staircase', 'nodeId': 'tf_start_top_left'},
    ],
  };

  static List<NavNode> nodesForFloor(int floor) {
    switch (floor) {
      case 0:
        return groundNodes;
      case 1:
        return secondNodes;
      case 2:
        return thirdNodes;
      default:
        return groundNodes;
    }
  }

  static List<NavEdge> edgesForFloor(int floor) {
    switch (floor) {
      case 0:
        return groundEdges;
      case 1:
        return secondEdges;
      case 2:
        return thirdEdges;
      default:
        return groundEdges;
    }
  }

  static List<NavNode> getNodes(int floor) => nodesForFloor(floor);
  static List<NavEdge> getEdges(int floor) => edgesForFloor(floor);

  static String? getDefaultStartNode(int floor) {
    final points = startingPoints[floor];
    return points?.isNotEmpty == true ? points!.first['nodeId'] : null;
  }

  /// Returns all nodes for a floor formatted for debug visualization.
  static List<DebugNodeInfo> getDebugNodes(int floor) {
    final nodes = nodesForFloor(floor);
    return nodes
        .map(
          (n) => DebugNodeInfo(
            id: n.id,
            pos: n.pos,
            isRoom:
                n.id.startsWith('gf_room_') ||
                n.id.startsWith('sf_room_') ||
                n.id.startsWith('tf_room_'),
            isStair:
                n.id.contains('start') ||
                n.id.contains('stair') ||
                n.id.contains('elevator') ||
                n.id.contains('center_entrance') ||
                n.id.contains('cv_'),
          ),
        )
        .toList();
  }

  /// Returns all edges for a floor formatted for debug visualization.
  static List<DebugEdgeInfo> getDebugEdges(int floor) {
    return edgesForFloor(
      floor,
    ).map((e) => DebugEdgeInfo(from: e.from, to: e.to)).toList();
  }

  /// Validates the graph for a specific floor.
  /// Returns a list of validation issues (empty if valid).
  static List<String> validateFloor(int floor) {
    final issues = <String>[];
    final nodes = nodesForFloor(floor);
    final edges = edgesForFloor(floor);
    final nodeIds = nodes.map((n) => n.id).toSet();

    // Check for duplicate node IDs
    final seen = <String>{};
    for (final n in nodes) {
      if (seen.contains(n.id)) {
        issues.add('Duplicate node ID: ${n.id}');
      }
      seen.add(n.id);
    }

    // Check for dangling edges
    for (final edge in edges) {
      if (!nodeIds.contains(edge.from)) {
        issues.add(
          'Edge references missing from-node: ${edge.from} -> ${edge.to}',
        );
      }
      if (!nodeIds.contains(edge.to)) {
        issues.add(
          'Edge references missing to-node: ${edge.from} -> ${edge.to}',
        );
      }
    }

    // Check roomToNode mappings exist in this floor's nodes
    for (final entry in roomToNode.entries) {
      final nodeId = entry.value;
      if (!nodeIds.contains(nodeId)) {
        // Only warn if the room maps to this floor
        final nodeFloor = _getFloorForNode(nodeId);
        if (nodeFloor == floor) {
          issues.add('roomToNode target not in graph: ${entry.key} -> $nodeId');
        }
      }
    }

    return issues;
  }

  static int? _getFloorForNode(String nodeId) {
    for (int f = 0; f < 3; f++) {
      if (nodesForFloor(f).any((n) => n.id == nodeId)) return f;
    }
    return null;
  }
}

/// Debug information for a navigation node.
class DebugNodeInfo {
  final String id;
  final Offset pos;
  final bool isRoom;
  final bool isStair;

  const DebugNodeInfo({
    required this.id,
    required this.pos,
    required this.isRoom,
    required this.isStair,
  });
}

/// Debug information for a navigation edge.
class DebugEdgeInfo {
  final String from;
  final String to;

  const DebugEdgeInfo({required this.from, required this.to});
}
