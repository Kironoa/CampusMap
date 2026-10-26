// lib/features/live_navigation/services/nav_errors.dart
//
// Typed error taxonomy for the feature. Every failure surfaces to the UI as
// a [NavError] whose [friendlyMessage] is safe to show to users.

/// Machine-readable failure reasons.
enum NavErrorKind {
  /// Routing backend unreachable or returned an unexpected response.
  serviceUnavailable,

  /// The backend was asked too often (HTTP 429 / OSRM "Too many requests").
  /// Public demo servers are shared resources — self-host for real use.
  rateLimited,

  /// No route exists between origin and destination.
  routeNotFound,

  /// Device has no internet connection.
  noInternet,

  /// Request timed out.
  timeout,

  /// Location permission denied (user can be asked again).
  permissionDenied,

  /// Location permission permanently denied (must open app settings).
  permissionDeniedForever,

  /// GPS/location services switched off on the device.
  locationDisabled,

  /// Could not get a GPS fix in time.
  locationTimeout,

  /// Destination or coordinates invalid (e.g. unparseable input).
  invalidInput,

  /// Anything else.
  unknown,
}

/// User-safe exception thrown by all feature providers/services.
class NavError implements Exception {
  const NavError(this.kind, [this.details = '']);

  final NavErrorKind kind;
  final String details;

  /// Short, non-technical message suitable for a SnackBar or banner.
  String get friendlyMessage {
    switch (kind) {
      case NavErrorKind.serviceUnavailable:
        return 'Routing service is unavailable right now. Please try again later.';
      case NavErrorKind.rateLimited:
        return 'Routing requests are being throttled. Wait a moment and try again.';
      case NavErrorKind.routeNotFound:
        return 'No driving route found to that destination.';
      case NavErrorKind.noInternet:
        return 'No internet connection. Live Navigation needs internet for map tiles and routes.';
      case NavErrorKind.timeout:
        return 'The request timed out. Check your connection and try again.';
      case NavErrorKind.permissionDenied:
        return 'Location permission is needed to show your position and navigate.';
      case NavErrorKind.permissionDeniedForever:
        return 'Location permission was permanently denied. Enable it in Settings to navigate.';
      case NavErrorKind.locationDisabled:
        return 'Location services are turned off. Turn on GPS to navigate.';
      case NavErrorKind.locationTimeout:
        return 'Could not get your GPS position in time. Try again outdoors.';
      case NavErrorKind.invalidInput:
        return details.isEmpty
            ? 'That destination is not valid.'
            : details;
      case NavErrorKind.unknown:
        return details.isEmpty
            ? 'Something went wrong with Live Navigation.'
            : details;
    }
  }

  @override
  String toString() => 'NavError($kind): $details';
}
