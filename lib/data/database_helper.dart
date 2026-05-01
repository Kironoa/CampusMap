import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'floor_plan_step.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'campus_map.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE floor_plan_steps(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            floor_plan_id TEXT NOT NULL,
            description TEXT NOT NULL,
            x REAL NOT NULL,
            y REAL NOT NULL,
            step_order INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE landmarks(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            description TEXT,
            category TEXT,
            floor TEXT
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_floor_plan_id ON floor_plan_steps(floor_plan_id)
        ''');
      },
    );
  }

  Future<List<FloorPlanStep>> getFloorPlanSteps(String floorPlanId) async {
    final db = await database;
    final maps = await db.query(
      'floor_plan_steps',
      where: 'floor_plan_id = ?',
      whereArgs: [floorPlanId],
      orderBy: 'step_order ASC',
    );
    return maps.map((m) => FloorPlanStep.fromMap(m)).toList();
  }

  Future<void> cacheFloorPlanSteps(List<FloorPlanStep> steps) async {
    final db = await database;
    final batch = db.batch();
    for (final step in steps) {
      batch.insert(
        'floor_plan_steps',
        step.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit();
  }

  Future<bool> hasCachedSteps(String floorPlanId) async {
    final db = await database;
    final result = await db.query(
      'floor_plan_steps',
      where: 'floor_plan_id = ?',
      whereArgs: [floorPlanId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getLandmarks() async {
    final db = await database;
    return db.query('landmarks');
  }

  Future<void> cacheLandmarks(List<Map<String, dynamic>> landmarks) async {
    final db = await database;
    final batch = db.batch();
    for (final landmark in landmarks) {
      batch.insert(
        'landmarks',
        landmark,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit();
  }
}
