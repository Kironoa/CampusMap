import 'dart:ui';
import 'package:naviapp/models/room.dart';

class ThirdFloorData {
  static List<Room> getRooms() {
    return [
      // --- CENTRAL AREA (Floor 2) ---
      Room(
        id: 'tf_main_stage',
        name: 'Main Stage',
        category: RoomCategory.general,
        wing: Wing.center,
        row: RoomRow.top,
        bounds: Rect.fromLTRB(0.46, 0.10, 0.60, 0.25),
      ),
      Room(
        id: 'tf_activity_area',
        name: 'Activity Area',
        category: RoomCategory.general,
        wing: Wing.center,
        row: RoomRow.top,
        bounds: Rect.fromLTRB(0.60, 0.10, 0.70, 0.25),
      ),
      Room(
        id: 'tf_prayer_room',
        name: 'Prayer Room',
        category: RoomCategory.specialized,
        wing: Wing.center,
        row: RoomRow.top,
        bounds: Rect.fromLTRB(0.70, 0.10, 0.80, 0.25),
      ),
      Room(
        id: 'tf_research',
        name: 'Research Extension Development',
        category: RoomCategory.office,
        wing: Wing.center,
        row: RoomRow.top,
        bounds: Rect.fromLTRB(0.80, 0.10, 0.92, 0.25),
      ),
      Room(
        id: 'tf_elevator',
        name: 'Elevator',
        category: RoomCategory.utility,
        wing: Wing.center,
        bounds: Rect.fromLTRB(0.48, 0.45, 0.54, 0.65),
      ),
      Room(
        id: 'tf_rest_room1',
        name: 'Rest Room 1',
        category: RoomCategory.utility,
        wing: Wing.center,
        row: RoomRow.top,
        bounds: Rect.fromLTRB(0.60, 0.25, 0.62, 0.45),
      ),
      Room(
        id: 'tf_rest_room2',
        name: 'Rest Room 2',
        category: RoomCategory.utility,
        wing: Wing.center,
        row: RoomRow.top,
        bounds: Rect.fromLTRB(0.62, 0.25, 0.64, 0.45),
      ),

      // --- WEST WING (LEFT SIDE) (Floor 2) ---
      Room(
        id: 'tf_library',
        name: 'Library',
        category: RoomCategory.academic,
        wing: Wing.left,
        row: RoomRow.top,
        bounds: Rect.fromLTRB(0.00, 0.25, 0.18, 0.45),
      ),
      Room(
        id: 'tf_lrc1',
        name: 'LRC Extension 1',
        category: RoomCategory.academic,
        wing: Wing.left,
        row: RoomRow.top,
        bounds: Rect.fromLTRB(0.18, 0.25, 0.28, 0.45),
      ),
      Room(
        id: 'tf_lrc2',
        name: 'LRC Extension 2',
        category: RoomCategory.academic,
        wing: Wing.left,
        row: RoomRow.top,
        bounds: Rect.fromLTRB(0.28, 0.25, 0.38, 0.45),
      ),

      // --- EAST WING (RIGHT SIDE) (Floor 2) ---
      Room(
        id: 'tf_class1',
        name: 'Classroom 1',
        category: RoomCategory.classroom,
        wing: Wing.right,
        row: RoomRow.bottom,
        bounds: Rect.fromLTRB(0.64, 0.52, 0.72, 0.72),
      ),
      Room(
        id: 'tf_class2',
        name: 'Classroom 2',
        category: RoomCategory.classroom,
        wing: Wing.right,
        row: RoomRow.bottom,
        bounds: Rect.fromLTRB(0.72, 0.52, 0.78, 0.72),
      ),
      Room(
        id: 'tf_class3',
        name: 'Classroom 3',
        category: RoomCategory.classroom,
        wing: Wing.right,
        row: RoomRow.bottom,
        bounds: Rect.fromLTRB(0.78, 0.52, 0.84, 0.72),
      ),
      Room(
        id: 'tf_class4',
        name: 'Classroom 4',
        category: RoomCategory.classroom,
        wing: Wing.right,
        row: RoomRow.bottom,
        bounds: Rect.fromLTRB(0.84, 0.52, 0.90, 0.72),
      ),
      Room(
        id: 'tf_class5',
        name: 'Classroom 5',
        category: RoomCategory.classroom,
        wing: Wing.right,
        row: RoomRow.bottom,
        bounds: Rect.fromLTRB(0.90, 0.52, 0.96, 0.72),
      ),
      Room(
        id: 'tf_science_lab',
        name: 'Science Laboratory',
        category: RoomCategory.lab,
        wing: Wing.right,
        row: RoomRow.bottom,
        bounds: Rect.fromLTRB(0.96, 0.52, 1.00, 0.72),
      ),
      Room(
        id: 'tf_class6',
        name: 'Classroom 6',
        category: RoomCategory.classroom,
        wing: Wing.right,
        row: RoomRow.bottom,
        bounds: Rect.fromLTRB(0.96, 0.72, 1.00, 0.90),
      ),

      // --- BLEACHERS AREA ---
      Room(
        id: 'tf_bleachers_west',
        name: 'West Bleachers',
        category: RoomCategory.general,
        wing: Wing.left,
        row: RoomRow.top,
        bounds: Rect.fromLTRB(0.82, 0.25, 1.00, 0.45),
      ),
      Room(
        id: 'tf_bleachers_east',
        name: 'East Bleachers',
        category: RoomCategory.general,
        wing: Wing.right,
        row: RoomRow.bottom,
        bounds: Rect.fromLTRB(0.82, 0.72, 1.00, 0.90),
      ),
    ];
  }
}
