// lib/features/live_navigation/providers/location/location_provider.dart
//
// GPS abstraction. The navigation UI consumes [NavFix] (plain data) and the
// [LocationProvider] contract — never geolocator (or any location plugin)
// directly — so the source can be swapped (e.g. a fused/mock provider)
// without touching the screen.

/// Plugin-free GPS fix.
class NavFix {
  const NavFix({
    required this.latitude,
    required this.longitude,
    this.speedMps,
    this.headingDeg,
    this.accuracyM,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;

  /// Speed in m/s, null when unavailable.
  final double? speedMps;

  /// Heading in degrees [0, 360), null when unavailable.
  final double? headingDeg;
  final double? accuracyM;
  final DateTime timestamp;
}

/// Permission / service state for GPS.
enum LocationReadiness {
  ready,
  denied,
  deniedForever,
  serviceDisabled,
}

abstract class LocationProvider {
  /// Checks service + permission and requests permission when appropriate.
  /// Never throws — returns the resulting state for the UI to message.
  Future<LocationReadiness> ensureReady();

  /// One-shot GPS fix. Throws a [NavError] on failure.
  Future<NavFix> currentFix({Duration? timeout});

  /// Continuous fixes while navigation is active.
  Stream<NavFix> liveFixes();

  Future<void> openAppSettings();
  Future<void> openLocationSettings();
}
