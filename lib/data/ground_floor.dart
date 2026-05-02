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

class GroundFloorData {
  static List<Room> getRooms() {
    return [
      // --- CENTRAL AREA ---
      Room(
        id: 'gf_lobby',
        name: 'Main Lobby',
        category: 'General',
        wing: 'Center',
      ),
      Room(
        id: 'gf_driveway',
        name: 'Drive Way',
        category: 'General',
        wing: 'Center',
      ),
      Room(
        id: 'gf_elevator',
        name: 'Elevator',
        category: 'Utility',
        wing: 'Center',
      ),
      Room(
        id: 'gf_accred',
        name: 'Accreditation Room',
        category: 'Office',
        wing: 'Center',
      ),

      // --- WEST WING (LEFT SIDE) ---
      // Top Row (North)
      Room(
        id: 'gf_ics',
        name: 'Institute of Computer Studies',
        category: 'Institute',
        wing: 'West',
      ),
      Room(
        id: 'gf_tcgc',
        name: 'TCGC Dev\'t Training Center',
        category: 'Institute',
        wing: 'West',
      ),
      Room(
        id: 'gf_ihs',
        name: 'Institute of Health Sciences',
        category: 'Institute',
        wing: 'West',
      ),
      Room(
        id: 'gf_ibfs',
        name: 'Institute of Business & Financial Services',
        category: 'Institute',
        wing: 'West',
      ),

      // Bottom Row (South)
      Room(
        id: 'gf_registrar',
        name: 'Registrar\'s Office',
        category: 'Office',
        wing: 'West',
      ),
      Room(
        id: 'gf_vp_admin',
        name: 'VP Admin and Finance',
        category: 'Office',
        wing: 'West',
      ),
      Room(
        id: 'gf_crim_lab',
        name: 'Criminology Laboratory',
        category: 'Lab',
        wing: 'West',
      ),
      Room(
        id: 'gf_icje',
        name: 'Institute of Criminal Justice Education',
        category: 'Institute',
        wing: 'West',
      ),

      // --- EAST WING (RIGHT SIDE) ---
      // Top Row (North)
      Room(
        id: 'gf_clinic',
        name: 'Medical & Dental Clinic',
        category: 'Medical',
        wing: 'East',
      ),
      Room(
        id: 'gf_midwife',
        name: 'Midwifery Laboratory',
        category: 'Lab',
        wing: 'East',
      ),
      Room(
        id: 'gf_demo',
        name: 'MB 103 / Demo Room',
        category: 'Specialized',
        wing: 'East',
      ),

      // Bottom Row (South)
      Room(
        id: 'gf_avr',
        name: 'Audio Visual Room',
        category: 'Specialized',
        wing: 'East',
      ),
      Room(
        id: 'gf_dance',
        name: 'Dance Studio',
        category: 'Specialized',
        wing: 'East',
      ),
      Room(id: 'gf_ciso', name: 'CISO', category: 'Office', wing: 'East'),
      Room(
        id: 'gf_music',
        name: 'Music Room',
        category: 'Specialized',
        wing: 'East',
      ),
    ];
  }
}
