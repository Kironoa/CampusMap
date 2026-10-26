// lib/features/live_navigation/config/nav_theme.dart
//
// PERSONAL UI THEME — edit these values to restyle Live Navigation.
//
// Everything visual in the feature reads from here: the guidance banner,
// route lines, position dot, destination pin, and buttons. Change a color
// once and it applies everywhere (map tiles themselves come from the
// selected map style — switch styles with the layers button in the app).
import 'package:flutter/material.dart';

class NavTheme {
  NavTheme._();

  // --- Map overlays -------------------------------------------------------
  /// Active route line.
  static const Color route = Color(0xFF1A73E8);

  /// Alternative (non-selected) route lines.
  static const Color routeAlt = Color(0xFF9AA0A6);

  /// Your GPS position dot.
  static const Color position = Color(0xFF1A73E8);

  /// Ring around the position dot.
  static const Color positionRing = Colors.white;

  /// Destination pin.
  static const Color pin = Color(0xFFD32F2F);

  // --- Building footprints (outdoor geofences + overlay) -------------------
  // Rendered BELOW routes, destination markers, and the position dot.
  // Plain peach fill; per-building colors can be added later if wayfinding
  // needs them.
  /// Building fill (plain peach).
  static const Color buildingFill = Color(0xFFFFDAB9);

  /// Building outline (warm brown, clearly visible on peach).
  static const Color buildingOutline = Color(0xFFB26A2B);

  /// Building name label background.
  static const Color buildingLabel = Color(0xFFFFFFFF);

  /// Building name label text.
  static const Color buildingLabelText = Color(0xFF5C3A1E);

  // --- HUD ----------------------------------------------------------------
  /// Guidance banner background (next-turn card).
  static const Color banner = Color(0xFF0A7040);

  /// Text/icons on the banner.
  static const Color bannerText = Colors.white;

  /// ETA headline, recenter button, "Start navigation" button.
  static const Color accent = Color(0xFF0A7040);

  /// "Stop" button.
  static const Color stopButton = Color(0xFFB71C1C);
}
