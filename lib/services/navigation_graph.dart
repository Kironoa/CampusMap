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

class NavigationGraph {

  // ════════════════════════════════════════════════════
  //  GROUND FLOOR
  // ════════════════════════════════════════════════════
  static const List<NavNode> groundNodes = [
    // ── Entry / Starting points (yellow) ──
    NavNode('gf_start_stairs_left_top',   Offset(0.095, 0.130)),
    NavNode('gf_start_stairs_right_top',  Offset(0.895, 0.075)),
    NavNode('gf_start_left_mid',          Offset(0.065, 0.370)),
    NavNode('gf_start_right_mid',         Offset(0.960, 0.370)),
    NavNode('gf_start_lobby_left',        Offset(0.435, 0.560)),
    NavNode('gf_start_lobby_center',      Offset(0.468, 0.560)),
    NavNode('gf_start_lobby_right',       Offset(0.565, 0.560)),

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
    NavNode('gf_v_050', Offset(0.468, 0.580)),
    NavNode('gf_v_060', Offset(0.468, 0.640)),
    NavNode('gf_v_070', Offset(0.468, 0.720)),
    NavNode('gf_v_080', Offset(0.468, 0.800)),
    NavNode('gf_v_090', Offset(0.468, 0.870)),
    NavNode('gf_v_100', Offset(0.468, 0.950)),

    // ── Entry connections from yellow starts into corridor ──
    NavNode('gf_conn_stairs_lt', Offset(0.095, 0.305)),
    NavNode('gf_conn_stairs_rt', Offset(0.895, 0.305)),

    // ── Room stub nodes (accessible directly from corridor) ──
    NavNode('gf_room_ics',          Offset(0.130, 0.190)),
    NavNode('gf_room_training',     Offset(0.180, 0.190)),
    NavNode('gf_room_ihs',          Offset(0.240, 0.190)),
    NavNode('gf_room_ibfs',         Offset(0.295, 0.190)),
    NavNode('gf_room_ite',          Offset(0.360, 0.190)),
    NavNode('gf_room_restroom_tc',  Offset(0.468, 0.190)),
    NavNode('gf_room_ias',          Offset(0.468, 0.130)),
    NavNode('gf_room_medical',      Offset(0.630, 0.190)),
    NavNode('gf_room_restroom_tr',  Offset(0.895, 0.190)),
    NavNode('gf_room_mb105',        Offset(0.720, 0.190)),
    NavNode('gf_room_mb103',        Offset(0.775, 0.190)),
    NavNode('gf_room_mpr',          Offset(0.830, 0.190)),
    NavNode('gf_room_midwifery',    Offset(0.885, 0.190)),
    NavNode('gf_room_pfom',         Offset(0.960, 0.190)),
    NavNode('gf_room_toilet_left',  Offset(0.050, 0.130)),
    NavNode('gf_room_toilet_right', Offset(0.960, 0.075)),
    NavNode('gf_room_cr_l1',        Offset(0.170, 0.130)),
    NavNode('gf_room_cr_l2',        Offset(0.195, 0.130)),
    NavNode('gf_room_cr_r1',        Offset(0.895, 0.130)),
    NavNode('gf_room_cr_r2',        Offset(0.920, 0.130)),
    // Bottom row (y≈0.420, accessed by stepping off corridor downward)
    NavNode('gf_room_sldo',         Offset(0.030, 0.420)),
    NavNode('gf_room_icje',         Offset(0.095, 0.420)),
    NavNode('gf_room_crim_lab',     Offset(0.185, 0.420)),
    NavNode('gf_room_vp_admin',     Offset(0.300, 0.420)),
    NavNode('gf_room_registrar',    Offset(0.375, 0.420)),
    NavNode('gf_room_record',       Offset(0.438, 0.420)),
    NavNode('gf_room_ciso',         Offset(0.595, 0.420)),
    NavNode('gf_room_avr',          Offset(0.670, 0.420)),
    NavNode('gf_room_dressing',     Offset(0.745, 0.420)),
    NavNode('gf_room_music',        Offset(0.815, 0.420)),
    NavNode('gf_room_dance',        Offset(0.885, 0.420)),
    NavNode('gf_room_barracks',     Offset(0.960, 0.420)),
    NavNode('gf_room_elevator',     Offset(0.468, 0.370)),
    // Lobby section (accessed via vertical spine)
    NavNode('gf_room_scholarship',  Offset(0.435, 0.490)),
    NavNode('gf_room_ojt',          Offset(0.435, 0.550)),
    NavNode('gf_room_accreditation',Offset(0.595, 0.490)),
    NavNode('gf_room_main_lobby',   Offset(0.595, 0.560)),
  ];

