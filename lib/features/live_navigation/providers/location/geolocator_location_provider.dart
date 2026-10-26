// lib/features/live_navigation/providers/location/geolocator_location_provider.dart
//
// Geolocator-backed [LocationProvider]. Kept behind the abstraction so the
// screen never imports geolocator directly.
import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../config/nav_config.dart';
import '../../services/nav_errors.dart';
import 'location_provider.dart';

class GeolocatorLocationProvider implements LocationProvider {
  GeolocatorLocationProvider({GeolocatorPlatform? platform})
    : _platform = platform ?? GeolocatorPlatform.instance;

  final GeolocatorPlatform _platform;

  @override
  Future<LocationReadiness> ensureReady() async {
    final serviceEnabled = await _platform.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationReadiness.serviceDisabled;

    var permission = await _platform.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _platform.requestPermission();
    }
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationReadiness.ready;
      case LocationPermission.denied:
        return LocationReadiness.denied;
      case LocationPermission.deniedForever:
        return LocationReadiness.deniedForever;
      case LocationPermission.unableToDetermine:
        return LocationReadiness.denied;
    }
  }

  @override
  Future<NavFix> currentFix({Duration? timeout}) async {
    try {
      final pos = await _platform
          .getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          )
          .timeout(timeout ?? NavConfig.apiTimeout);
      return _toFix(pos);
    } on TimeoutException {
      throw const NavError(NavErrorKind.locationTimeout);
    } catch (e) {
      throw _mapPlatformError(e);
    }
  }

  @override
  Stream<NavFix> liveFixes() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 8, // meters; the guidance engine debounces further
    );
    return _platform
        .getPositionStream(locationSettings: settings)
        .map(_toFix);
  }

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  NavFix _toFix(Position pos) => NavFix(
    latitude: pos.latitude,
    longitude: pos.longitude,
    speedMps: pos.speed.isNaN ? null : pos.speed,
    headingDeg: pos.heading.isNaN ? null : pos.heading,
    accuracyM: pos.accuracy.isNaN ? null : pos.accuracy,
    timestamp: pos.timestamp,
  );

  NavError _mapPlatformError(Object e) {
    final text = e.toString();
    if (e is PermissionDeniedException) {
      return const NavError(NavErrorKind.permissionDenied);
    }
    if (text.contains('PERMISSION_DENIED_NEVER_ASK') ||
        text.contains('deniedForever')) {
      return const NavError(NavErrorKind.permissionDeniedForever);
    }
    if (text.contains('location services are disabled') ||
        text.contains('SERVICE_DISABLED')) {
      return const NavError(NavErrorKind.locationDisabled);
    }
    if (text.contains('SocketException') ||
        text.contains('Failed host lookup') ||
        text.contains('Network is unreachable')) {
      return const NavError(NavErrorKind.noInternet);
    }
    return NavError(NavErrorKind.unknown, text);
  }
}
