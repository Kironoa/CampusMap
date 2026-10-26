// lib/features/live_navigation/providers/routing/routing_service.dart
//
// Routing abstraction. The guidance engine and UI consume [NavRouteOption]
// only — never backend-specific JSON — so the routing backend can be
// replaced (OSRM today, Valhalla/GraphHopper/self-hosted tomorrow) by
// implementing this contract.
import '../../models/geo_math.dart';
import '../../models/nav_route.dart';

abstract class RoutingService {
  /// Computes driving routes from [origin] to [destination].
  /// Returns the recommended route first, then alternatives when the
  /// backend provides them. Throws [NavError] on failure.
  Future<List<NavRouteOption>> computeRoutes({
    required NavLatLng origin,
    required NavLatLng destination,
  });
}
