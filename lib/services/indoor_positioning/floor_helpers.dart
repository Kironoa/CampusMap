// lib/services/indoor_positioning/floor_helpers.dart
import '../room_catalog.dart';

/// Conversion helpers between zero-based floor indexes (0=Ground, 1=2nd,
/// 2=3rd) and human-readable floor names.
///
/// The navigation graph, pathfinder and position model all use zero-based
/// indexes. Never mix the two representations.
class FloorInfo {
  FloorInfo._();

  static const List<String> names = RoomCatalog.floorKeys;

  /// Short labels used in tabs/chips.
  static const List<String> shortNames = ['Ground', '2nd', '3rd'];

  /// Human-readable floor name for a zero-based index.
  static String name(int floorIndex) {
    if (floorIndex < 0 || floorIndex >= names.length) {
      return 'Floor $floorIndex';
    }
    return names[floorIndex];
  }

  /// Zero-based index for a human-readable floor name, or null if unknown.
  static int? indexFromName(String name) {
    final index = names.indexOf(name);
    return index >= 0 ? index : null;
  }

  /// Human-readable floor number (1-based, e.g. "3rd Floor" -> "3rd").
  static String displayNumber(int floorIndex) {
    const suffixes = ['st', 'nd', 'rd', 'th'];
    final n = floorIndex + 1;
    if (n == 1) return '1st';
    if (n == 2) return '2nd';
    if (n == 3) return '3rd';
    final suffix = n % 100 >= 11 && n % 100 <= 13 ? 'th' : suffixes[n % 10];
    return '$n$suffix';
  }
}
