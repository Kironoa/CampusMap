// lib/features/live_navigation/models/nav_route.dart
//
// Provider-neutral route model. Any routing backend (OSRM today, Valhalla /
// GraphHopper tomorrow) maps its response onto [NavRouteOption] — the
// guidance engine and UI never see provider-specific JSON.
import 'geo_math.dart';

/// One maneuver step of a route (e.g. "Turn right onto Lacaya St").
class NavRouteStep {
  const NavRouteStep({
    required this.instruction,
    required this.maneuver,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.points,
  });

  /// Human-readable instruction text.
  final String instruction;

  /// Short maneuver token (e.g. "turn right"). Used for the banner icon.
  final String maneuver;

  final double distanceMeters;
  final int durationSeconds;

  /// Decoded step polyline (at least the step endpoints).
  final List<NavLatLng> points;

  /// Short label for the maneuver icon (e.g. "Turn right").
  String get maneuverLabel {
    if (maneuver.isEmpty) return 'Continue';
    final words = maneuver
        .toLowerCase()
        .split(RegExp(r'[\s_]+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'Continue';
    return words
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

/// One route option (primary + alternatives when the backend returns them).
class NavRouteOption {
  const NavRouteOption({
    required this.summary,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.overviewPoints,
    required this.steps,
  });

  final String summary;
  final double distanceMeters;
  final int durationSeconds;

  /// Full-route polyline for map display.
  final List<NavLatLng> overviewPoints;
  final List<NavRouteStep> steps;

  bool get hasSteps => steps.isNotEmpty;

  /// Flattens step polylines into a single continuous path used both for
  /// display fallback and guidance tracking.
  List<NavLatLng> get trackingPoints {
    final flat = <NavLatLng>[];
    for (final step in steps) {
      for (final p in step.points) {
        if (flat.isEmpty || flat.last != p) flat.add(p);
      }
    }
    if (flat.length < 2 && overviewPoints.length >= 2) {
      return List.of(overviewPoints);
    }
    return flat;
  }
}
