// lib/ar/models/ar_route_data.dart
import 'dart:math';
import 'dart:ui';

class ArRouteData {
  final List<Offset> path;
  final int floorIndex;
  final String? roomId;
  final String? roomName;

  const ArRouteData({
    required this.path,
    required this.floorIndex,
    this.roomId,
    this.roomName,
  });

  bool get hasRoute => path.length >= 2;

  /// Approximate route length in meters (normalized map units -> meters).
  double get estimatedDistanceMeters {
    if (path.length < 2) return 0;
    double distance = 0;
    for (int i = 0; i < path.length - 1; i++) {
      final dx = path[i + 1].dx - path[i].dx;
      final dy = path[i + 1].dy - path[i].dy;
      distance += sqrt(dx * dx + dy * dy);
    }
    return distance * 40;
  }
}
