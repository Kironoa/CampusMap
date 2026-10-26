// lib/features/live_navigation/providers/map/map_provider.dart
//
// Map rendering abstraction. The navigation UI depends ONLY on these types —
// never on maplibre (or any map SDK) directly — so the tile/renderer backend
// can be swapped without touching the screen.
//
// Current implementation: [MapLibreMapProvider] (MapLibre Native, OSM data,
// no key required). See maplibre_map_provider.dart.

import 'package:flutter/widgets.dart';

import '../../models/geo_math.dart';

/// One route polyline to draw.
class RouteLine {
  const RouteLine({required this.points, required this.selected});

  final List<NavLatLng> points;
  final bool selected;
}

/// Declarative map content. The screen rebuilds this on state changes;
/// the provider turns it into native layers/markers.
class MapViewState {
  const MapViewState({
    this.routes = const [],
    this.destination,
    this.position,
  });

  final List<RouteLine> routes;
  final NavLatLng? destination;
  final NavLatLng? position;
}

/// Map callbacks consumed by the screen.
class MapViewCallbacks {
  const MapViewCallbacks({
    required this.onReady,
    required this.onTap,
    required this.onUserTakeover,
    this.onStyleLoaded,
    this.onZoomChange,
  });

  /// Fired once the map is ready; provides camera control.
  final void Function(NavMapController controller) onReady;

  /// Fired when the user taps the map (used to drop the destination pin).
  final void Function(NavLatLng point) onTap;

  /// Fired when the user moves/zooms the map manually (breaks follow mode).
  final void Function() onUserTakeover;

  /// Fired when the style (base tiles) finished loading.
  final void Function()? onStyleLoaded;

  /// Fired when the camera zoom level changes.
  /// Provides the new zoom level.
  final void Function(double zoom)? onZoomChange;
}

/// Imperative camera control, backend-agnostic.
abstract class NavMapController {
  Future<void> moveTo({
    required NavLatLng target,
    double? zoom,
    double? bearing,
    double? tilt,
  });

  Future<void> animateTo({
    required NavLatLng target,
    double? zoom,
    double? bearing,
    double? tilt,
  });

  /// Fits all [points] on screen with padding.
  Future<void> fitPoints(List<NavLatLng> points);

  /// Switches the base-map appearance (style document URL).
  Future<void> setStyle(String styleUrl);
}

/// Renders the map widget for the given [state] and [callbacks].
abstract class MapProvider {
  /// Style document URL used to render the map.
  String get styleUrl;

  Widget buildMap({
    required MapViewState state,
    required MapViewCallbacks callbacks,
    required NavLatLng initialCenter,
  });
}
