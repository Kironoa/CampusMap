import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/models/class_model.dart';
import 'package:mobile_app/models/assignment_model.dart';
import 'package:mobile_app/repositories/class_repository.dart';
import 'package:mobile_app/services/assignment_service.dart';
import 'package:mobile_app/providers/class_update_notifier.dart';

final classRepositoryProvider = Provider<ClassRepository>((ref) {
  return ClassRepository();
});

final assignmentServiceProvider = Provider<AssignmentService>((ref) {
  return AssignmentService();
});

final assignmentsProvider = FutureProvider.family<List<Assignment>, int>((ref, userId) async {
  final assignmentService = ref.read(assignmentServiceProvider);
  return assignmentService.getRecentAssignments(userId);
});

final classListProvider =
    FutureProvider.family<List<ClassModel>, int>((ref, userId) async {
  final repository = ref.read(classRepositoryProvider);
  ClassUpdateProvider.instance.addListener(() {
    ref.invalidateSelf();
  });
  return repository.getAllClasses(userId);
});

final todayClassesProvider =
    FutureProvider.family<List<ClassModel>, ({int userId, String day})>((ref, params) async {
  final repository = ref.read(classRepositoryProvider);
  return repository.getClassesForDay(params.userId, params.day);
});

final currentTimeProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

final formattedTimeProvider = Provider<String>((ref) {
  ref.watch(currentTimeProvider);
  return DateFormat('HH:mm:ss').format(DateTime.now());
});

final formattedDateProvider = Provider<String>((ref) {
  ref.watch(currentTimeProvider);
  return DateFormat('EEE, MMM dd, yyyy').format(DateTime.now());
});

final currentClassProvider =
    Provider.family<ClassModel?, int>((ref, userId) {
  final classesAsync = ref.watch(classListProvider(userId));
  final timeAsync = ref.watch(currentTimeProvider);

  return classesAsync.when(
    data: (classes) => timeAsync.when(
      data: (now) {
        final nowDayName = DateFormat('EEEE').format(now);
        final dayAbbrev = _dayToAbbrev(nowDayName);
        final dayShort = nowDayName.substring(0, 1).toUpperCase();
        final dayFull = nowDayName.substring(0, 3).toUpperCase();

        final todayClassesList = classes.where((c) {
          final classDays = c.days.toUpperCase();
          return classDays.contains(dayAbbrev.toUpperCase()) ||
              classDays.contains(dayFull) ||
              classDays.contains(dayShort) ||
              _matchesDayFull(classDays, nowDayName.toUpperCase());
        }).toList();

        todayClassesList.sort((a, b) =>
            ClassModel.timeToMinutes(a.startTime)
                .compareTo(ClassModel.timeToMinutes(b.startTime)));

        for (final schedule in todayClassesList) {
          if (ClassModel.isCurrentClassActive(
              schedule.startTime, schedule.endTime, now)) {
            return schedule;
          }
        }
        return null;
      },
      loading: () => null,
      error: (_, __) => null,
    ),
    loading: () => null,
    error: (_, __) => null,
  );
});

final nextClassProvider = Provider.family<ClassModel?, int>((ref, userId) {
  final classesAsync = ref.watch(classListProvider(userId));
  final timeAsync = ref.watch(currentTimeProvider);

  return classesAsync.when(
    data: (classes) => timeAsync.when(
      data: (now) {
        final nowDayName = DateFormat('EEEE').format(now);
        final dayAbbrev = _dayToAbbrev(nowDayName);
        final dayShort = nowDayName.substring(0, 1).toUpperCase();
        final dayFull = nowDayName.substring(0, 3).toUpperCase();

        final todayClassesList = classes.where((c) {
          final classDays = c.days.toUpperCase();
          return classDays.contains(dayAbbrev.toUpperCase()) ||
              classDays.contains(dayFull) ||
              classDays.contains(dayShort) ||
              _matchesDayFull(classDays, nowDayName.toUpperCase());
        }).toList();

        todayClassesList.sort((a, b) =>
            ClassModel.timeToMinutes(a.startTime)
                .compareTo(ClassModel.timeToMinutes(b.startTime)));

        Duration minGap = const Duration(days: 1);
        ClassModel? foundNext;

        for (final schedule in todayClassesList) {
          final startMinutes = ClassModel.timeToMinutes(schedule.startTime);
          final scheduledTime = DateTime(
              now.year, now.month, now.day, startMinutes ~/ 60, startMinutes % 60);
          if (scheduledTime.isAfter(now)) {
            final gap = scheduledTime.difference(now);
            if (gap < minGap) {
              minGap = gap;
              foundNext = schedule;
            }
          }
        }
        return foundNext;
      },
      loading: () => null,
      error: (_, __) => null,
    ),
    loading: () => null,
    error: (_, __) => null,
  );
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
  final scheduleDayList = scheduleDays.split(', ');
  final currentShort = currentDay.substring(0, 1).toUpperCase();
  if (scheduleDayList.contains(currentShort)) return true;
  return false;
}