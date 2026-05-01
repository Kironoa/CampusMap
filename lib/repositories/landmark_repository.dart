import '../data/floor_plan_step.dart';

abstract class LandmarkRepository {
  Future<List<Map<String, dynamic>>> getLandmarks();
  Future<void> cacheLandmarks(List<Map<String, dynamic>> landmarks);
  Future<List<FloorPlanStep>> getFloorPlanSteps(String floorPlanId);
  Future<void> cacheFloorPlanSteps(List<FloorPlanStep> steps);
  Future<bool> hasCachedSteps(String floorPlanId);
  Future<List<Map<String, dynamic>>> searchLandmarks(String query);
}
