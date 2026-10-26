// lib/features/live_navigation/config/nav_config.dart
//
// Central configuration for Live Navigation. No secrets, no API keys.
//
// Map tiles:
//   Default style is Esri World Imagery (satellite): keyless raster tiles,
//   handy for development, but a shared public resource — respect fair use
//   and keep the Esri attribution chip visible.
//   Point MAP_STYLE_URL at your own style for real use (e.g. a self-hosted
//   tileserver-gl instance serving OpenMapTiles, or any MapLibre-compatible
//   vector/raster style you are allowed to use). The layers button in the
//   app cycles Satellite → Streets → Bright → Light.
//
// Routing:
//   Default is the public OSRM demo server (shared, rate-limited, no SLA).
//   Point OSRM_BASE_URL at your own OSRM instance for real use. Any server
//   speaking the OSRM v1 route API works (swap via [RoutingService]).
import '../models/geo_math.dart';

class NavConfig {
  NavConfig._();

  /// MapLibre style document URL (JSON) or inline style JSON.
  /// Override per build: --dart-define=MAP_STYLE_URL=<url-or-json>
  /// (added as a "Custom" entry ahead of the built-in presets).
  static String get mapStyleUrl {
    const custom = String.fromEnvironment('MAP_STYLE_URL');
    if (custom.isNotEmpty) return custom;
    return navStylePresets().first.url;
  }

  /// Base URL of an OSRM v1 compatible route server (no trailing slash).
  /// Override per build: --dart-define=OSRM_BASE_URL=<url>
  static const String osrmBaseUrl = String.fromEnvironment(
    'OSRM_BASE_URL',
    defaultValue: 'https://router.project-osrm.org',
  );

  // --- Tuning thresholds (performance / quota guards) ---------------------

  /// GPS fixes are processed at most this often for guidance math.
  static const Duration minGuidanceInterval = Duration(seconds: 1);

  /// Lateral distance (meters) from the remaining route that counts as
  /// "possibly off-route" for a single fix.
  static const double offRouteDeviationMeters = 60.0;

  /// Consecutive off-route fixes required before a reroute is requested.
  static const int offRouteFixesRequired = 3;

  /// Minimum time between automatic reroute requests (server-friendly).
  static const Duration rerouteCooldown = Duration(seconds: 45);

  /// Distance (meters) to the final destination that counts as "arrived".
  static const double arrivalRadiusMeters = 30.0;

  /// Assumed speed (m/s) when GPS speed is unavailable, for ETA estimates.
  static const double fallbackSpeedMps = 8.0;

  /// HTTP timeout for routing API calls.
  static const Duration apiTimeout = Duration(seconds: 15);

  /// Fallback camera target (Tangub City) before the first GPS fix.
  static const NavLatLng fallbackCenter = NavLatLng(8.0625, 123.7458);
}

/// One selectable map appearance: a style URL or an inline style JSON
/// document (both are accepted by the MapLibre plugin).
class MapStylePreset {
  const MapStylePreset(this.name, this.url);

  final String name;
  final String url;
}

/// Keyless Esri World Imagery raster style (inline JSON — no account, no
/// token). Attribution "Imagery © Esri, Maxar, Earthstar Geographics" is
/// embedded in the source AND shown in the on-map credit chip.
const String satelliteStyleJson = '''
{
  "version": 8,
  "name": "Esri World Imagery",
  "sources": {
    "esri-world-imagery": {
      "type": "raster",
      "tiles": [
        "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"
      ],
      "tileSize": 256,
      "maxzoom": 19,
      "attribution": "Imagery © Esri, Maxar, Earthstar Geographics"
    }
  },
  "layers": [
    {
      "id": "esri-world-imagery",
      "type": "raster",
      "source": "esri-world-imagery"
    }
  ]
}
''';

/// Keyless OpenTopoMap terrain style (inline JSON — no account, no token).
/// Attribution "© OpenStreetMap contributors, © OpenTopoMap (CC-BY-SA)" is
/// embedded in the source.
const String terrainStyleJson = '''
{
  "version": 8,
  "name": "OpenTopoMap",
  "sources": {
    "opentopomap": {
      "type": "raster",
      "tiles": [
        "https://tile.opentopomap.org/{z}/{x}/{y}.png"
      ],
      "tileSize": 256,
      "maxzoom": 17,
      "attribution": "© OpenStreetMap contributors, © OpenTopoMap (CC-BY-SA)"
    }
  },
  "layers": [
    {
      "id": "opentopomap",
      "type": "raster",
      "source": "opentopomap"
    }
  ]
}
''';

/// Built-in appearances, cycled by the style button in the app.
/// Satellite is first, so it is the default map. Vector street styles are
/// keyless OpenFreeMap services — free, respect fair use.
/// A custom MAP_STYLE_URL build define is inserted first as "Custom".
List<MapStylePreset> navStylePresets() {
  const custom = String.fromEnvironment('MAP_STYLE_URL');
  return [
    if (custom.isNotEmpty) const MapStylePreset('Custom', custom),
    const MapStylePreset('Satellite', satelliteStyleJson),
    const MapStylePreset('Terrain', terrainStyleJson),
    const MapStylePreset(
      'Streets',
      'https://tiles.openfreemap.org/styles/liberty',
    ),
    const MapStylePreset(
      'Bright',
      'https://tiles.openfreemap.org/styles/bright',
    ),
    const MapStylePreset(
      'Light',
      'https://tiles.openfreemap.org/styles/positron',
    ),
  ];
}
