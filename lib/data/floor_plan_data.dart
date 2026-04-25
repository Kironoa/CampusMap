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
      bounds: Rect.fromLTRB(0.00, 0.30, 0.08, 0.40),
      description: 'Testing and assessment center for students',
    ),
    FloorRoom(
      id: 'computer_lab',
      name: 'Computer Laboratory',
      category: 'academic',
      bounds: Rect.fromLTRB(0.08, 0.25, 0.20, 0.45),
      description: 'Main computer laboratory with workstations',
    ),
    FloorRoom(
      id: 'computer_room_1',
      name: 'Computer Room 1',
      category: 'academic',
      bounds: Rect.fromLTRB(0.20, 0.25, 0.31, 0.45),
    ),
    FloorRoom(
      id: 'computer_room_2',
      name: 'Computer Room 2',
      category: 'academic',
      bounds: Rect.fromLTRB(0.31, 0.25, 0.42, 0.45),
    ),
    FloorRoom(
      id: 'computer_room_3',
      name: 'Computer Room 3',
      category: 'academic',
      bounds: Rect.fromLTRB(0.42, 0.25, 0.53, 0.45),
    ),
    FloorRoom(
      id: 'guidance_counseling',
      name: 'Guidance Counseling Room',
      category: 'office',
      bounds: Rect.fromLTRB(0.00, 0.50, 0.08, 0.65),
      description: 'Student counseling and guidance services',
    ),
    FloorRoom(
      id: 'moot_court',
      name: 'Moot Court',
      category: 'academic',
      bounds: Rect.fromLTRB(0.08, 0.50, 0.23, 0.65),
      description: 'Mock court room for legal studies',
    ),
    FloorRoom(
      id: 'business_center',
      name: 'Business Center',
      category: 'academic',
      bounds: Rect.fromLTRB(0.23, 0.50, 0.33, 0.65),
      description: 'Business education resource center',
    ),
    FloorRoom(
      id: 'classroom_1',
      name: 'Classroom 1',
      category: 'academic',
      bounds: Rect.fromLTRB(0.33, 0.50, 0.44, 0.65),
    ),
    FloorRoom(
      id: 'classroom_2',
      name: 'Classroom 2',
      category: 'academic',
      bounds: Rect.fromLTRB(0.44, 0.50, 0.55, 0.65),
    ),
    FloorRoom(
      id: 'classroom_3',
      name: 'Classroom 3',
      category: 'academic',
      bounds: Rect.fromLTRB(0.55, 0.50, 0.66, 0.65),
    ),
    FloorRoom(
      id: 'main_stage',
      name: 'Main Stage',
      category: 'facility',
      bounds: Rect.fromLTRB(0.35, 0.00, 0.60, 0.25),
      description: 'Main auditorium stage for events',
    ),
    FloorRoom(
      id: 'vip_lounge',
      name: 'V.I.P. Lounge',
      category: 'facility',
      bounds: Rect.fromLTRB(0.35, 0.25, 0.60, 0.40),
      description: 'VIP seating and waiting area',
    ),
    FloorRoom(
      id: 'board_room',
      name: 'Board Room',
      category: 'office',
      bounds: Rect.fromLTRB(0.49, 0.50, 0.59, 0.65),
      description: 'Board meetings and conferences',
    ),
    FloorRoom(
      id: 'deans_office',
      name: "Dean's Office",
      category: 'office',
      bounds: Rect.fromLTRB(0.40, 0.60, 0.50, 0.75),
      description: "Office of the Academic Dean",
    ),
    FloorRoom(
      id: 'vp_academic',
      name: 'VP for Academic Affairs',
      category: 'office',
      bounds: Rect.fromLTRB(0.40, 0.75, 0.50, 0.90),
      description: 'Vice President for Academic Affairs office',
    ),
    FloorRoom(
      id: 'president_office',
      name: 'Office of the President',
      category: 'office',
      bounds: Rect.fromLTRB(0.50, 0.60, 0.60, 0.90),
      description: "President's executive office",
    ),
    FloorRoom(
      id: 'faculty_lounge',
      name: 'Faculty and Staff Lounge',
      category: 'office',
      bounds: Rect.fromLTRB(0.60, 0.25, 0.78, 0.45),
      description: 'Lounge area for faculty and staff',
    ),
    FloorRoom(
      id: 'speech_lab',
      name: 'Speech Lab',
      category: 'academic',
      bounds: Rect.fromLTRB(0.78, 0.25, 0.91, 0.45),
      description: 'Communication and speech laboratory',
    ),
    FloorRoom(
      id: 'bseed_sim_1',
      name: 'BSEED Simulation Room 1',
      category: 'academic',
      bounds: Rect.fromLTRB(0.91, 0.25, 1.00, 0.45),
      description: 'Business simulation room',
    ),
    FloorRoom(
      id: 'bseed_sim_2',
      name: 'BSEED Simulation Room 2',
      category: 'academic',
      bounds: Rect.fromLTRB(0.91, 0.45, 1.00, 0.65),
      description: 'Business simulation room',
    ),
    FloorRoom(
      id: 'hr_office',
      name: 'HR Management Office',
      category: 'office',
      bounds: Rect.fromLTRB(0.60, 0.50, 0.70, 0.65),
      description: 'Human Resources Management office',
    ),
    FloorRoom(
      id: 'faculty_room',
      name: 'Faculty Room',
      category: 'office',
      bounds: Rect.fromLTRB(0.70, 0.50, 0.80, 0.65),
      description: 'Faculty collaboration room',
    ),
    FloorRoom(
      id: 'supply_office',
      name: 'Supply Office',
      category: 'office',
      bounds: Rect.fromLTRB(0.80, 0.50, 0.88, 0.65),
      description: 'Supply and logistics office',
    ),
    FloorRoom(
      id: 'vp_planning',
      name: 'VP for Planning',
      category: 'office',
      bounds: Rect.fromLTRB(0.88, 0.50, 0.94, 0.65),
      description: 'Vice President for Planning office',
    ),
    FloorRoom(
      id: 'exec_vp',
      name: 'Executive VP Office',
      category: 'office',
      bounds: Rect.fromLTRB(0.94, 0.50, 1.00, 0.65),
      description: 'Executive Vice President office',
    ),
    FloorRoom(
      id: 'restroom_1',
      name: 'Restroom 1',
      category: 'amenity',
      bounds: Rect.fromLTRB(0.08, 0.65, 0.15, 0.75),
    ),
    FloorRoom(
      id: 'restroom_2',
      name: 'Restroom 2',
      category: 'amenity',
      bounds: Rect.fromLTRB(0.30, 0.65, 0.37, 0.75),
    ),
    FloorRoom(
      id: 'restroom_3',
      name: 'Restroom 3',
      category: 'amenity',
      bounds: Rect.fromLTRB(0.50, 0.65, 0.57, 0.75),
    ),
    FloorRoom(
      id: 'restroom_4',
      name: 'Restroom 4',
      category: 'amenity',
      bounds: Rect.fromLTRB(0.75, 0.65, 0.82, 0.75),
    ),
    FloorRoom(
      id: 'staircase_west',
      name: 'West Staircase',
      category: 'amenity',
      bounds: Rect.fromLTRB(0.00, 0.40, 0.05, 0.50),
    ),
    FloorRoom(
      id: 'staircase_east',
      name: 'East Staircase',
      category: 'amenity',
      bounds: Rect.fromLTRB(0.95, 0.40, 1.00, 0.50),
    ),
    FloorRoom(
      id: 'deck_canopy',
      name: 'Deck Canopy',
      category: 'facility',
      bounds: Rect.fromLTRB(0.40, 0.90, 0.60, 1.00),
      description: 'Outdoor covered deck area',
    ),
    FloorRoom(
      id: 'safe_area',
      name: 'Safe Area / Exit',
      category: 'amenity',
      bounds: Rect.fromLTRB(0.00, 0.65, 0.05, 0.75),
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