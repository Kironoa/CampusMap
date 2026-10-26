// lib/features/live_navigation/ui/nav_format.dart
//
// Display formatting for distances, durations, and ETAs.

String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  final km = meters / 1000.0;
  return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
}

String formatDuration(int totalSeconds) {
  final minutes = (totalSeconds / 60).round();
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '${hours}h' : '${hours}h ${rest}m';
}

String formatEta(DateTime eta) {
  var hour = eta.hour % 12;
  if (hour == 0) hour = 12;
  final minute = eta.minute.toString().padLeft(2, '0');
  final period = eta.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

/// Compact "lat, lng" label with 5 decimals (~1 m precision).
String formatLatLng(double latitude, double longitude) {
  return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
}