  static const List<NavEdge> groundEdges = [
    // ── Horizontal corridor ──
    NavEdge('gf_h_000','gf_h_010'), NavEdge('gf_h_010','gf_h_020'),
    NavEdge('gf_h_020','gf_h_030'), NavEdge('gf_h_030','gf_h_040'),
    NavEdge('gf_h_040','gf_h_050'), NavEdge('gf_h_050','gf_h_060'),
    NavEdge('gf_h_060','gf_h_070'), NavEdge('gf_h_070','gf_h_080'),
    NavEdge('gf_h_080','gf_h_090'), NavEdge('gf_h_090','gf_h_100'),
    NavEdge('gf_h_100','gf_h_110'), NavEdge('gf_h_110','gf_h_120'),
    NavEdge('gf_h_120','gf_h_130'), NavEdge('gf_h_130','gf_h_140'),
    NavEdge('gf_h_140','gf_h_150'), NavEdge('gf_h_150','gf_h_160'),
    NavEdge('gf_h_160','gf_h_170'), NavEdge('gf_h_170','gf_h_180'),
    NavEdge('gf_h_180','gf_h_190'), NavEdge('gf_h_190','gf_h_200'),
    NavEdge('gf_h_200','gf_h_210'),
    // ── Entry yellow nodes connect to nearest corridor node ──
    NavEdge('gf_start_stairs_left_top','gf_conn_stairs_lt'),
    NavEdge('gf_conn_stairs_lt','gf_h_020'),
    NavEdge('gf_start_stairs_right_top','gf_conn_stairs_rt'),
    NavEdge('gf_conn_stairs_rt','gf_h_190'),
    NavEdge('gf_start_left_mid','gf_h_010'),
    NavEdge('gf_start_right_mid','gf_h_210'),
    NavEdge('gf_start_lobby_left','gf_v_040'),
    NavEdge('gf_start_lobby_center','gf_v_050'),
    NavEdge('gf_start_lobby_right','gf_v_040'),
    // ── Vertical spine (gf_h_100 == gf_v_000, share position) ──
    NavEdge('gf_h_100','gf_v_010'),
    NavEdge('gf_v_010','gf_v_020'), NavEdge('gf_v_020','gf_v_030'),
    NavEdge('gf_v_030','gf_v_040'), NavEdge('gf_v_040','gf_v_050'),
    NavEdge('gf_v_050','gf_v_060'), NavEdge('gf_v_060','gf_v_070'),
    NavEdge('gf_v_070','gf_v_080'), NavEdge('gf_v_080','gf_v_090'),
    NavEdge('gf_v_090','gf_v_100'),
    // ── Top-row room stubs (off horizontal corridor going up) ──
    NavEdge('gf_h_030','gf_room_ics'),
    NavEdge('gf_h_040','gf_room_training'),
    NavEdge('gf_h_050','gf_room_ihs'),
    NavEdge('gf_h_060','gf_room_ibfs'),
    NavEdge('gf_h_080','gf_room_ite'),
    NavEdge('gf_h_100','gf_room_restroom_tc'),
    NavEdge('gf_room_restroom_tc','gf_room_ias'),
    NavEdge('gf_h_130','gf_room_medical'),
    NavEdge('gf_h_190','gf_room_restroom_tr'),
    NavEdge('gf_h_150','gf_room_mb105'),
    NavEdge('gf_h_160','gf_room_mb103'),
    NavEdge('gf_h_170','gf_room_mpr'),
    NavEdge('gf_h_180','gf_room_midwifery'),
    NavEdge('gf_h_210','gf_room_pfom'),
    NavEdge('gf_h_000','gf_room_toilet_left'),
    NavEdge('gf_h_200','gf_room_toilet_right'),
    NavEdge('gf_h_040','gf_room_cr_l1'),
    NavEdge('gf_h_040','gf_room_cr_l2'),
    NavEdge('gf_h_190','gf_room_cr_r1'),
    NavEdge('gf_h_190','gf_room_cr_r2'),
    // ── Bottom-row room stubs (off horizontal corridor going down) ──
    NavEdge('gf_h_000','gf_room_sldo'),
    NavEdge('gf_h_010','gf_room_icje'),
    NavEdge('gf_h_040','gf_room_crim_lab'),
    NavEdge('gf_h_060','gf_room_vp_admin'),
    NavEdge('gf_h_080','gf_room_registrar'),
    NavEdge('gf_h_090','gf_room_record'),
    NavEdge('gf_h_110','gf_room_ciso'),
    NavEdge('gf_h_130','gf_room_avr'),
    NavEdge('gf_h_150','gf_room_dressing'),
    NavEdge('gf_h_160','gf_room_music'),
    NavEdge('gf_h_180','gf_room_dance'),
    NavEdge('gf_h_210','gf_room_barracks'),
    NavEdge('gf_v_010','gf_room_elevator'),
    // ── Lobby room stubs (off vertical spine) ──
    NavEdge('gf_v_030','gf_room_scholarship'),
    NavEdge('gf_v_040','gf_room_ojt'),
    NavEdge('gf_v_030','gf_room_accreditation'),
    NavEdge('gf_v_050','gf_room_main_lobby'),
  ];

