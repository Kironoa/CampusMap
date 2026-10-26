// lib/features/live_navigation/models/reports/report_repository.dart
//
// Waze-style report REPOSITORY CONTRACT + in-memory implementation.
//
// Future backend work only needs to implement [ReportRepository] (e.g. a
// Firestore/REST version) and inject it where reports are consumed. The
// routing and guidance layers must treat reports as advisory data only.
//
// NOTE: not wired into any UI yet — architecture placeholder.
import '../geo_math.dart';
import 'report.dart';

/// Storage/query contract for road reports.
abstract class ReportRepository {
  /// Live list of currently valid (non-expired) reports.
  Stream<List<RoadReport>> watchReports();

  /// Current snapshot of valid reports.
  List<RoadReport> currentReports();

  /// Adds a report; returns its assigned id.
  Future<String> addReport({
    required ReportType type,
    required double latitude,
    required double longitude,
    String note = '',
  });

  /// Removes a report by id (e.g. user deletes their own report).
  Future<void> removeReport(String id);

  /// Reports within [radiusMeters] of a point (for map display / alerts).
  List<RoadReport> nearbyReports({
    required double latitude,
    required double longitude,
    double radiusMeters = 2000,
  });

  /// Clears expired reports. Backends should also enforce TTL server-side.
  Future<void> purgeExpired();
}

/// Local-only implementation used until a backend is chosen.
class InMemoryReportRepository implements ReportRepository {
  InMemoryReportRepository({this.defaultTtl = const Duration(minutes: 45)});

  final Duration defaultTtl;
  final Map<String, RoadReport> _reports = {};
  int _nextId = 0;

  @override
  Stream<List<RoadReport>> watchReports() async* {
    yield currentReports();
  }

  @override
  List<RoadReport> currentReports() {
    final now = DateTime.now();
    return _reports.values.where((r) => !r.isExpired(now)).toList();
  }

  @override
  Future<String> addReport({
    required ReportType type,
    required double latitude,
    required double longitude,
    String note = '',
  }) async {
    final id = 'local_${_nextId++}';
    final now = DateTime.now();
    _reports[id] = RoadReport(
      id: id,
      type: type,
      position: NavLatLng(latitude, longitude),
      note: note,
      createdAt: now,
      expiresAt: now.add(defaultTtl),
    );
    return id;
  }

  @override
  Future<void> removeReport(String id) async {
    _reports.remove(id);
  }

  @override
  List<RoadReport> nearbyReports({
    required double latitude,
    required double longitude,
    double radiusMeters = 2000,
  }) {
    final origin = NavLatLng(latitude, longitude);
    return currentReports()
        .where(
          (r) => GeoMath.distanceMeters(origin, r.position) <= radiusMeters,
        )
        .toList();
  }

  @override
  Future<void> purgeExpired() async {
    final now = DateTime.now();
    _reports.removeWhere((_, r) => r.isExpired(now));
  }
}



