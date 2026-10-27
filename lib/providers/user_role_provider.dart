import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_role.dart';

class UserRoleProvider extends ChangeNotifier {
  static const String _prefsKey = 'user_role';

  UserRole? _role;

  UserRole? get role => _role;

  bool get hasRole => _role != null;

  Future<void> loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    for (final role in UserRole.values) {
      if (role.name == stored) {
        _role = role;
        break;
      }
    }
    notifyListeners();
  }

  Future<void> setRole(UserRole role) async {
    if (_role == role) return;
    _role = role;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, role.name);
  }
}