  // ════════════════════════════════════════════════════
  //  2ND FLOOR
  // ════════════════════════════════════════════════════
  static const List<NavNode> secondNodes = [
    // ── Entry / Starting points (yellow) ──
    NavNode('sf_start_left_mid',    Offset(0.065, 0.500)),
    NavNode('sf_start_right_mid',   Offset(0.960, 0.500)),
    NavNode('sf_start_center',      Offset(0.468, 0.415)),
    NavNode('sf_start_bot_left',    Offset(0.435, 0.760)),
    NavNode('sf_start_bot_right',   Offset(0.595, 0.760)),

    // ── Horizontal corridor (y≈0.415) ──
    NavNode('sf_h_000', Offset(0.030, 0.415)),
    NavNode('sf_h_010', Offset(0.065, 0.415)),
    NavNode('sf_h_020', Offset(0.120, 0.415)),
    NavNode('sf_h_030', Offset(0.185, 0.415)),
    NavNode('sf_h_040', Offset(0.255, 0.415)),
    NavNode('sf_h_050', Offset(0.320, 0.415)),
    NavNode('sf_h_060', Offset(0.375, 0.415)),
    NavNode('sf_h_070', Offset(0.420, 0.415)),
    NavNode('sf_h_080', Offset(0.468, 0.415)),
    NavNode('sf_h_090', Offset(0.510, 0.415)),
    NavNode('sf_h_100', Offset(0.560, 0.415)),
    NavNode('sf_h_110', Offset(0.595, 0.415)),
    NavNode('sf_h_120', Offset(0.640, 0.415)),
    NavNode('sf_h_130', Offset(0.695, 0.415)),
    NavNode('sf_h_140', Offset(0.745, 0.415)),
    NavNode('sf_h_150', Offset(0.800, 0.415)),
    NavNode('sf_h_160', Offset(0.855, 0.415)),
    NavNode('sf_h_170', Offset(0.905, 0.415)),
    NavNode('sf_h_180', Offset(0.960, 0.415)),
    NavNode('sf_h_190', Offset(0.980, 0.415)),

    // ── Left vertical spine (x≈0.468, going down) ──
    NavNode('sf_lv_000', Offset(0.468, 0.415)),
    NavNode('sf_lv_010', Offset(0.468, 0.480)),
    NavNode('sf_lv_020', Offset(0.468, 0.540)),
    NavNode('sf_lv_030', Offset(0.468, 0.600)),
    NavNode('sf_lv_040', Offset(0.468, 0.660)),
    NavNode('sf_lv_050', Offset(0.468, 0.720)),
    NavNode('sf_lv_060', Offset(0.468, 0.760)),

    // ── Right vertical spine (x≈0.595, going down) ──
    NavNode('sf_rv_000', Offset(0.595, 0.415)),
    NavNode('sf_rv_010', Offset(0.595, 0.480)),
    NavNode('sf_rv_020', Offset(0.595, 0.550)),
    NavNode('sf_rv_030', Offset(0.595, 0.630)),
    NavNode('sf_rv_040', Offset(0.595, 0.700)),
    NavNode('sf_rv_050', Offset(0.595, 0.760)),

    // ── Room stubs ──
    // Top row
    NavNode('sf_room_guidance_test',   Offset(0.045, 0.320)),
    NavNode('sf_room_sub_lobby',       Offset(0.090, 0.320)),
    NavNode('sf_room_comp_lab',        Offset(0.185, 0.320)),
    NavNode('sf_room_comp_room1',      Offset(0.285, 0.320)),
    NavNode('sf_room_comp_room2',      Offset(0.360, 0.320)),
    NavNode('sf_room_comp_room3',      Offset(0.420, 0.320)),
    NavNode('sf_room_restroom_l1',     Offset(0.468, 0.320)),
    NavNode('sf_room_restroom_l2',     Offset(0.490, 0.320)),
    NavNode('sf_room_restroom_r1',     Offset(0.790, 0.320)),
    NavNode('sf_room_restroom_r2',     Offset(0.820, 0.320)),
    NavNode('sf_room_vip_lounge',      Offset(0.590, 0.320)),
    NavNode('sf_room_faculty_lounge',  Offset(0.740, 0.320)),
    NavNode('sf_room_speech_lab',      Offset(0.875, 0.320)),
    NavNode('sf_room_bseed_top',       Offset(0.970, 0.320)),
    NavNode('sf_room_main_stage',      Offset(0.500, 0.120)),
    NavNode('sf_room_bleacher_left',   Offset(0.250, 0.200)),
    NavNode('sf_room_bleacher_right',  Offset(0.750, 0.200)),
    // Bottom row
    NavNode('sf_room_guidance_counsel',Offset(0.045, 0.510)),
    NavNode('sf_room_moot_court',      Offset(0.170, 0.510)),
    NavNode('sf_room_business',        Offset(0.290, 0.510)),
    NavNode('sf_room_classroom_l',     Offset(0.380, 0.510)),
    NavNode('sf_room_classroom_c',     Offset(0.425, 0.510)),
    NavNode('sf_room_classroom_r',     Offset(0.460, 0.510)),
    NavNode('sf_room_board',           Offset(0.560, 0.510)),
    NavNode('sf_room_hrmo',            Offset(0.640, 0.510)),
    NavNode('sf_room_faculty',         Offset(0.720, 0.510)),
    NavNode('sf_room_supply',          Offset(0.795, 0.510)),
    NavNode('sf_room_vp_planning',     Offset(0.855, 0.510)),
    NavNode('sf_room_evp',             Offset(0.910, 0.510)),
    NavNode('sf_room_bseed_bot',       Offset(0.970, 0.510)),
    // Lower section (via vertical spines)
    NavNode('sf_room_deans',           Offset(0.440, 0.590)),
    NavNode('sf_room_vpaa',            Offset(0.440, 0.680)),
    NavNode('sf_room_president',       Offset(0.595, 0.630)),
    NavNode('sf_room_deck_canopy',     Offset(0.500, 0.920)),
  ];

