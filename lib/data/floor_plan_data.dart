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
    // ==========================================
    // TOP ROW ROOMS (y: 0.25 to 0.45)
    // ==========================================
    FloorRoom(
      id: 'guidance_testing',
      name: 'Guidance Testing Center',
      category: 'academic',
      bounds: Rect.fromLTRB(0.00, 0.25, 0.06, 0.45),
      description: 'Testing and assessment center for students',
    ),
    // Notice the gap from 0.06 to 0.09 for the Sub-Lobby
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
    // Notice the gap from 0.92 to 0.95 for the Right Sub-Lobby
    FloorRoom(
      id: 'bseed_sim_1',
      name: 'BSEED Simulation Room',
      category: 'academic',
      bounds: Rect.fromLTRB(0.95, 0.25, 1.00, 0.45),
      description: 'Business simulation room',
    ),

    // ==========================================
    // MAIN HALLWAY GAP (y: 0.45 to 0.52)
    // No rooms are placed here to create the path
    // ==========================================

    // ==========================================
    // BOTTOM ROW ROOMS (y: 0.52 to 0.72)
    // ==========================================
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

    // Protruding Bottom Left Offices
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

    // Center Elevator Block (Breaks the hallway)
    FloorRoom(
      id: 'center_elevator',
      name: 'Elevator',
      category: 'facility',
      bounds: Rect.fromLTRB(0.48, 0.45, 0.54, 0.65),
    ),

    // Protruding Bottom Right Office
    FloorRoom(
      id: 'president_office',
      name: 'Office Of The President',
      category: 'office',
      bounds: Rect.fromLTRB(0.54, 0.52, 0.60, 0.84),
      description: "President's executive office",
    ),

    // Continuing Bottom Row
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

    // ==========================================
    // EXTERIOR AND SPECIAL ZONES
    // ==========================================
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

  static FloorRoom? getRoomAtPosition(Offset normalizedPos) {
    for (final room in secondFloorRooms) {
      if (room.bounds.contains(normalizedPos)) {
        return room;
      }
    }
    return null;
  }
}
