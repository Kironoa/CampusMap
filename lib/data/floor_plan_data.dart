import 'dart:ui';

class FloorRoom {
  final String id;
  final String name;
  final String category;
  final Rect bounds;
  final String? description;

  const FloorRoom({
    required this.id,
    required this.name,
    required this.category,
    required this.bounds,
    this.description,
  });
}

class FloorPlanData {
  static const List<FloorRoom> secondFloorRooms = [
    FloorRoom(
      id: 'guidance_testing',
      name: 'Guidance Testing Center',
      category: 'academic',
      bounds: Rect.fromLTRB(0.00, 0.25, 0.06, 0.45),
      description: 'Testing and assessment center for students',
    ),
    FloorRoom(
      id: 'computer_lab',
      name: 'Computer Laboratory',
      category: 'academic',
      bounds: Rect.fromLTRB(0.09, 0.25, 0.21, 0.45),
      description: 'Main computer laboratory with workstations',
    ),
    FloorRoom(
      id: 'computer_room_1',
      name: 'Computer Room 1',
      category: 'academic',
      bounds: Rect.fromLTRB(0.21, 0.25, 0.28, 0.45),
    ),
    FloorRoom(
      id: 'computer_room_2',
      name: 'Computer Room 2',
      category: 'academic',
      bounds: Rect.fromLTRB(0.28, 0.25, 0.35, 0.45),
    ),
    FloorRoom(
      id: 'computer_room_3',
      name: 'Computer Room 3',
      category: 'academic',
      bounds: Rect.fromLTRB(0.35, 0.25, 0.42, 0.45),
    ),
    FloorRoom(
      id: 'restroom_1',
      name: 'Rest\nRoom',
      category: 'amenity',
      bounds: Rect.fromLTRB(0.42, 0.25, 0.44, 0.45),
    ),
    FloorRoom(
      id: 'restroom_2',
      name: 'Rest\nRoom',
      category: 'amenity',
      bounds: Rect.fromLTRB(0.44, 0.25, 0.46, 0.45),
    ),
    FloorRoom(
      id: 'vip_lounge',
      name: 'V.I.P. Lounge',
      category: 'facility',
      bounds: Rect.fromLTRB(0.46, 0.25, 0.60, 0.45),
      description: 'VIP seating and waiting area',
    ),
    FloorRoom(
      id: 'restroom_3',
      name: 'Rest\nRoom',
      category: 'amenity',
      bounds: Rect.fromLTRB(0.60, 0.25, 0.62, 0.45),
    ),
    FloorRoom(
      id: 'restroom_4',
      name: 'Rest\nRoom',
      category: 'amenity',
      bounds: Rect.fromLTRB(0.62, 0.25, 0.64, 0.45),
    ),
    FloorRoom(
      id: 'faculty_lounge',
      name: 'Faculty and Staff Lounge',
      category: 'office',
      bounds: Rect.fromLTRB(0.64, 0.25, 0.77, 0.45),
      description: 'Lounge area for faculty and staff',
    ),
    FloorRoom(
      id: 'speech_lab',
      name: 'Speech Lab',
      category: 'academic',
      bounds: Rect.fromLTRB(0.77, 0.25, 0.92, 0.45),
      description: 'Communication and speech laboratory',
    ),
    FloorRoom(
      id: 'bseed_sim_1',
      name: 'BSEED Simulation Room',
      category: 'academic',
      bounds: Rect.fromLTRB(0.95, 0.25, 1.00, 0.45),
      description: 'Business simulation room',
    ),
    FloorRoom(
      id: 'guidance_counseling',
      name: 'Guidance Counseling Room',
      category: 'office',
      bounds: Rect.fromLTRB(0.00, 0.52, 0.06, 0.72),
      description: 'Student counseling and guidance services',
    ),
    FloorRoom(
      id: 'staircase_west',
      name: 'Stairs',
      category: 'amenity',
      bounds: Rect.fromLTRB(0.06, 0.52, 0.09, 0.72),
    ),
    FloorRoom(
      id: 'moot_court',
      name: 'Moot Court',
      category: 'academic',
      bounds: Rect.fromLTRB(0.09, 0.52, 0.21, 0.72),
      description: 'Mock court room for legal studies',
    ),
    FloorRoom(
      id: 'business_center',
      name: 'Business Center',
      category: 'academic',
      bounds: Rect.fromLTRB(0.21, 0.52, 0.28, 0.72),
      description: 'Business education resource center',
    ),
    FloorRoom(
      id: 'classroom_1',
      name: 'Classroom',
      category: 'academic',
      bounds: Rect.fromLTRB(0.28, 0.52, 0.35, 0.72),
    ),
    FloorRoom(
      id: 'classroom_2',
      name: 'Class Room',
      category: 'academic',
      bounds: Rect.fromLTRB(0.35, 0.52, 0.42, 0.72),
    ),
    FloorRoom(
      id: 'deans_office',
      name: "Deans Office",
      category: 'office',
      bounds: Rect.fromLTRB(0.42, 0.52, 0.48, 0.68),
      description: "Office of the Academic Dean",
    ),
    FloorRoom(
      id: 'vp_academic',
      name: 'VP For Academic Affairs',
      category: 'office',
      bounds: Rect.fromLTRB(0.42, 0.68, 0.48, 0.84),
      description: 'Vice President for Academic Affairs office',
    ),
    FloorRoom(
      id: 'center_elevator',
      name: 'Elevator',
      category: 'facility',
      bounds: Rect.fromLTRB(0.48, 0.45, 0.54, 0.65),
    ),
    FloorRoom(
      id: 'president_office',
      name: 'Office Of The President',
      category: 'office',
      bounds: Rect.fromLTRB(0.54, 0.52, 0.60, 0.84),
      description: "President's executive office",
    ),
    FloorRoom(
      id: 'board_room',
      name: 'Board Room',
      category: 'office',
      bounds: Rect.fromLTRB(0.60, 0.52, 0.66, 0.72),
      description: 'Board meetings and conferences',
    ),
    FloorRoom(
      id: 'hr_office',
      name: 'Human Resource Management Office',
      category: 'office',
      bounds: Rect.fromLTRB(0.66, 0.52, 0.72, 0.72),
      description: 'Human Resources Management office',
    ),
    FloorRoom(
      id: 'faculty_room',
      name: 'Faculty Room',
      category: 'office',
      bounds: Rect.fromLTRB(0.72, 0.52, 0.78, 0.72),
      description: 'Faculty collaboration room',
    ),
    FloorRoom(
      id: 'supply_office',
      name: 'Supply Office',
      category: 'office',
      bounds: Rect.fromLTRB(0.78, 0.52, 0.83, 0.72),
      description: 'Supply and logistics office',
    ),
    FloorRoom(
      id: 'vp_planning',
      name: 'VP For Planning',
      category: 'office',
      bounds: Rect.fromLTRB(0.83, 0.52, 0.88, 0.72),
      description: 'Vice President for Planning office',
    ),
    FloorRoom(
      id: 'exec_vp',
      name: 'Executive Vice President Office',
      category: 'office',
      bounds: Rect.fromLTRB(0.88, 0.52, 0.92, 0.72),
      description: 'Executive Vice President office',
    ),
    FloorRoom(
      id: 'staircase_east',
      name: 'Stairs',
      category: 'amenity',
      bounds: Rect.fromLTRB(0.92, 0.52, 0.95, 0.72),
    ),
    FloorRoom(
      id: 'bseed_sim_2',
      name: 'BSEED Simulation Room',
      category: 'academic',
      bounds: Rect.fromLTRB(0.95, 0.52, 1.00, 0.72),
      description: 'Business simulation room',
    ),
    FloorRoom(
      id: 'main_stage',
      name: 'MAIN STAGE',
      category: 'facility',
      bounds: Rect.fromLTRB(0.46, 0.10, 0.60, 0.25),
      description: 'Main auditorium stage for events',
    ),
    FloorRoom(
      id: 'deck_canopy',
      name: 'DECK CANOPY',
      category: 'facility',
      bounds: Rect.fromLTRB(0.46, 0.84, 0.56, 1.00),
      description: 'Outdoor covered deck area',
    ),
    FloorRoom(
      id: 'safe_area',
      name: 'Safe Area / Exit',
      category: 'amenity',
      bounds: Rect.fromLTRB(0.05, 0.78, 0.10, 0.88),
      description: 'Emergency exit and safe area',
    ),
  ];