  static const List<NavEdge> secondEdges = [
    // ── Horizontal corridor ──
    NavEdge('sf_h_000','sf_h_010'), NavEdge('sf_h_010','sf_h_020'),
    NavEdge('sf_h_020','sf_h_030'), NavEdge('sf_h_030','sf_h_040'),
    NavEdge('sf_h_040','sf_h_050'), NavEdge('sf_h_050','sf_h_060'),
    NavEdge('sf_h_060','sf_h_070'), NavEdge('sf_h_070','sf_h_080'),
    NavEdge('sf_h_080','sf_h_090'), NavEdge('sf_h_090','sf_h_100'),
    NavEdge('sf_h_100','sf_h_110'), NavEdge('sf_h_110','sf_h_120'),
    NavEdge('sf_h_120','sf_h_130'), NavEdge('sf_h_130','sf_h_140'),
    NavEdge('sf_h_140','sf_h_150'), NavEdge('sf_h_150','sf_h_160'),
    NavEdge('sf_h_160','sf_h_170'), NavEdge('sf_h_170','sf_h_180'),
    NavEdge('sf_h_180','sf_h_190'),
    // ── Entry yellow nodes ──
    NavEdge('sf_start_left_mid','sf_h_010'),
    NavEdge('sf_start_right_mid','sf_h_180'),
    NavEdge('sf_start_center','sf_h_080'),
    NavEdge('sf_start_bot_left','sf_lv_060'),
    NavEdge('sf_start_bot_right','sf_rv_050'),
    // ── Left vertical spine ──
    NavEdge('sf_h_080','sf_lv_010'),
    NavEdge('sf_lv_010','sf_lv_020'), NavEdge('sf_lv_020','sf_lv_030'),
    NavEdge('sf_lv_030','sf_lv_040'), NavEdge('sf_lv_040','sf_lv_050'),
    NavEdge('sf_lv_050','sf_lv_060'),
    // ── Right vertical spine ──
    NavEdge('sf_h_110','sf_rv_010'),
    NavEdge('sf_rv_010','sf_rv_020'), NavEdge('sf_rv_020','sf_rv_030'),
    NavEdge('sf_rv_030','sf_rv_040'), NavEdge('sf_rv_040','sf_rv_050'),
    // ── Top-row room stubs ──
    NavEdge('sf_h_010','sf_room_guidance_test'),
    NavEdge('sf_h_010','sf_room_sub_lobby'),
    NavEdge('sf_h_030','sf_room_comp_lab'),
    NavEdge('sf_h_040','sf_room_comp_room1'),
    NavEdge('sf_h_060','sf_room_comp_room2'),
    NavEdge('sf_h_070','sf_room_comp_room3'),
    NavEdge('sf_h_080','sf_room_restroom_l1'),
    NavEdge('sf_h_090','sf_room_restroom_l2'),
    NavEdge('sf_h_110','sf_room_vip_lounge'),
    NavEdge('sf_h_140','sf_room_faculty_lounge'),
    NavEdge('sf_h_150','sf_room_restroom_r1'),
    NavEdge('sf_h_160','sf_room_restroom_r2'),
    NavEdge('sf_h_170','sf_room_speech_lab'),
    NavEdge('sf_h_190','sf_room_bseed_top'),
    NavEdge('sf_h_080','sf_room_main_stage'),
    NavEdge('sf_h_040','sf_room_bleacher_left'),
    NavEdge('sf_h_140','sf_room_bleacher_right'),
    // ── Bottom-row room stubs ──
    NavEdge('sf_h_010','sf_room_guidance_counsel'),
    NavEdge('sf_h_030','sf_room_moot_court'),
    NavEdge('sf_h_050','sf_room_business'),
    NavEdge('sf_h_060','sf_room_classroom_l'),
    NavEdge('sf_h_070','sf_room_classroom_c'),
    NavEdge('sf_h_080','sf_room_classroom_r'),
    NavEdge('sf_h_100','sf_room_board'),
    NavEdge('sf_h_120','sf_room_hrmo'),
    NavEdge('sf_h_130','sf_room_faculty'),
    NavEdge('sf_h_150','sf_room_supply'),
    NavEdge('sf_h_160','sf_room_vp_planning'),
    NavEdge('sf_h_170','sf_room_evp'),
    NavEdge('sf_h_190','sf_room_bseed_bot'),
    // ── Lower section via spines ──
    NavEdge('sf_lv_030','sf_room_deans'),
    NavEdge('sf_lv_040','sf_room_vpaa'),
    NavEdge('sf_rv_030','sf_room_president'),
    NavEdge('sf_lv_060','sf_room_deck_canopy'),
  ];

