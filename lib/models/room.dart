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
    const map = {
      'left': Wing.left,
      'west': Wing.left,
      'right': Wing.right,
      'east': Wing.right,
    };
    return map[wing.toLowerCase()] ?? Wing.center;
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
    const map = {
      RoomCategory.academic: Color(0xFF0F766E),
      RoomCategory.office: Color(0xFF0A7040),
      RoomCategory.facility: Color(0xFF16A34A),
      RoomCategory.amenity: Color(0xFF65A30D),
      RoomCategory.lab: Color(0xFFDC2626),
      RoomCategory.classroom: Color(0xFF0D9488),
      RoomCategory.institute: Color(0xFF2F855A),
      RoomCategory.utility: Color(0xFF6B7280),
      RoomCategory.general: Color(0xFF0A5C40),
      RoomCategory.specialized: Color(0xFF0E8A5F),
    };
    return map[category]!;
  }
}
