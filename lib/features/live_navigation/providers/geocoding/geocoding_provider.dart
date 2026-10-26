// lib/features/live_navigation/providers/geocoding/geocoding_provider.dart
//
// Place-search contract for a FUTURE non-Google provider.
//
// Destination selection today is map-tap + coordinates only (no network
// search, no key, no account). When a billing-free search is wanted, add an
// implementation of [GeocodingProvider] (e.g. Nominatim — respect its usage
// policy — or a self-hosted Photon/Pelias instance) and inject it into the
// destination UI. The routing/guidance layers only ever consume the
// resulting coordinates, so no other code changes are needed.
import '../../models/geo_math.dart';

/// A named place resolved to coordinates by a geocoding provider.
class NavPlace {
  const NavPlace({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
  });

  final String id;
  final String name;
  final String address;
  final NavLatLng location;
}

/// Contract for text place search. No bundled implementation yet.
abstract class GeocodingProvider {
  /// Returns up to [maxResults] matching places with coordinates.
  /// Throws [NavError] on failure.
  Future<List<NavPlace>> searchPlaces(String query, {int maxResults = 6});
}
