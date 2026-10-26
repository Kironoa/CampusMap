// lib/features/live_navigation/live_navigation.dart
//
// Public entry point for the Live Navigation feature.
//
// Billing-free: MapLibre (OSM data) + device GPS + OSRM routing. No Google
// services, no API keys, no credit card — see README.md.
//
// This feature is intentionally isolated: everything it needs lives under
// lib/features/live_navigation/. To disable it, set
// [LiveNavFeatureFlag.enabled] to false (the HomeScreen entry point hides
// itself). To remove it entirely, delete this folder plus:
//   - the entry card in lib/screens/home_screen.dart
//   - maplibre / geolocator from pubspec.yaml
library live_navigation;

export 'config/campus_buildings.dart';
export 'config/nav_config.dart';
export 'config/nav_theme.dart';
export 'models/geo_math.dart';
export 'models/nav_route.dart';
export 'models/navigation_state.dart';
export 'models/reports/report.dart';
export 'models/reports/report_repository.dart';
export 'providers/geocoding/geocoding_provider.dart';
export 'providers/location/location_provider.dart';
export 'providers/map/map_provider.dart';
export 'providers/routing/routing_service.dart';
export 'services/guidance_engine.dart';
export 'services/nav_errors.dart';
export 'ui/navigation_screen.dart';

/// Kill-switch for the whole feature. When false, the app must behave as if
/// Live Navigation was never added (entry point hidden, no map/GPS/routing
/// usage at runtime).
class LiveNavFeatureFlag {
  LiveNavFeatureFlag._();

  static const bool enabled = true;
}
