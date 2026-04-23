import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:intl/intl.dart';
import 'package:mobile_app/helper/db_helper.dart';
import 'package:mobile_app/models/app_user.dart';
import 'package:mobile_app/models/schedule_model.dart';
import 'package:mobile_app/services/assignment_service.dart';
import 'package:mobile_app/services/user_service.dart';

final databaseHelperProvider = rp.Provider<DatabaseHelper>((ref) => DatabaseHelper());
final userServiceProvider = rp.Provider<UserService>((ref) => UserService());
final assignmentServiceProvider = rp.Provider<AssignmentService>((ref) => AssignmentService());

final userDataProvider = rp.FutureProvider.family<AppUser?, int>((ref, userId) async {
  final userService = ref.read(userServiceProvider);
  return userService.getUser(userId);
});

final schedulesProvider = rp.FutureProvider.family<List<Schedule>, int>((ref, userId) async {
  final dbHelper = ref.read(databaseHelperProvider);
  return dbHelper.getAllSchedules(userId);
});

final todaySchedulesProvider = rp.FutureProvider.family<List<Schedule>, int>((ref, userId) async {
  final schedules = await ref.watch(schedulesProvider(userId).future);
  final now = DateTime.now();
  final currentDayName = DateFormat('EEEE').format(now);
  final dayAbbrev = _dayToAbbrev(currentDayName);
  final dayShort = currentDayName.substring(0, 1).toUpperCase();
  final dayFull = currentDayName.substring(0, 3).toUpperCase();
  
  return schedules.where((s) {
    final scheduleDays = s.days.toUpperCase();
    return scheduleDays.contains(dayAbbrev.toUpperCase()) ||
        scheduleDays.contains(dayFull) ||
        scheduleDays.contains(dayShort) ||
        _matchesDayFull(scheduleDays, currentDayName.toUpperCase());
  }).toList()..sort((a, b) => _timeTo24Hour(a.startTime).compareTo(_timeTo24Hour(b.startTime)));
});

String _dayToAbbrev(String day) {
  final map = {
    'MONDAY': 'MON',
    'TUESDAY': 'TUE',
    'WEDNESDAY': 'WED',
    'THURSDAY': 'THU',
    'FRIDAY': 'FRI',
    'SATURDAY': 'SAT',
    'SUNDAY': 'SUN',
  };
  return map[day.toUpperCase()] ?? day.substring(0, 3).toUpperCase();
}

bool _matchesDayFull(String scheduleDays, String currentDay) {
  final abbrev = _dayToAbbrev(currentDay);
  if (scheduleDays.contains(abbrev)) return true;
  if (scheduleDays.contains(currentDay.substring(0, 3).toUpperCase())) return true;
  final scheduleDayList = scheduleDays.toUpperCase().split(', ');
  final currentShort = currentDay.substring(0, 1).toUpperCase();
  if (scheduleDayList.contains(currentShort)) return true;
  if (currentDay == 'WEDNESDAY' && scheduleDays.toUpperCase().contains('W')) return true;
  if (currentDay == 'MONDAY' && scheduleDays.toUpperCase().contains('M')) return true;
  if (currentDay == 'FRIDAY' && scheduleDays.toUpperCase().contains('F')) return true;
  return false;
}

int _timeTo24Hour(String timeStr) {
  try {
    final trimmed = timeStr.trim();
    final parts = trimmed.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    int minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
    if (parts.length > 1 && parts[1].toUpperCase() == 'PM' && hour < 12) hour += 12;
    if (parts.length > 1 && parts[1].toUpperCase() == 'AM' && hour == 12) hour = 0;
    return hour * 60 + minute;
  } catch (e) {
    return 0;
  }
}