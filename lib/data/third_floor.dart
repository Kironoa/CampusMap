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

class ThirdFloorData {
  static List<Room> getRooms() {
    return [
      // --- CENTRAL AREA ---
      Room(
        id: 'tf_main_stage',
        name: 'Main Stage',
        category: 'General',
        wing: 'Center',
      ),
      Room(
        id: 'tf_activity_area',
        name: 'Activity Area',
        category: 'General',
        wing: 'Center',
      ),
      Room(
        id: 'tf_prayer_room',
        name: 'Prayer Room',
        category: 'Specialized',
        wing: 'Center',
      ),
      Room(
        id: 'tf_research',
        name: 'Research Extension Development',
        category: 'Office',
        wing: 'Center',
      ),
      Room(
        id: 'tf_elevator',
        name: 'Elevator',
        category: 'Utility',
        wing: 'Center',
      ),
      Room(
        id: 'tf_rest_room1',
        name: 'Rest Room 1',
        category: 'Utility',
        wing: 'Center',
      ),
      Room(
        id: 'tf_rest_room2',
        name: 'Rest Room 2',
        category: 'Utility',
        wing: 'Center',
      ),

      // --- WEST WING (LEFT SIDE) ---
      Room(
        id: 'tf_library',
        name: 'Library',
        category: 'Academic',
        wing: 'West',
      ),
      Room(
        id: 'tf_lrc1',
        name: 'LRC Extension 1',
        category: 'Academic',
        wing: 'West',
      ),
      Room(
        id: 'tf_lrc2',
        name: 'LRC Extension 2',
        category: 'Academic',
        wing: 'West',
      ),

      // --- EAST WING (RIGHT SIDE) ---
      Room(
        id: 'tf_class1',
        name: 'Classroom 1',
        category: 'Classroom',
        wing: 'East',
      ),
      Room(
        id: 'tf_class2',
        name: 'Classroom 2',
        category: 'Classroom',
        wing: 'East',
      ),
      Room(
        id: 'tf_class3',
        name: 'Classroom 3',
        category: 'Classroom',
        wing: 'East',
      ),
      Room(
        id: 'tf_class4',
        name: 'Classroom 4',
        category: 'Classroom',
        wing: 'East',
      ),
      Room(
        id: 'tf_class5',
        name: 'Classroom 5',
        category: 'Classroom',
        wing: 'East',
      ),
      Room(
        id: 'tf_science_lab',
        name: 'Science Laboratory',
        category: 'Lab',
        wing: 'East',
      ),
      Room(
        id: 'tf_class6',
        name: 'Classroom 6',
        category: 'Classroom',
        wing: 'East',
      ),

      // --- BLEACHERS AREA ---
      Room(
        id: 'tf_bleachers_west',
        name: 'West Bleachers',
        category: 'General',
        wing: 'West',
      ),
      Room(
        id: 'tf_bleachers_east',
        name: 'East Bleachers',
        category: 'General',
        wing: 'East',
      ),
    ];
  }
}
