import 'package:naviapp/helper/db_helper.dart';
import 'package:naviapp/models/app_user.dart';
import 'package:naviapp/models/user_session.dart';
import 'package:naviapp/services/user_session_service.dart';

class AuthService {
  final DatabaseHelper _dbHelper;
  final UserSessionService _sessionService;

  AuthService({
    DatabaseHelper? dbHelper,
    UserSessionService? sessionService,
  })  : _dbHelper = dbHelper ?? DatabaseHelper(),
        _sessionService = sessionService ?? UserSessionService();

  Future<UserSession> loadSession() {
    return _sessionService.loadSession();
  }

  Future<AppUser?> login(String username, String password) async {
    final userMap = await _dbHelper.checkLogin(username, password);
    if (userMap == null) {
      return null;
    }

    final user = AppUser.fromMap(userMap);
    await _sessionService.saveLoggedInUser(user);
    return user;
  }

  Future<bool> usernameExists(String username) async {
    final db = await _dbHelper.database;
    final existingUsers = await db.query(
      'users',
      columns: ['id'],
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    return existingUsers.isNotEmpty;
  }

  Future<AppUser?> register(String username, String password) async {
    final userId = await _dbHelper.registerUser(username, password);
    final userMap = await _dbHelper.getUser(userId);
    if (userMap == null) {
      return AppUser(id: userId, username: username);
    }
    return AppUser.fromMap(userMap);
  }

  Future<void> logout() {
    return _sessionService.clearSession();
  }
}
