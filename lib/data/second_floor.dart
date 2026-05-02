import 'package:flutter/material.dart';

class Room {
  final String id;
  final String name;
  final String category;
  final String wing;

  Room({
    required this.id,
    required this.name,
    required this.category,
    required this.wing,
  });
}

class SecondFloorData {
  static List<Room> getRooms() {
    return [
      // --- CENTRAL AREA ---
      Room(
        id: 'sf_vip_lounge',
        name: 'V.I.P. Lounge',
        category: 'Specialized',
        wing: 'Center',
      ),
      Room(
        id: 'sf_main_stage',
        name: 'Main Stage',
        category: 'General',
        wing: 'Center',
      ),
      Room(
        id: 'sf_deck',
        name: 'Deck Canopy',
        category: 'General',
        wing: 'Center',
      ),
      Room(
        id: 'sf_pres_office',
        name: 'Office of the President',
        category: 'Office',
        wing: 'Center',
      ),
      Room(
        id: 'sf_deans_office',
        name: 'Deans Office',
        category: 'Office',
        wing: 'Center',
      ),
      Room(
        id: 'sf_vp_academic',
        name: 'VP for Academic Affairs',
        category: 'Office',
        wing: 'Center',
      ),
      Room(
        id: 'sf_elevator',
        name: 'Elevator',
        category: 'Utility',
        wing: 'Center',
      ),

      // --- WEST WING (LEFT SIDE) ---
      // Top Row
      Room(
        id: 'sf_comp_lab',
        name: 'Computer Laboratory',
        category: 'Lab',
        wing: 'West',
      ),
      Room(
        id: 'sf_comp_rm1',
        name: 'Computer Room 1',
        category: 'Lab',
        wing: 'West',
      ),
      Room(
        id: 'sf_comp_rm2',
        name: 'Computer Room 2',
        category: 'Lab',
        wing: 'West',
      ),
      Room(
        id: 'sf_guidance_test',
        name: 'Guidance Testing Center',
        category: 'Office',
        wing: 'West',
      ),

      // Bottom Row
      Room(
        id: 'sf_moot_court',
        name: 'Moot Court',
        category: 'Specialized',
        wing: 'West',
      ),
      Room(
        id: 'sf_biz_center',
        name: 'Business Center',
        category: 'Office',
        wing: 'West',
      ),
      Room(
        id: 'sf_classroom1',
        name: 'Classroom 1',
        category: 'Classroom',
        wing: 'West',
      ),
      Room(
        id: 'sf_guidance_counsel',
        name: 'Guidance Counseling Room',
        category: 'Office',
        wing: 'West',
      ),

      // --- EAST WING (RIGHT SIDE) ---
      // Top Row
      Room(
        id: 'sf_faculty_lounge',
        name: 'Faculty and Staff Lounge',
        category: 'General',
        wing: 'East',
      ),
      Room(
        id: 'sf_speech_lab',
        name: 'Speech Lab.',
        category: 'Lab',
        wing: 'East',
      ),
      Room(
        id: 'sf_bseed_sim1',
        name: 'BSEED Simulation Room 1',
        category: 'Lab',
        wing: 'East',
      ),

      // Bottom Row
      Room(
        id: 'sf_board_rm',
        name: 'Board Room',
        category: 'Office',
        wing: 'East',
      ),
      Room(
        id: 'sf_hrmo',
        name: 'Human Resource Management Office',
        category: 'Office',
        wing: 'East',
      ),
      Room(
        id: 'sf_faculty_rm',
        name: 'Faculty Room',
        category: 'Office',
        wing: 'East',
      ),
      Room(
        id: 'sf_supply',
        name: 'Supply Office',
        category: 'Office',
        wing: 'East',
      ),
      Room(
        id: 'sf_vp_planning',
        name: 'VP for Planning',
        category: 'Office',
        wing: 'East',
      ),
      Room(
        id: 'sf_evp_office',
        name: 'Executive Vice President Office',
        category: 'Office',
        wing: 'East',
      ),
      Room(
        id: 'sf_bseed_sim2',
        name: 'BSEED Simulation Room 2',
        category: 'Lab',
        wing: 'East',
      ),
    ];
  }
}
