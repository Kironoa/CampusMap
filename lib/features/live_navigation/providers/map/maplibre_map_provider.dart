// lib/features/live_navigation/providers/map/maplibre_map_provider.dart
//
// MapLibre implementation of [MapProvider]: open-source renderer, OSM-based
// vector tiles, no API key, no account. See NavConfig.mapStyleUrl.
import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';

import '../../config/campus_buildings.dart';
import '../../config/nav_config.dart';
import '../../config/nav_theme.dart';
import '../../models/geo_math.dart';
import 'map_provider.dart';

class MapLibreMapProvider implements MapProvider {
  @override
  String get styleUrl => NavConfig.mapStyleUrl;

  @override
  Widget buildMap({
    required MapViewState state,
    required MapViewCallbacks callbacks,
    required NavLatLng initialCenter,
  }) {
    return MapLibreMap(
      options: MapOptions(
        initStyle: styleUrl,
        initCenter: Geographic(
          lon: initialCenter.longitude,
          lat: initialCenter.latitude,
        ),
        initZoom: 14,
        maxZoom: 19.0,
      ),
      onMapCreated: (controller) =>
          callbacks.onReady(_MapLibreNavController(controller)),
      onStyleLoaded: (_) => callbacks.onStyleLoaded?.call(),
      onEvent: (event) {
        switch (event) {
          case MapEventClick(point: final point):
            callbacks.onTap(
              NavLatLng(point.lat, point.lon),
            );
          case MapEventStartMoveCamera(reason: final reason):
            if (reason == CameraChangeReason.apiGesture) {
              callbacks.onUserTakeover();
            }
          case MapEventMoveCamera(camera: final camera):
            callbacks.onZoomChange?.call(camera.zoom);
          default:
            break;
        }
      },
      layers: [
        // Building footprints — FIRST so they stay behind routes, destination
        // markers, and the position dot. Same [CampusBuildings] data used by
        // the enter-building geofence. Add more buildings by appending to
        // CampusBuildings.all — no other map code changes needed.
        for (final building in CampusBuildings.all) ...[
          PolygonLayer(
            polygons: [
              Feature(
                geometry: Polygon.from([
                  [
                    for (final p in building.ringClosed)
                      Position.create(
                        x: p.longitude,
                        y: p.latitude,
                      ),
                  ],
                ]),
              ),
            ],
            color: NavTheme.buildingFill,
            outlineColor: NavTheme.buildingOutline,
          ),
          PolylineLayer(
            polylines: [
              Feature(
                geometry: LineString.from([
                  for (final p in building.ringClosed)
                    Position.create(
                      x: p.longitude,
                      y: p.latitude,
                    ),
                ]),
              ),
            ],
            color: NavTheme.buildingOutline,
            width: 2,
          ),
        ],
        for (final line in state.routes)
          if (line.points.length >= 2)
            PolylineLayer(
              polylines: [
                Feature(
                  geometry: LineString.from([
                    for (final p in line.points)
                      Position.create(x: p.longitude, y: p.latitude),
                  ]),
                ),
              ],
              color: line.selected ? NavTheme.route : NavTheme.routeAlt,
              width: line.selected ? 6 : 4,
            ),
        if (state.position != null)
          CircleLayer(
            points: [
              Feature(
                geometry: Point(
                  Position.create(
                    x: state.position!.longitude,
                    y: state.position!.latitude,
                  ),
                ),
              ),
            ],
            radius: 9,
            color: NavTheme.position,
            strokeWidth: 3,
            strokeColor: NavTheme.positionRing,
          ),
      ],
      children: [
        // Building name labels, anchored at each footprint's interior point.
        // Listed before the destination pin so the pin draws on top.
        // Non-interactive (TranslucentPointer) so map panning still works.
        WidgetLayer(
          markers: [
            for (final building in CampusBuildings.all)
              Marker(
                point: Geographic(
                  lon: building.labelPoint.longitude,
                  lat: building.labelPoint.latitude,
                ),
                size: const Size(180, 30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: NavTheme.buildingLabel,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: NavTheme.buildingOutline,
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    building.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: NavTheme.buildingLabelText,
                    ),
                  ),
                ),
              ),
          ],
        ),
        // Entrance gates (numbered pills). Non-interactive widgets — taps
        // are resolved in Dart via CampusEntrances.nearestWithin so the
        // same data drives markers and popups.
        WidgetLayer(
          markers: [
            for (final entrance in CampusEntrances.all)
              Marker(
                point: Geographic(
                  lon: entrance.location.longitude,
                  lat: entrance.location.latitude,
                ),
                size: const Size(132, 32),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: NavTheme.accent,
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.login_rounded,
                        size: 14,
                        color: NavTheme.accent,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          entrance.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: NavTheme.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (state.destination != null)
          WidgetLayer(
            markers: [
              Marker(
                point: Geographic(
                  lon: state.destination!.longitude,
                  lat: state.destination!.latitude,
                ),
                size: const Size(48, 48),
                alignment: Alignment.bottomCenter,
                child: const Icon(
                  Icons.location_pin,
                  size: 48,
                  color: NavTheme.pin,
                ),
              ),
            ],
          ),
        // Map data attribution. Shown for every style (the layers button
        // cycles Satellite ↔ Streets without rebuilding this chip):
        // OSM credit for vector styles (ODbL) + Esri credit for satellite.
        Positioned(
          left: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '© OpenStreetMap contributors • Imagery © Esri',
              style: TextStyle(fontSize: 10, color: Colors.black87),
            ),
          ),
        ),
      ],
    );
  }
}

class _MapLibreNavController implements NavMapController {
  _MapLibreNavController(this._controller);

  final MapController _controller;

  @override
  Future<void> moveTo({
    required NavLatLng target,
    double? zoom,
    double? bearing,
    double? tilt,
  }) {
    return _controller.moveCamera(
      center: Geographic(lon: target.longitude, lat: target.latitude),
      zoom: zoom,
      bearing: bearing,
      pitch: tilt,
    );
  }

  @override
  Future<void> animateTo({
    required NavLatLng target,
    double? zoom,
    double? bearing,
    double? tilt,
  }) {
    return _controller.animateCamera(
      center: Geographic(lon: target.longitude, lat: target.latitude),
      zoom: zoom,
      bearing: bearing,
      pitch: tilt,
    );
  }

  @override
  Future<void> fitPoints(List<NavLatLng> points) {
    if (points.isEmpty) return Future.value();
    return _controller.fitBounds(
      bounds: LngLatBounds.fromPoints([
        for (final p in points)
          Geographic(lon: p.longitude, lat: p.latitude),
      ]),
      padding: const EdgeInsets.all(72),
    );
  }

  @override
  Future<void> setStyle(String styleUrl) {
    _controller.setStyle(styleUrl);
    return Future.value();
  }
}
