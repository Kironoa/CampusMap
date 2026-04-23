String dayToAbbrev(String day) {
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

bool matchesDayFull(String scheduleDays, String currentDay) {
  final abbrev = dayToAbbrev(currentDay);
  if (scheduleDays.contains(abbrev)) return true;
  if (scheduleDays.contains(currentDay.substring(0, 3).toUpperCase())) {
    return true;
  }
  final scheduleDayList = scheduleDays.split(', ');
  final currentShort = currentDay.substring(0, 1).toUpperCase();
  if (scheduleDayList.contains(currentShort)) return true;
  return false;
}

int timeTo24Hour(String timeStr) {
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