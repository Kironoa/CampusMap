// lib/features/live_navigation/providers/routing/campus_routing_service.dart
//
// Campus-specific routing service that wraps OSRM and adds custom pathways
// for known campus connections (e.g., Main Building ↔ Annex Building).
// Enforces campus boundary: all entry/exit must go through designated gates.

import '../../config/campus_buildings.dart';
import '../../models/geo_math.dart';
import '../../models/nav_route.dart';
import '../routing/osrm_routing_service.dart';
import '../routing/routing_service.dart';

class CampusRoutingService implements RoutingService {
  CampusRoutingService({OsrmRoutingService? osrmService})
      : _osrm = osrmService ?? OsrmRoutingService();

  final OsrmRoutingService _osrm;

  // Custom pathway: Main Building (MB) to Annex Building (AB)
  // From: 8.06522, 123.75695 (MB southeast)
  // To:   8.06549, 123.75726 (AB southwest)
  static const List<NavLatLng> mbToAbPath = [
    NavLatLng(8.06522, 123.75695),
    NavLatLng(8.06549, 123.75726),
  ];

  // Campus boundary polygon (4 corners, clockwise, closed)
  // NW: 8.06441, 123.75838
  // NE: 8.06615, 123.75696
  // SE: 8.06444, 123.75502
  // SW: 8.06271, 123.75648
  static const List<NavLatLng> _campusBoundary = [
    NavLatLng(8.06441, 123.75838),
    NavLatLng(8.06615, 123.75696),
    NavLatLng(8.06444, 123.75502),
    NavLatLng(8.06271, 123.75648),
    NavLatLng(8.06441, 123.75838), // closed
  ];

  // Building footprint centers for proximity checks
  static const NavLatLng _mainBuildingCenter = NavLatLng(8.06513, 123.75620);
  static const NavLatLng _annexBuildingCenter = NavLatLng(8.06522, 123.75760);

  // Radius (meters) to consider a point "at" a building
  static const double _buildingProximityRadius = 50.0;

  @override
  Future<List<NavRouteOption>> computeRoutes({
    required NavLatLng origin,
    required NavLatLng destination,
  }) async {
    // Check if this is a Main Building ↔ Annex Building route
    final isMbToAb = _isNearBuilding(origin, _mainBuildingCenter) &&
        _isNearBuilding(destination, _annexBuildingCenter);
    final isAbToMb = _isNearBuilding(origin, _annexBuildingCenter) &&
        _isNearBuilding(destination, _mainBuildingCenter);

    if (isMbToAb || isAbToMb) {
      return [_buildCustomMbAbRoute(isMbToAb ? mbToAbPath : mbToAbPath.reversed.toList())];
    }

    // Get base routes from OSRM
    final baseRoutes = await _osrm.computeRoutes(origin: origin, destination: destination);

    // Enforce campus boundary: snap routes to gates when crossing boundary
    return _enforceCampusBoundary(baseRoutes, origin, destination);
  }

  Future<List<NavRouteOption>> _enforceCampusBoundary(
    List<NavRouteOption> routes,
    NavLatLng origin,
    NavLatLng destination,
  ) async {
    final originInside = _isInsideCampus(origin);
    final destInside = _isInsideCampus(destination);

    // Both inside or both outside: no boundary crossing needed
    if (originInside == destInside) {
      return routes;
    }

    // Crossing boundary: find best gate and rebuild route via gate
    final gate = _findBestGate(originInside ? destination : origin);
    if (gate == null) return routes;

    return await _routesViaGate(routes, origin, destination, gate, originInside);
  }

  bool _isInsideCampus(NavLatLng point) {
    return CampusBuildings.isPointInRing(point, _campusBoundary);
  }

  CampusEntrance? _findBestGate(NavLatLng outsidePoint) {
    CampusEntrance? best;
    var bestDist = double.infinity;
    for (final gate in CampusEntrances.all) {
      final d = GeoMath.distanceMeters(outsidePoint, gate.location);
      if (d < bestDist) {
        bestDist = d;
        best = gate;
      }
    }
    return best;
  }

  Future<List<NavRouteOption>> _routesViaGate(
    List<NavRouteOption> originalRoutes,
    NavLatLng origin,
    NavLatLng destination,
    CampusEntrance gate,
    bool originInside,
  ) async {
    final outsidePoint = originInside ? destination : origin;
    final insidePoint = originInside ? origin : destination;

    // Route from outside point to gate, then gate to inside point
    final leg1 = await _osrm.computeRoutes(origin: outsidePoint, destination: gate.location);
    final leg2 = await _osrm.computeRoutes(origin: gate.location, destination: insidePoint);

    if (leg1.isEmpty || leg2.isEmpty) return originalRoutes;

    final combined = _combineRoutes(leg1.first, leg2.first, gate.name);
    return [combined];
  }

  NavRouteOption _combineRoutes(
    NavRouteOption leg1,
    NavRouteOption leg2,
    String gateName,
  ) {
    final combinedPoints = [
      ...leg1.overviewPoints,
      ...leg2.overviewPoints.skip(1), // avoid duplicate gate point
    ];
    final distance = leg1.distanceMeters + leg2.distanceMeters;
    final duration = leg1.durationSeconds + leg2.durationSeconds;

    final steps = <NavRouteStep>[
      ...leg1.steps,
      NavRouteStep(
        instruction: 'Pass through $gateName',
        maneuver: 'continue',
        distanceMeters: 0,
        durationSeconds: 30,
        points: [leg1.overviewPoints.last, leg2.overviewPoints.first],
      ),
      ...leg2.steps,
    ];

    return NavRouteOption(
      summary: 'Via $gateName',
      distanceMeters: distance,
      durationSeconds: duration,
      overviewPoints: combinedPoints,
      steps: steps,
    );
  }

  bool _isNearBuilding(NavLatLng point, NavLatLng buildingCenter) {
    return GeoMath.distanceMeters(point, buildingCenter) <= _buildingProximityRadius;
  }

  NavRouteOption _buildCustomMbAbRoute(List<NavLatLng> pathPoints) {
    final distanceMeters = _calculatePathDistance(pathPoints);
    final durationSeconds = (distanceMeters / 1.4).round(); // ~1.4 m/s walking speed

    final step = NavRouteStep(
      instruction: 'Walk through the pathway connecting Main Building and Annex Building',
      maneuver: 'continue',
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      points: pathPoints,
    );

    return NavRouteOption(
      summary: 'Campus Pathway (MB ↔ AB)',
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      overviewPoints: pathPoints,
      steps: [step],
    );
  }

  double _calculatePathDistance(List<NavLatLng> points) {
    double total = 0.0;
    for (int i = 1; i < points.length; i++) {
      total += GeoMath.distanceMeters(points[i - 1], points[i]);
    }
    return total;
  }
}