  // ═══════════���═���══════════════════════════════════════
  //  3RD FLOOR
  // ════════════════════════════════════════════════════
  static const List<NavNode> thirdNodes = [
    // ── Entry / Starting points (yellow) ──
    NavNode('tf_start_left',      Offset(0.065, 0.420)),
    NavNode('tf_start_elevator',  Offset(0.490, 0.300)),
    NavNode('tf_start_right',     Offset(0.960, 0.420)),
    NavNode('tf_start_top_left',  Offset(0.380, 0.080)),

    // ── Single horizontal corridor (y≈0.420) ──
    NavNode('tf_h_000', Offset(0.030, 0.420)),
    NavNode('tf_h_010', Offset(0.065, 0.420)),
    NavNode('tf_h_020', Offset(0.110, 0.420)),
    NavNode('tf_h_030', Offset(0.160, 0.420)),
    NavNode('tf_h_040', Offset(0.220, 0.420)),
    NavNode('tf_h_050', Offset(0.290, 0.420)),
    NavNode('tf_h_060', Offset(0.350, 0.420)),
    NavNode('tf_h_070', Offset(0.380, 0.420)),
    NavNode('tf_h_080', Offset(0.435, 0.420)),
    NavNode('tf_h_090', Offset(0.490, 0.420)),
    NavNode('tf_h_100', Offset(0.560, 0.420)),
    NavNode('tf_h_110', Offset(0.620, 0.420)),
    NavNode('tf_h_120', Offset(0.680, 0.420)),
    NavNode('tf_h_130', Offset(0.730, 0.420)),
    NavNode('tf_h_140', Offset(0.785, 0.420)),
    NavNode('tf_h_150', Offset(0.840, 0.420)),
    NavNode('tf_h_160', Offset(0.895, 0.420)),
    NavNode('tf_h_170', Offset(0.940, 0.420)),
    NavNode('tf_h_180', Offset(0.980, 0.420)),

    // ── Left vertical protrusion (x≈0.380, going UP from corridor) ──
    NavNode('tf_lp_000', Offset(0.380, 0.420)),
    NavNode('tf_lp_010', Offset(0.380, 0.340)),
    NavNode('tf_lp_020', Offset(0.380, 0.260)),
    NavNode('tf_lp_030', Offset(0.380, 0.180)),
    NavNode('tf_lp_040', Offset(0.380, 0.100)),
    NavNode('tf_lp_top',  Offset(0.380, 0.050)),

    // ── Right vertical protrusion (x≈0.620, going UP from corridor) ──
    NavNode('tf_rp_000', Offset(0.620, 0.420)),
    NavNode('tf_rp_010', Offset(0.620, 0.340)),
    NavNode('tf_rp_020', Offset(0.620, 0.260)),
    NavNode('tf_rp_030', Offset(0.620, 0.180)),
    NavNode('tf_rp_040', Offset(0.620, 0.100)),
    NavNode('tf_rp_top',  Offset(0.620, 0.050)),

    // ── Horizontal connector at mid-protrusion height (y≈0.300) ──
    NavNode('tf_mid_left',  Offset(0.380, 0.300)),
    NavNode('tf_mid_elev',  Offset(0.490, 0.300)),
    NavNode('tf_mid_right', Offset(0.620, 0.300)),

    // ── Room stubs ──
    NavNode('tf_room_lrc1',        Offset(0.065, 0.300)),
    NavNode('tf_room_library',     Offset(0.260, 0.300)),
    NavNode('tf_room_lrc2',        Offset(0.430, 0.300)),
    NavNode('tf_room_prayer',      Offset(0.380, 0.185)),
    NavNode('tf_room_activity',    Offset(0.490, 0.150)),
    NavNode('tf_room_research',    Offset(0.620, 0.185)),
    NavNode('tf_room_restroom_l',  Offset(0.560, 0.300)),
    NavNode('tf_room_restroom_r',  Offset(0.590, 0.300)),
    NavNode('tf_room_classroom_1', Offset(0.650, 0.300)),
    NavNode('tf_room_classroom_2', Offset(0.700, 0.300)),
    NavNode('tf_room_classroom_3', Offset(0.750, 0.300)),
    NavNode('tf_room_classroom_4', Offset(0.800, 0.300)),
    NavNode('tf_room_classroom_5', Offset(0.855, 0.300)),
    NavNode('tf_room_sci_lab',     Offset(0.920, 0.300)),
    NavNode('tf_room_classroom_6', Offset(0.975, 0.300)),
    NavNode('tf_room_bleacher_l',  Offset(0.250, 0.600)),
    NavNode('tf_room_bleacher_r',  Offset(0.750, 0.600)),
    NavNode('tf_room_main_stage',  Offset(0.500, 0.750)),
  ];

