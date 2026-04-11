import 'package:flutter/material.dart';
import 'package:mobile_app/themes/app_themes.dart';
import 'package:mobile_app/helper/db_helper.dart';

class ThemeProvider extends ChangeNotifier {
  String _username = "Student";
  String get username => _username;

  Future<void> updateUsername(String name) async {
    if (name.trim().isNotEmpty) {
      _username = name;
      notifyListeners();
      await DatabaseHelper().saveSettings(name: name);
    }
  }

  double _uiScale = 1.0;
  double get uiScale => _uiScale;

  Future<void> setScale(double scale) async {
    _uiScale = scale;
    notifyListeners();
  }

  Brightness _brightness = Brightness.light;
  Color _accentColor = const Color(0xFF009688);

  Brightness get brightness => _brightness;
  Color get currentAccentColor => _accentColor;
  bool get isDarkMode => _brightness == Brightness.dark;
  ThemeData get currentTheme =>
      AppThemes.createTheme(_brightness, _accentColor);

  Future<void> loadSettings() async {
    final settings = await DatabaseHelper().getSettings();
    if (settings.isNotEmpty) {
      _username = settings['username'] ?? "Student";
      _brightness =
          (settings['isDarkMode'] == 1) ? Brightness.dark : Brightness.light;
      notifyListeners();
    }
  }

  Future<void> setBrightness(Brightness newBrightness) async {
    _brightness = newBrightness;
    notifyListeners();
    await DatabaseHelper().saveSettings(dark: newBrightness == Brightness.dark);
  }

  void setColor(Color newColor) {
    _accentColor = newColor;
    notifyListeners();
  }

  String get currentThemeName => isDarkMode ? "dark" : "light";

  Future<void> setTheme(String themeName) async {
    _brightness = (themeName == 'light') ? Brightness.light : Brightness.dark;
    notifyListeners();
    await DatabaseHelper().saveSettings(dark: _brightness == Brightness.dark);
  }
}
