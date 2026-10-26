// lib/config/staircase_locations.dart
import '../models/starting_location.dart';
import 'starting_locations.dart';

/// Canonical staircase list per floor.
///
/// Every entry points at a configured [StartingLocation], so the label drawn
/// on the floor plan and the QR code generated for that staircase resolve to
/// exactly the same spot. Only real staircases are listed (entrances, side
/// doors and the elevator are excluded).
class StaircaseLocations {
  StaircaseLocations._();

  /// Starting-location IDs for each floor index (0 = Ground Floor).
  static const Map<int, List<String>> idsByFloor = {
    0: [
      'GF_LOBBY_LEFT_STAIRCASE',
      'GF_LOBBY_RIGHT_STAIRCASE',
      'GF_LEFT_WING_STAIRCASE',
      'GF_RIGHT_WING_STAIRCASE',
    ],
    1: [
      'SF_LEFT_STAIRCASE',
      'SF_CENTER_STAIRCASE',
      'SF_RIGHT_STAIRCASE',
      'SF_BOTTOM_LEFT_STAIRCASE',
      'SF_BOTTOM_RIGHT_STAIRCASE',
    ],
    2: ['TF_LEFT_STAIRCASE', 'TF_RIGHT_STAIRCASE', 'TF_TOP_LEFT_STAIRCASE'],
  };

  /// Resolved staircase locations for [floor], in label-drawing order.
  static List<StartingLocation> forFloor(int floor) {
    final ids = idsByFloor[floor] ?? const <String>[];
    final locations = <StartingLocation>[];
    for (final id in ids) {
      final location = StartingLocations.byId(id);
      if (location != null) locations.add(location);
    }
    return locations;
  }

  /// Display label for a staircase, hiding legacy bookkeeping suffixes.
  static String labelFor(StartingLocation location) =>
      location.name.replaceFirst(' (Legacy)', '');
}
