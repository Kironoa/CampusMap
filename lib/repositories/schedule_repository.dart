import 'package:naviapp/helper/db_helper.dart';
import 'package:naviapp/models/schedule_model.dart';
import 'package:naviapp/core/base_repository.dart';

class ScheduleRepository implements BaseRepository<Schedule> {
  final DatabaseHelper _dbHelper;

  ScheduleRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  @override
  Future<List<Schedule>> getAll(int userId) async {
    return await _dbHelper.getAllSchedules(userId);
  }

  @override
  Future<Schedule?> getById(int id) async {
    final all = await getAll(0);
    final found = all.where((s) => s.id == id);
    return found.isNotEmpty ? found.first : null;
  }

  @override
  Future<int> create(int userId, Schedule schedule) async {
    return await _dbHelper.insertSchedule(schedule, userId);
  }

  @override
  Future<void> update(Schedule schedule) async {
    if (schedule.id == null) return;
    await _dbHelper.updateSchedule(schedule);
  }

  @override
  Future<void> delete(int id) async {
    await _dbHelper.deleteSchedule(id);
  }

  @override
  Future<List<Schedule>> search(int userId, String query) async {
    final all = await getAll(userId);
    return all
        .where((s) =>
            s.subject.toLowerCase().contains(query.toLowerCase()) ||
            s.professor.toLowerCase().contains(query.toLowerCase()) ||
            s.room.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}