  static const List<NavEdge> thirdEdges = [
    // ── Horizontal corridor ──
    NavEdge('tf_h_000','tf_h_010'), NavEdge('tf_h_010','tf_h_020'),
    NavEdge('tf_h_020','tf_h_030'), NavEdge('tf_h_030','tf_h_040'),
    NavEdge('tf_h_040','tf_h_050'), NavEdge('tf_h_050','tf_h_060'),
    NavEdge('tf_h_060','tf_h_070'), NavEdge('tf_h_070','tf_h_080'),
    NavEdge('tf_h_080','tf_h_090'), NavEdge('tf_h_090','tf_h_100'),
    NavEdge('tf_h_100','tf_h_110'), NavEdge('tf_h_110','tf_h_120'),
    NavEdge('tf_h_120','tf_h_130'), NavEdge('tf_h_130','tf_h_140'),
    NavEdge('tf_h_140','tf_h_150'), NavEdge('tf_h_150','tf_h_160'),
    NavEdge('tf_h_160','tf_h_170'), NavEdge('tf_h_170','tf_h_180'),
    // ── Entry yellow nodes ──
    NavEdge('tf_start_left','tf_h_010'),
    NavEdge('tf_start_right','tf_h_170'),
    NavEdge('tf_start_elevator','tf_mid_elev'),
    NavEdge('tf_start_top_left','tf_lp_top'),
    // ── Left protrusion (upward from corridor) ──
    NavEdge('tf_h_070','tf_lp_010'),
    NavEdge('tf_lp_010','tf_lp_020'), NavEdge('tf_lp_020','tf_lp_030'),
    NavEdge('tf_lp_030','tf_lp_040'), NavEdge('tf_lp_040','tf_lp_top'),
    // ── Right protrusion (upward from corridor) ──
    NavEdge('tf_h_110','tf_rp_010'),
    NavEdge('tf_rp_010','tf_rp_020'), NavEdge('tf_rp_020','tf_rp_030'),
    NavEdge('tf_rp_030','tf_rp_040'), NavEdge('tf_rp_040','tf_rp_top'),
    // ── Mid horizontal connector (y≈0.300) linking protrusions and elevator ──
    NavEdge('tf_lp_020','tf_mid_left'),
    NavEdge('tf_mid_left','tf_mid_elev'),
    NavEdge('tf_mid_elev','tf_mid_right'),
    NavEdge('tf_mid_right','tf_rp_020'),
    // ── Room stubs off protrusions ──
    NavEdge('tf_lp_030','tf_room_prayer'),
    NavEdge('tf_mid_elev','tf_room_activity'),
    NavEdge('tf_rp_030','tf_room_research'),
    // ── Room stubs off horizontal corridor (and mid connector) ──
    NavEdge('tf_h_010','tf_room_lrc1'),
    NavEdge('tf_h_040','tf_room_library'),
    NavEdge('tf_h_080','tf_room_lrc2'),
    NavEdge('tf_mid_left','tf_room_restroom_l'),
    NavEdge('tf_mid_elev','tf_room_restroom_r'),
    NavEdge('tf_mid_right','tf_room_classroom_1'),
    NavEdge('tf_h_120','tf_room_classroom_2'),
    NavEdge('tf_h_130','tf_room_classroom_3'),
    NavEdge('tf_h_140','tf_room_classroom_4'),
    NavEdge('tf_h_150','tf_room_classroom_5'),
    NavEdge('tf_h_160','tf_room_sci_lab'),
    NavEdge('tf_h_180','tf_room_classroom_6'),
    NavEdge('tf_h_040','tf_room_bleacher_l'),
    NavEdge('tf_h_140','tf_room_bleacher_r'),
    NavEdge('tf_h_090','tf_room_main_stage'),
  ];

