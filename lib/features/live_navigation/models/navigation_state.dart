// lib/features/live_navigation/models/navigation_state.dart
//
// UI-facing navigation state for the feature. Kept separate from the
// existing app's navigation state so the two systems never mix.
import 'geo_math.dart';

/// Lifecycle phase of the Live Navigation screen.
enum NavPhase {
  /// No destination yet — map + destination picking only.
  idle,

  /// Routes loaded, user picks an option and starts.
  preview,

  /// Actively guiding along the selected route.
  navigating,
}

/// A destination picked on the map or entered as coordinates.
class NavDestination {
  const NavDestination({required this.label, required this.location});

  final String label;
  final NavLatLng location;
}

/// Live trip numbers shown in the navigation HUD.
class TripProgress {
  const TripProgress({
    required this.instruction,
    required this.maneuverLabel,
    required this.distanceToManeuverM,
    required this.remainingDistanceM,
    required this.eta,
    required this.offRoute,
    required this.arrived,
  });

  final String instruction;
  final String maneuverLabel;
  final double distanceToManeuverM;
  final double remainingDistanceM;
  final DateTime eta;
  final bool offRoute;
  final bool arrived;
}
