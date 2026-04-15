import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/models/schedule_model.dart';
import 'package:mobile_app/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // STABILITY FIX: Use getApplicationSupportDirectory for Windows to avoid permission issues
    final directory = await getApplicationSupportDirectory();
    final path = join(directory.path, 'student_pal.db');

    return await openDatabase(
      path,
      version: 15, // Version 15 triggers the UNIQUE constraint logic
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT, 
            username TEXT, 
            password TEXT, 
            profilePath TEXT
          )
        ''');

        await _createSettingsTable(db);
        await _createSchedulesTable(db);
        await _createAssignmentsTable(db);
        await _createNotesTable(db);
        await _createResourcesTable(db);
        await _createAiCacheTable(db);

        await db.insert('users', {
          'username': 'Kironoa',
          'password': 'admin123',
          'profilePath': null,
        });
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createSchedulesTable(db);
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE schedules ADD COLUMN userId INTEGER');
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE users ADD COLUMN profilePath TEXT');
        }
        if (oldVersion < 5) {
          await _createAssignmentsTable(db);
          await _createNotesTable(db);
        }
        if (oldVersion < 8) {
          var columns = await db.rawQuery('PRAGMA table_info(assignments)');
          bool hasDeadline =
              columns.any((column) => column['name'] == 'deadline');
          if (!hasDeadline) {
            await db
                .execute('ALTER TABLE assignments ADD COLUMN deadline TEXT');
          }
        }
        if (oldVersion < 7) await _createSettingsTable(db);

        if (oldVersion < 9) {
          await _createResourcesTable(db);
        } else if (oldVersion < 11) {
          await db.execute('DROP TABLE IF EXISTS study_resources');
          await _createResourcesTable(db);
        }

        if (oldVersion < 12) {
          await db.execute('ALTER TABLE notes ADD COLUMN content TEXT');
        }

        if (oldVersion < 13) {
          var columns = await db.rawQuery('PRAGMA table_info(study_resources)');
          bool hasContent =
              columns.any((column) => column['name'] == 'content');
          if (!hasContent) {
            await db
                .execute('ALTER TABLE study_resources ADD COLUMN content TEXT');
          }
        }

        if (oldVersion < 14) {
          await _createAiCacheTable(db);
        }

        if (oldVersion < 15) {
          await db.execute('DROP TABLE IF EXISTS ai_cache');
          await _createAiCacheTable(db);
        }
      },
    );
  }

  // --- TABLE CREATION HELPERS ---

  Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE settings(
        id INTEGER PRIMARY KEY,
        username TEXT,
        isDarkMode INTEGER DEFAULT 0,
        isLoggedIn INTEGER DEFAULT 0
      )
    ''');
    await db.insert('settings',
        {'id': 1, 'username': 'Student', 'isDarkMode': 0, 'isLoggedIn': 0});
  }

  Future<void> _createSchedulesTable(Database db) async {
    await db.execute('''
      CREATE TABLE schedules(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER, subject TEXT, days TEXT, startTime TEXT, endTime TEXT, room TEXT, professor TEXT
      )
    ''');
  }

  Future<void> _createAssignmentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE assignments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER, subject TEXT, title TEXT, description TEXT, 
        isCompleted INTEGER DEFAULT 0,
        deadline TEXT 
      )
    ''');
  }

  Future<void> _createNotesTable(Database db) async {
    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER, title TEXT, description TEXT, content TEXT, dateCreated TEXT
      )
    ''');
  }

  Future<void> _createResourcesTable(Database db) async {
    await db.execute('''
      CREATE TABLE study_resources(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        fileName TEXT,
        localPath TEXT,
        category TEXT,
        content TEXT,
        dateAdded TEXT
      )
    ''');
  }

  Future<void> _createAiCacheTable(Database db) async {
    await db.execute('''
      CREATE TABLE ai_cache(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        resourceId INTEGER,
        type TEXT,
        content TEXT,
        createdAt TEXT,
        UNIQUE(resourceId, type)
      )
    ''');
  }

  // --- AI CACHE METHODS ---

  Future<String?> getCachedAIContent(int resourceId, String type) async {
    final db = await database;
    var res = await db.query("ai_cache",
        where: "resourceId = ? AND type = ?", whereArgs: [resourceId, type]);
    return res.isNotEmpty ? res.first['content'] as String : null;
  }

  Future<void> saveAIContentToCache(
      int resourceId, String type, String content) async {
    final db = await database;
    await db.insert(
        "ai_cache",
        {
          "resourceId": resourceId,
          "type": type,
          "content": content,
          "createdAt": DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // FORCE CLEAN: Use this to wipe AI data if generation is inaccurate
  Future<void> clearAllAiCache() async {
    final db = await database;
    await db.delete('ai_cache');
    debugPrint("AI Cache cleared successfully.");
  }

  // --- DATA OPERATIONS (All Preserved) ---

  Future<Map<String, dynamic>> getSettings() async {
    final db = await database;
    List<Map<String, dynamic>> results =
        await db.query('settings', where: 'id = 1');
    return results.isNotEmpty ? results.first : {};
  }

  Future<void> saveSettings({String? name, bool? dark, bool? loggedIn}) async {
    final db = await database;
    Map<String, dynamic> data = {};
    if (name != null) data['username'] = name;
    if (dark != null) data['isDarkMode'] = dark ? 1 : 0;
    if (loggedIn != null) data['isLoggedIn'] = loggedIn ? 1 : 0;
    await db.update('settings', data, where: 'id = 1');
  }

  Future<int> registerUser(String username, String password) async {
    final db = await database;
    return await db.insert('users',
        {'username': username, 'password': password, 'profilePath': null});
  }

  Future<Map<String, dynamic>?> checkLogin(
      String username, String password) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query('users',
        where: 'username = ? AND password = ?',
        whereArgs: [username, password]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>?> getUser(int userId) async {
    final db = await database;
    try {
      List<Map<String, dynamic>> results =
          await db.query('users', where: 'id = ?', whereArgs: [userId]);
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      debugPrint("Get User Error: $e");
      return null;
    }
  }

  Future<int> updateUserProfilePhoto(int userId, String? imagePath) async {
    final db = await database;
    return await db.update('users', {'profilePath': imagePath},
        where: 'id = ?', whereArgs: [userId]);
  }

  Future<int> insertAssignment(int userId, String subject, String title,
      String desc, String? deadline) async {
    final db = await database;
    try {
      return await db.insert('assignments', {
        'userId': userId,
        'subject': subject,
        'title': title,
        'description': desc,
        'isCompleted': 0,
        'deadline': deadline
      });
    } catch (e) {
      debugPrint("Insert Assignment Error: $e");
      return -1;
    }
  }

  Future<int> updateAssignment(int id, String subject, String title,
      String desc, String? deadline) async {
    final db = await database;
    try {
      return await db.update(
          'assignments',
          {
            'subject': subject,
            'title': title,
            'description': desc,
            'deadline': deadline
          },
          where: 'id = ?',
          whereArgs: [id]);
    } catch (e) {
      debugPrint("Update Assignment Error: $e");
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getAssignments(int userId) async {
    final db = await database;
    return await db.query('assignments',
        where: 'userId = ?', whereArgs: [userId], orderBy: 'deadline ASC');
  }

  Future<int> deleteAssignment(int id) async {
    final db = await database;
    return await db.delete('assignments', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertNote(int userId, String title, String desc,
      {String content = ''}) async {
    final db = await database;
    return await db.insert('notes', {
      'userId': userId,
      'title': title,
      'description': desc,
      'content': content,
      'dateCreated': DateTime.now().toIso8601String()
    });
  }

  Future<int> updateNote(int id, String title, String desc,
      {String content = ''}) async {
    final db = await database;
    return await db.update(
        'notes',
        {
          'title': title,
          'description': desc,
          'content': content,
          'dateCreated': DateTime.now().toIso8601String()
        },
        where: 'id = ?',
        whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getNotes(int userId) async {
    final db = await database;
    return await db.query('notes',
        where: 'userId = ?', whereArgs: [userId], orderBy: 'dateCreated DESC');
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertResource(
      int userId, String name, String localPath, String category,
      {String content = ''}) async {
    final db = await database;
    return await db.insert('study_resources', {
      'userId': userId,
      'fileName': name,
      'localPath': localPath,
      'category': category,
      'content': content,
      'dateAdded': DateTime.now().toIso8601String()
    });
  }

  Future<List<Map<String, dynamic>>> getLocalResources(
      int userId, String category) async {
    final db = await database;
    return await db.query('study_resources',
        where: 'userId = ? AND category = ?',
        whereArgs: [userId, category],
        orderBy: 'dateAdded DESC');
  }

  Future<int> updateResourceName(int id, String newName) async {
    final db = await database;
    return await db.update('study_resources', {'fileName': newName},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteResource(int id) async {
    final db = await database;
    return await db.delete('study_resources', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertSchedule(Schedule schedule, int currentUserId) async {
    final db = await database;
    Map<String, dynamic> row = schedule.toMap();
    row['userId'] = currentUserId;
    int id = await db.insert('schedules', row);
    await _syncScheduleNotification(id, schedule.subject, schedule.startTime);
    return id;
  }

  Future<int> updateSchedule(Schedule schedule) async {
    final db = await database;
    int result = await db.update('schedules', schedule.toMap(),
        where: 'id = ?', whereArgs: [schedule.id]);
    if (schedule.id != null) {
      await _syncScheduleNotification(
          schedule.id!, schedule.subject, schedule.startTime);
    }
    return result;
  }

  Future<List<Schedule>> getAllSchedules(int currentUserId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db
        .query('schedules', where: 'userId = ?', whereArgs: [currentUserId]);
    return maps.map((m) => Schedule.fromMap(m)).toList();
  }

  Future<int> deleteSchedule(int id) async {
    final db = await database;
    try {
      await NotificationService().cancelNotification(id);
    } catch (e) {
      debugPrint("Notification cancel failed: $e");
    }
    return await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getDatabaseData(String tableName) async {
    final db = await database;
    return await db.query(tableName);
  }

  Future<void> _syncScheduleNotification(
      int id, String subject, String startTimeStr) async {
    try {
      DateTime now = DateTime.now();
      DateTime time;
      try {
        time = DateFormat.jm().parse(startTimeStr);
      } catch (_) {
        time = DateFormat("HH:mm").parse(startTimeStr);
      }
      DateTime scheduledDate =
          DateTime(now.year, now.month, now.day, time.hour, time.minute);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      await NotificationService().scheduleClassAlerts(
          id: id, subject: subject, startTime: scheduledDate);
    } catch (e) {
      debugPrint("Sync failed: $e");
    }
  }

  Future<List<Map<String, dynamic>>> searchNotesOffline(
      int userId, String query) async {
    final db = await database;
    return await db.query('notes',
        where:
            'userId = ? AND (title LIKE ? OR description LIKE ? OR content LIKE ?)',
        whereArgs: [userId, '%$query%', '%$query%', '%$query%'],
        orderBy: 'dateCreated DESC');
  }

  Future<Map<String, dynamic>?> getNoteById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('notes', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<Map<String, dynamic>?> getResourceById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('study_resources', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? maps.first : null;
  }
}
