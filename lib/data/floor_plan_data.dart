import 'package:naviapp/models/room.dart';
import 'package:naviapp/data/ground_floor.dart';
import 'package:naviapp/data/second_floor.dart';
import 'package:naviapp/data/third_floor.dart';

/// Central manager for all TCGC floor plan data.
/// Floor 0 = Ground / First Floor (physically the same level)
/// Floor 1 = Second Floor
/// Floor 2 = Third Floor
class FloorPlanData {
  // Floor 0: Ground / First Floor (same physical level)
  static List<Room> get groundFloorRooms => GroundFloorData.getRooms();

  // Floor 1: Second Floor
  static List<Room> get secondFloorRooms => SecondFloorData.getRooms();

  // Floor 2: Third Floor
  static List<Room> get thirdFloorRooms => ThirdFloorData.getRooms();

  /// Returns the correct room list for the given floor index (0, 1, or 2).
  static List<Room> getRoomsForFloor(int floorIndex) {
    switch (floorIndex) {
      case 0:
        return groundFloorRooms;
      case 1:
        return secondFloorRooms;
      case 2:
        return thirdFloorRooms;
      default:
        return groundFloorRooms;
    }
  }

  /// Returns the asset image path for the given floor index.
  static String getImageAssetForFloor(int floorIndex) {
    switch (floorIndex) {
      case 0:
        return 'assets/images/ground_floor.png';
      case 1:
        return 'assets/images/second_floor.png';
      case 2:
        return 'assets/images/third_floor.png';
      default:
        return 'assets/images/ground_floor.png';
    }
  }

  /// Returns the display name for the given floor index.
  static String getFloorName(int floorIndex) {
    switch (floorIndex) {
      case 0:
        return 'Ground / First Floor';
      case 1:
        return 'Second Floor';
      case 2:
        return 'Third Floor';
      default:
        return 'Ground / First Floor';
    }
  }

  /// Finds a room by its ID across all floors.
  static Room? getRoomById(String roomId) {
    for (final floor in [groundFloorRooms, secondFloorRooms, thirdFloorRooms]) {
      for (final room in floor) {
        if (room.id == roomId) return room;
      }
    }
    return null;
  }

  /// Finds a room at a normalized position (0.0–1.0) on the given floor.
  static Room? getRoomAtPosition(int floorIndex, double x, double y) {
    final rooms = getRoomsForFloor(floorIndex);
    final nx = x.clamp(0.0, 1.0);
    final ny = y.clamp(0.0, 1.0);
    for (final room in rooms) {
      if (room.bounds != null &&
          nx >= room.bounds!.left &&
          nx <= room.bounds!.right &&
          ny >= room.bounds!.top &&
          ny <= room.bounds!.bottom) {
        return room;
      }
    }
    return null;
  }
}
