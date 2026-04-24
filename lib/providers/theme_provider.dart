import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _uiScaleKey = 'ui_scale';
  static const String _usernameKey = 'username';
  bool _isDarkMode = false;
  double _uiScale = 1.0;
  Color _accentColor = const Color(0xFF2563EB);
  String _username = 'Student';

  bool get isDarkMode => _isDarkMode;
  double get uiScale => _uiScale;
  Color get currentAccentColor => _accentColor;
  String get username => _username;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    _uiScale = prefs.getDouble(_uiScaleKey) ?? 1.0;
    _username = prefs.getString(_usernameKey) ?? 'Student';
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, value);
    notifyListeners();
  }

  Future<void> setScale(double scale) async {
    _uiScale = scale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_uiScaleKey, scale);
    notifyListeners();
  }

  Future<void> updateUsername(String name) async {
    _username = name.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, _username);
    notifyListeners();
  }
}