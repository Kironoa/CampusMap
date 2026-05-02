import 'dart:ui';

enum Wing { left, right, center }

enum RoomRow { top, bottom }

enum RoomCategory {
  academic,
  office,
  facility,
  amenity,
  lab,
  classroom,
  institute,
  utility,
  general,
  specialized,
}

class Room {
  final String id;
  final String name;
  final RoomCategory category;
  final Wing wing;
  final RoomRow? row;
  final String? description;
  final Rect? bounds;

  const Room({
    required this.id,
    required this.name,
    required this.category,
    required this.wing,
    this.row,
    this.description,
    this.bounds,
  });

  String get wingName => wing.name[0].toUpperCase() + wing.name.substring(1);
  String get rowName => row != null ? row!.name[0].toUpperCase() + row!.name.substring(1) : '';

  static Wing wingFromString(String wing) {
    switch (wing.toLowerCase()) {
      case 'left':
      case 'west':
        return Wing.left;
      case 'right':
      case 'east':
        return Wing.right;
      default:
        return Wing.center;
    }
  }

  static RoomCategory categoryFromString(String category) {
    switch (category.toLowerCase()) {
      case 'academic':
        return RoomCategory.academic;
      case 'office':
        return RoomCategory.office;
      case 'facility':
        return RoomCategory.facility;
      case 'amenity':
        return RoomCategory.amenity;
      case 'lab':
        return RoomCategory.lab;
      case 'classroom':
        return RoomCategory.classroom;
      case 'institute':
        return RoomCategory.institute;
      case 'utility':
        return RoomCategory.utility;
      case 'general':
        return RoomCategory.general;
      case 'specialized':
        return RoomCategory.specialized;
      default:
        return RoomCategory.general;
    }
  }

  static Color categoryColor(RoomCategory category) {
    switch (category) {
      case RoomCategory.academic:
        return const Color(0xFF2563EB);
      case RoomCategory.office:
        return const Color(0xFFEA580C);
      case RoomCategory.facility:
        return const Color(0xFF16A34A);
      case RoomCategory.amenity:
        return const Color(0xFF7C3AED);
      case RoomCategory.lab:
        return const Color(0xFFDC2626);
      case RoomCategory.classroom:
        return const Color(0xFF0891B2);
      case RoomCategory.institute:
        return const Color(0xFF7C3AED);
      case RoomCategory.utility:
        return const Color(0xFF6B7280);
      case RoomCategory.general:
        return const Color(0xFFF97316);
      case RoomCategory.specialized:
        return const Color(0xFFDB2777);
    }
  }
}
