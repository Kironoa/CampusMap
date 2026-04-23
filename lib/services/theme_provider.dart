import 'package:flutter/material.dart';
import 'package:mobile_app/themes/app_themes.dart';
import 'package:mobile_app/helper/db_helper.dart';

class ThemeProvider extends ChangeNotifier {
  // --- State Variables ---
  String _username = "Student";
  double _uiScale = 1.0;
  Brightness _brightness =
      Brightness.dark; // Defaulting to dark for Student Pal look
  Color _accentColor = const Color(0xFF009688);

  // --- Getters ---
  String get username => _username;
  double get uiScale => _uiScale;
  Brightness get brightness => _brightness;
  Color get currentAccentColor => _accentColor;
  bool get isDarkMode => _brightness == Brightness.dark;
  String get currentThemeName => isDarkMode ? "dark" : "light";

  // This generates the actual theme object for main.dart
  ThemeData get currentTheme =>
      AppThemes.createTheme(_brightness, _accentColor);

  // --- Initialization ---
  ThemeProvider() {
    loadSettings();
  }

  // Unified Load Logic: Fetches everything from SQLite at once
  Future<void> loadSettings() async {
    try {
      final settings = await DatabaseHelper().getSettings();
      if (settings.isNotEmpty) {
        _username = settings['name'] ?? settings['username'] ?? "Student";
        _uiScale = (settings['ui_scale'] ?? 1.0).toDouble();

        // Handle darkness/brightness persistence
        if (settings['isDarkMode'] != null) {
          _brightness = (settings['isDarkMode'] == 1)
              ? Brightness.dark
              : Brightness.light;
        } else if (settings['dark'] != null) {
          _brightness =
              (settings['dark'] == 1) ? Brightness.dark : Brightness.light;
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading settings: $e");
    }
  }

  // --- Setters & Persistence ---

  Future<void> updateUsername(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isNotEmpty) {
      _username = trimmedName;
      notifyListeners();
      try {
        await DatabaseHelper().saveSettings(name: trimmedName);
      } catch (e) {
        debugPrint("Error saving username: $e");
      }
    }
  }

  Future<void> setScale(double scale) async {
    _uiScale = scale;
    notifyListeners();
    // Optional: Save scale to DB here if your saveSettings supports it
    // await DatabaseHelper().saveSettings(uiScale: scale);
  }

  Future<void> setBrightness(Brightness newBrightness) async {
    _brightness = newBrightness;
    notifyListeners();
    await DatabaseHelper().saveSettings(dark: newBrightness == Brightness.dark);
  }

  Future<void> setTheme(String themeName) async {
    _brightness = (themeName == 'light') ? Brightness.light : Brightness.dark;
    notifyListeners();
    await DatabaseHelper().saveSettings(dark: _brightness == Brightness.dark);
  }

  void setColor(Color newColor) {
    _accentColor = newColor;
    notifyListeners();
    // Optional: Persist color selection
    // await DatabaseHelper().saveSettings(accentColor: newColor.value);
  }
}