  static const List<FloorRoom> groundFloorRooms = [
    FloorRoom(
      id: 'library',
      name: 'LIBRARY',
      category: 'amenity',
      bounds: Rect.fromLTRB(0.00, 0.25, 0.18, 0.45),
      description: 'Campus Library',
    ),
    FloorRoom(
      id: 'icje',
      name: 'INSTITUTE OF\nCRIMINAL JUSTICE',
      category: 'academic',
      bounds: Rect.fromLTRB(0.00, 0.52, 0.15, 0.72),
      description: 'Institute of Criminal Justice Education',
    ),
    FloorRoom(
      id: 'criminology_lab',
      name: 'CRIMINOLOGY\nLABORATORY',
      category: 'academic',
      bounds: Rect.fromLTRB(0.15, 0.52, 0.25, 0.72),
      description: 'Criminology Laboratory',
    ),
    FloorRoom(
      id: 'vp_admin_finance',
      name: 'VP ADMIN\nAND FINANCE',
      category: 'office',
      bounds: Rect.fromLTRB(0.25, 0.52, 0.35, 0.72),
      description: 'VP Admin and Finance Office',
    ),
    FloorRoom(
      id: 'registrar',
      name: "REGISTRAR'S\nOFFICE",
      category: 'office',
      bounds: Rect.fromLTRB(0.35, 0.52, 0.42, 0.72),
      description: "Registrar's Office",
    ),
    FloorRoom(
      id: 'main_lobby',
      name: 'MAIN LOBBY',
      category: 'facility',
      bounds: Rect.fromLTRB(0.42, 0.45, 0.50, 0.65),
      description: 'Main entry lobby - Navigation start point',
    ),
    FloorRoom(
      id: 'elevator_core',
      name: 'ELEVATOR',
      category: 'facility',
      bounds: Rect.fromLTRB(0.50, 0.45, 0.54, 0.65),
    ),
    FloorRoom(
      id: 'ics',
      name: 'INSTITUTE OF\nCOMPUTER STUDIES',
      category: 'academic',
      bounds: Rect.fromLTRB(0.54, 0.52, 0.68, 0.72),
      description: 'Institute of Computer Studies',
    ),
    FloorRoom(
      id: 'tcgc_training',
      name: 'TCGC DEV\'T\nTRAINING CTR',
      category: 'academic',
      bounds: Rect.fromLTRB(0.68, 0.52, 0.78, 0.72),
      description: 'TCGC Development Training Center',
    ),
    FloorRoom(
      id: 'health_sciences',
      name: 'INSTITUTE OF\nHEALTH SCIENCES',
      category: 'academic',
      bounds: Rect.fromLTRB(0.78, 0.52, 0.92, 0.72),
      description: 'Institute of Health Sciences',
    ),
    FloorRoom(
      id: 'bleachers',
      name: 'BLEACHERS /\nMAIN STAGE',
      category: 'facility',
      bounds: Rect.fromLTRB(0.82, 0.25, 1.00, 0.45),
      description: 'Bleachers and Main Stage Area',
    ),
    FloorRoom(
      id: 'safe_area_ground',
      name: 'SAFE AREA',
      category: 'amenity',
      bounds: Rect.fromLTRB(0.08, 0.78, 0.14, 0.88),
      description: 'Emergency evacuation safe area',
    ),
  ];

  static FloorRoom? getRoomAtPosition(Offset normalizedPos, {bool secondFloor = true}) {
    final rooms = secondFloor ? secondFloorRooms : groundFloorRooms;
    for (final room in rooms) {
      if (room.bounds.contains(normalizedPos)) {
        return room;
      }
    }
    return null;
  }

  static Offset get mainLobbyPosition => const Offset(0.46, 0.55);

  static Offset get safeAreaPosition => const Offset(0.11, 0.83);
}