  // ════════════════════════════════════════════════════
  //  ROOM → NODE MAPPING
  // ════════════════════════════════════════════════════
  static const Map<String, String> roomToNode = {
    // Ground floor
    'gf_main_lobby':       'gf_room_main_lobby',
    'gf_drive_way':        'gf_v_100',
    'gf_scholarship':      'gf_room_scholarship',
    'gf_ojt':              'gf_room_ojt',
    'gf_accreditation':    'gf_room_accreditation',
    'gf_record':           'gf_room_record',
    'gf_registrar':        'gf_room_registrar',
    'gf_vp_admin':         'gf_room_vp_admin',
    'gf_crim_lab':         'gf_room_crim_lab',
    'gf_icje':             'gf_room_icje',
    'gf_sldo':             'gf_room_sldo',
    'gf_ciso':             'gf_room_ciso',
    'gf_avr':              'gf_room_avr',
    'gf_dressing':         'gf_room_dressing',
    'gf_music':            'gf_room_music',
    'gf_dance':            'gf_room_dance',
    'gf_barracks':         'gf_room_barracks',
    'gf_medical':          'gf_room_medical',
    'gf_restroom_left':    'gf_room_toilet_left',
    'gf_restroom_center':  'gf_room_restroom_tc',
    'gf_restroom_right':   'gf_room_restroom_tr',
    'gf_mb105':            'gf_room_mb105',
    'gf_mb103':            'gf_room_mb103',
    'gf_mpr':              'gf_room_mpr',
    'gf_midwifery':        'gf_room_midwifery',
    'gf_pfom':             'gf_room_pfom',
    'gf_ias':              'gf_room_ias',
    'gf_ite':              'gf_room_ite',
    'gf_ibfs':             'gf_room_ibfs',
    'gf_ihs':              'gf_room_ihs',
    'gf_training':         'gf_room_training',
    'gf_ics':              'gf_room_ics',
    'gf_cr_left1':         'gf_room_cr_l1',
    'gf_cr_left2':         'gf_room_cr_l2',
    'gf_cr_right1':        'gf_room_cr_r1',
    'gf_cr_right2':        'gf_room_cr_r2',
    'gf_elevator':         'gf_room_elevator',
    // 2nd floor
    'sf_main_stage':       'sf_room_main_stage',
    'sf_guidance_testing': 'sf_room_guidance_test',
    'sf_sub_lobby':        'sf_room_sub_lobby',
    'sf_computer_lab':     'sf_room_comp_lab',
    'sf_computer_room_1':  'sf_room_comp_room1',
    'sf_computer_room_2':  'sf_room_comp_room2',
    'sf_computer_room_3':  'sf_room_comp_room3',
    'sf_restroom_left':    'sf_room_restroom_l1',
    'sf_restroom_cl':      'sf_room_restroom_l1',
    'sf_restroom_cr':      'sf_room_restroom_l2',
    'sf_restroom_r1':      'sf_room_restroom_r1',
    'sf_restroom_r2':      'sf_room_restroom_r2',
    'sf_vip_lounge':       'sf_room_vip_lounge',
    'sf_faculty_lounge':   'sf_room_faculty_lounge',
    'sf_speech_lab':       'sf_room_speech_lab',
    'sf_bseed_left':       'sf_room_bseed_top',
    'sf_bseed_right':      'sf_room_bseed_bot',
    'sf_guidance_counsel': 'sf_room_guidance_counsel',
    'sf_moot_court':       'sf_room_moot_court',
    'sf_business_center':  'sf_room_business',
    'sf_classroom_left':   'sf_room_classroom_l',
    'sf_classroom_center': 'sf_room_classroom_c',
    'sf_classroom_right':  'sf_room_classroom_r',
    'sf_board_room':       'sf_room_board',
    'sf_hrmo':             'sf_room_hrmo',
    'sf_faculty_room':     'sf_room_faculty',
    'sf_supply':           'sf_room_supply',
    'sf_vp_planning':      'sf_room_vp_planning',
    'sf_evp':              'sf_room_evp',
    'sf_deans':            'sf_room_deans',
    'sf_vpaa':             'sf_room_vpaa',
    'sf_president':        'sf_room_president',
    'sf_deck_canopy':      'sf_room_deck_canopy',
    'sf_bleacher_left':    'sf_room_bleacher_left',
    'sf_bleacher_right':   'sf_room_bleacher_right',
    // 3rd floor
    'tf_library':          'tf_room_library',
    'tf_lrc1':             'tf_room_lrc1',
    'tf_lrc2':             'tf_room_lrc2',
    'tf_prayer':           'tf_room_prayer',
    'tf_activity':         'tf_room_activity',
    'tf_research':         'tf_room_research',
    'tf_restroom_left':    'tf_room_restroom_l',
    'tf_restroom_right':   'tf_room_restroom_r',
    'tf_classroom_1':      'tf_room_classroom_1',
    'tf_classroom_2':      'tf_room_classroom_2',
    'tf_classroom_3':      'tf_room_classroom_3',
    'tf_classroom_4':      'tf_room_classroom_4',
    'tf_classroom_5':      'tf_room_classroom_5',
    'tf_classroom_6':      'tf_room_classroom_6',
    'tf_science_lab':      'tf_room_sci_lab',
    'tf_elevator':         'tf_start_elevator',
    'tf_main_stage':       'tf_room_main_stage',
    'tf_bleacher_left':    'tf_room_bleacher_l',
    'tf_bleacher_right':   'tf_room_bleacher_r',
  };

