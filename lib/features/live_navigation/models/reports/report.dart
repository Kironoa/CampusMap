// lib/features/live_navigation/models/reports/report.dart
//
// Waze-style report MODELS ONLY (future architecture).
//
// These types define the shape of traffic/accident/closure/construction/
// hazard/police reports so they can be added later WITHOUT changing the
// routing, guidance, or UI layers. Nothing in the app creates, displays, or
// syncs reports yet — see report_repository.dart.
import '../geo_math.dart';

/// Report categories supported by the future report system.
enum ReportType {
  traffic,
  accident,
  closure,
  construction,
  hazard,
  police,
}

/// A single user-submitted road report.
class RoadReport {
  const RoadReport({
    required this.id,
    required this.type,
    required this.position,
    this.note = '',
    required this.createdAt,
    this.expiresAt,
    this.upvotes = 0,
  });

  final String id;
  final ReportType type;
  final NavLatLng position;
  final String note;
  final DateTime createdAt;

  /// Reports auto-expire so stale markers disappear on their own.
  /// Null means "use the repository default TTL".
  final DateTime? expiresAt;

  final int upvotes;

  bool isExpired(DateTime now) =>
      expiresAt != null && now.isAfter(expiresAt!);
}


