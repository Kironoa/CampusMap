import 'package:intl/intl.dart';

class TimeHelper {
  static int convertToMinutes(String timeStr) {
    final trimmed = timeStr.trim();
    try {
      final parts = trimmed.split(RegExp(r'[:\s]'));
      if (parts.length < 2) return 0;
      
      int hour = int.tryParse(parts[0]) ?? 0;
      String minutePart = parts[1].replaceAll(RegExp(r'[^0-9]'), '');
      int minute = int.tryParse(minutePart) ?? 0;
      
      final isPM = trimmed.toUpperCase().contains('PM');
      final isAM = trimmed.toUpperCase().contains('AM');
      
      if (isPM && hour != 12) {
        hour += 12;
      } else if (isAM && hour == 12) {
        hour = 0;
      }
      
      if (hour == 24) hour = 0;
      
      return hour * 60 + minute;
    } catch (e) {
      return 0;
    }
  }

  static String formatMinutesToTime(int minutes) {
    int hour = minutes ~/ 60;
    int minute = minutes % 60;
    
    if (hour == 0) {
      return DateFormat('h:mm a').format(DateTime(2024, 1, 1, 12, minute));
    }
    
    return DateFormat('h:mm a').format(DateTime(2024, 1, 1, hour == 12 ? 12 : hour % 12, minute));
  }

  static String formatTimeForDisplay(String timeStr) {
    try {
      final normalized = _normalizeTo24Hour(timeStr);
      final parts = normalized.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final period = hour >= 12 ? 'PM' : 'AM';
      
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return timeStr;
    }
  }

  static String _normalizeTo24Hour(String timeStr) {
    final trimmed = timeStr.trim();
    try {
      if (!trimmed.contains(' ') && trimmed.contains(':')) {
        final parts = trimmed.split(':');
        if (parts.length >= 2) {
          int hour = int.parse(parts[0]);
          int minute = int.parse(parts[1].replaceAll(RegExp(r'[^0-9]'), ''));
          if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
            return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
          }
        }
      }
      final parsed = DateFormat.jm().parse(trimmed);
      return DateFormat('HH:mm').format(parsed);
    } catch (_) {
      try {
        final parsed = DateFormat('h:mm a').parse(trimmed);
        return DateFormat('HH:mm').format(parsed);
      } catch (_) {
        return '00:00';
      }
    }
  }

  static int getCurrentMinutes() {
    final now = DateTime.now();
    return now.hour * 60 + now.minute;
  }

  static bool isClassActive(String startTime, String endTime) {
    final startMinutes = convertToMinutes(startTime);
    final endMinutes = convertToMinutes(endTime);
    final currentMinutes = getCurrentMinutes();

    if (endMinutes < startMinutes) {
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    } else {
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    }
  }
}