  // ════════════════════════════════════════════════════
  //  STARTING POINTS per floor index
  // ════════════════════════════════════════════════════════════
  static const Map<int, List<Map<String, String>>> startingPoints = {
    0: [
      {'label': 'Main Entrance (Driveway)', 'nodeId': 'gf_v_100'},
      {'label': 'Lobby Left Staircase',     'nodeId': 'gf_start_lobby_left'},
      {'label': 'Lobby Right Staircase',    'nodeId': 'gf_start_lobby_right'},
      {'label': 'Left Wing Staircase',      'nodeId': 'gf_start_stairs_left_top'},
      {'label': 'Right Wing Staircase',     'nodeId': 'gf_start_stairs_right_top'},
      {'label': 'Left Side Door',           'nodeId': 'gf_start_left_mid'},
      {'label': 'Right Side Door',          'nodeId': 'gf_start_right_mid'},
    ],
    1: [
      {'label': 'Left Staircase',           'nodeId': 'sf_start_left_mid'},
      {'label': 'Right Staircase',          'nodeId': 'sf_start_right_mid'},
      {'label': 'Center Staircase',         'nodeId': 'sf_start_center'},
      {'label': 'Bottom Left Staircase',    'nodeId': 'sf_start_bot_left'},
      {'label': 'Bottom Right Staircase',   'nodeId': 'sf_start_bot_right'},
    ],
    2: [
      {'label': 'Left Staircase',           'nodeId': 'tf_start_left'},
      {'label': 'Elevator',                 'nodeId': 'tf_start_elevator'},
      {'label': 'Right Staircase',          'nodeId': 'tf_start_right'},
      {'label': 'Top Left Staircase',       'nodeId': 'tf_start_top_left'},
    ],
  };

  static List<NavNode> nodesForFloor(int floor) {
    switch (floor) {
      case 0: return groundNodes;
      case 1: return secondNodes;
      case 2: return thirdNodes;
      default: return groundNodes;
    }
  }

  static List<NavEdge> edgesForFloor(int floor) {
    switch (floor) {
      case 0: return groundEdges;
      case 1: return secondEdges;
      case 2: return thirdEdges;
      default: return groundEdges;
    }
  }

  static List<NavNode> getNodes(int floor) => nodesForFloor(floor);
  static List<NavEdge> getEdges(int floor) => edgesForFloor(floor);

  static String? getDefaultStartNode(int floor) {
    final points = startingPoints[floor];
    return points?.isNotEmpty == true ? points!.first['nodeId'] : null;
  }
}