import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
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
=======
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/themes/app_themes.dart';
import 'package:mobile_app/helper/db_helper.dart';

class ThemeProvider extends ChangeNotifier {
  String _username = "Student";
  double _uiScale = 1.0;
  Brightness _brightness = Brightness.dark;
  Color _accentColor = const Color(0xFF009688);
  bool _isLoaded = false;

  String get username => _username;
  double get uiScale => _uiScale;
  Brightness get brightness => _brightness;
  Color get currentAccentColor => _accentColor;
  bool get isDarkMode => _brightness == Brightness.dark;
  String get currentThemeName => isDarkMode ? "dark" : "light";
  ThemeData get currentTheme => AppThemes.createTheme(_brightness, _accentColor);
  bool get isLoaded => _isLoaded;

  Future<void> loadSettings() async {
    try {
      final settings = await DatabaseHelper().getSettings();
      if (settings.isNotEmpty) {
        _username = settings['name'] ?? settings['username'] ?? "Student";
        _uiScale = (settings['uiScale'] ?? settings['ui_scale'] ?? 1.0).toDouble();

        if (settings['isDarkMode'] != null) {
          _brightness = (settings['isDarkMode'] == 1)
              ? Brightness.dark
              : Brightness.light;
        } else if (settings['dark'] != null) {
          _brightness = (settings['dark'] == 1) ? Brightness.dark : Brightness.light;
        }

        if (settings['accentColor'] != null && settings['accentColor'] != 0) {
          _accentColor = Color(settings['accentColor'] as int);
        }

        if (_uiScale >= 0.8 && _uiScale <= 1.2) {
          // valid range
        } else {
          _uiScale = 1.0;
        }

        _isLoaded = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading settings: $e");
    }
  }

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
    try {
      await DatabaseHelper().saveSettings(uiScale: scale);
    } catch (e) {
      debugPrint("Error saving scale: $e");
    }
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
    try {
      DatabaseHelper().saveSettings(accentColor: newColor.toARGB32());
    } catch (e) {
      debugPrint("Error saving color: $e");
    }
  }
}

final themeProviderProvider = NotifierProvider<ThemeProviderNotifier, ThemeProvider>(() {
  return ThemeProviderNotifier();
});

class ThemeProviderNotifier extends Notifier<ThemeProvider> {
  @override
  ThemeProvider build() {
    final provider = ThemeProvider();
    Future.microtask(() => provider.loadSettings());
    return provider;
  }

  Future<void> updateUsername(String name) async {
    await state.updateUsername(name);
>>>>>>> 8a35f843624a455ebaf6c1defb4b1077f73e75bc
  }
}