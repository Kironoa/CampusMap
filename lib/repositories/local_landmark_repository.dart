import '../data/database_helper.dart';
import '../data/floor_plan_step.dart';
import 'landmark_repository.dart';

class LocalLandmarkRepository implements LandmarkRepository {
  final DatabaseHelper _dbHelper;

  LocalLandmarkRepository(this._dbHelper);

  @override
  Future<List<Map<String, dynamic>>> getLandmarks() => _dbHelper.getLandmarks();

  @override
  Future<void> cacheLandmarks(List<Map<String, dynamic>> landmarks) =>
      _dbHelper.cacheLandmarks(landmarks);

  @override
  Future<List<FloorPlanStep>> getFloorPlanSteps(String floorPlanId) =>
      _dbHelper.getFloorPlanSteps(floorPlanId);

  @override
  Future<void> cacheFloorPlanSteps(List<FloorPlanStep> steps) =>
      _dbHelper.cacheFloorPlanSteps(steps);

  @override
  Future<bool> hasCachedSteps(String floorPlanId) =>
      _dbHelper.hasCachedSteps(floorPlanId);

  @override
  Future<List<Map<String, dynamic>>> searchLandmarks(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'landmarks',
      where: 'name LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return maps;
  }
}
