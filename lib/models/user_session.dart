import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  final bool isLoggedIn;
  final int? userId;
  final String? username;

  const UserSession({
    required this.isLoggedIn,
    this.userId,
    this.username,
  });

  static const UserSession loggedOut = UserSession(isLoggedIn: false);

  bool get hasActiveUser => isLoggedIn && userId != null;

  factory UserSession.fromPreferences(SharedPreferences preferences) {
    return UserSession(
      isLoggedIn: preferences.getBool('isLoggedIn') ?? false,
      userId: preferences.getInt('userId'),
      username: preferences.getString('username'),
    );
  }
}
