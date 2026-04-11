import 'package:flutter/material.dart';

class AppThemes {
  static const Map<String, Color> colors = {
    'Green': Color(0xFF00C853),
    'Electric Purple': Color(0xFF9D50BB),
    'Cyan': Color(0xFF00E5FF),
    'Hot Pink': Color(0xFFFF69B4),
    'Neon Blue': Color(0xFF2979FF),
    'Orange': Color(0xFFFF8C00),
    'Amber': Color(0xFFFFA000),
    'Yellow': Color(0xFFFFD700),
    'Crimson': Color(0xFFD32F2F),
    'Sunset': Color(0xFFF46036),
    'Midnight Blue': Color(0xFF1A237E),
    'Deep Sea': Color(0xFF2E3192),
    'Teal': Color(0xFF009688),
    'Indigo': Color(0xFF3F51B5),
    'Slate': Color(0xFF607D8B),
    'Rose Gold': Color(0xFFB76E79),
    'Lavender': Color(0xFFE1BEE7),
    'Mint': Color(0xFFB2DFDB),
    'Sky Blue': Color(0xFF87CEEB),
    'Coffee': Color(0xFF6F4E37),
    'Cyber Neon': Color(0xFF00FF7F),
    'Black': Colors.black,
    'Deep Purple': Color(0xFF4B0082),
    'Purple': Color(0xFF800080),
    'Cyber Gradient': Color(0xFF00FF7F),
  };

  static ThemeData createTheme(Brightness brightness, Color accentColor) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        primary: accentColor,
        brightness: brightness,
        surface: isDark ? const Color(0xFF121212) : Colors.white,
      ),
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
    );
  }
}
