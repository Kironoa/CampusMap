import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _sessionKey = 'session_email';

  static String _userKey(String email) => 'user_${email.toLowerCase().trim()}';

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_sessionKey) ?? '';
    if (email.isEmpty) return null;
    final raw = prefs.getString(_userKey(email));
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<bool> isLoggedIn() async {
    return (await getCurrentUser()) != null;
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _userKey(email);
    final raw = prefs.getString(key);
    if (raw == null) throw Exception('No account found with this email.');
    final user = jsonDecode(raw) as Map<String, dynamic>;
    if (user['password'] != password) throw Exception('Incorrect password. Please try again.');
    await prefs.setString(_sessionKey, email.toLowerCase().trim());
    return user;
  }

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String idNumber,
    required String email,
    required String password,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _userKey(email);
    if (prefs.containsKey(key)) throw Exception('An account already exists with this email.');
    final user = {
      'fullName': fullName.trim(),
      'idNumber': idNumber.trim(),
      'email': email.toLowerCase().trim(),
      'password': password,
      'role': role,
    };
    await prefs.setString(key, jsonEncode(user));
    await prefs.setString(_sessionKey, email.toLowerCase().trim());
    return user;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, '');
  }
}