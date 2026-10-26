// lib/features/live_navigation/services/guidance_engine.dart
//
// On-device turn-by-turn guidance computed from Routes API steps.
//
// This is the seam where the Google Navigation SDK would plug in later:
// it consumes GPS fixes and emits guidance snapshots plus reroute signals,
// without any Flutter, map, or network dependencies (fully unit-testable).
//
// Design:
//   - The route is flattened into segments, each owned by a step index.
//   - Each GPS fix snaps to the nearest segment at/after the current
//     progress (search window prevents snapping backwards onto passed roads).
//   - The active step advances as progress passes step boundaries.
//   - Fixes far from the remaining route accumulate an off-route streak;
//     after [offRouteFixesRequired] consecutive strays (and the reroute
//     cooldown), [takeRerouteSignal] returns true exactly once.
import '../config/nav_config.dart';
import '../models/geo_math.dart';
import '../models/nav_route.dart';

/// One guidance computation result for a single GPS fix.
class GuidanceSnapshot {
  const GuidanceSnapshot({
    required this.stepIndex,
    required this.instruction,
    required this.maneuverLabel,
    required this.distanceToManeuverM,
    required this.remainingDistanceM,
    required this.eta,
    required this.offRoute,
    required this.arrived,
  });

  final int stepIndex;
  final String instruction;
  final String maneuverLabel;
  final double distanceToManeuverM;
  final double remainingDistanceM;
  final DateTime eta;
  final bool offRoute;
  final bool arrived;
}

class _Segment {
  _Segment({
    required this.start,
    required this.end,
    required this.length,
    required this.stepIndex,
  });

  final NavLatLng start;
  final NavLatLng end;
  final double length;
  final int stepIndex;
}

class GuidanceEngine {
  GuidanceEngine({
    double? offRouteDeviationMeters,
    int? offRouteFixesRequired,
    Duration? rerouteCooldown,
    double? arrivalRadiusMeters,
    double? fallbackSpeedMps,
  }) : _offRouteDeviationMeters =
           offRouteDeviationMeters ?? NavConfig.offRouteDeviationMeters,
       _offRouteFixesRequired =
           offRouteFixesRequired ?? NavConfig.offRouteFixesRequired,
       _rerouteCooldown = rerouteCooldown ?? NavConfig.rerouteCooldown,
       _arrivalRadiusMeters =
           arrivalRadiusMeters ?? NavConfig.arrivalRadiusMeters,
       _fallbackSpeedMps = fallbackSpeedMps ?? NavConfig.fallbackSpeedMps;

  final double _offRouteDeviationMeters;
  final int _offRouteFixesRequired;
  final Duration _rerouteCooldown;
  final double _arrivalRadiusMeters;
  final double _fallbackSpeedMps;

  NavRouteOption? _route;
  final List<_Segment> _segments = [];
  final List<double> _cumulative = []; // length at segment starts
  double _totalLength = 0.0;

  int _progressSegment = 0;
  double _progressFraction = 0.0;
  int _offRouteStreak = 0;
  DateTime? _lastRerouteAt;
  bool _rerouteSignalled = false;

  bool get hasRoute => _route != null;

  /// Loads a new route (initial calculation or post-reroute replacement)
  /// and resets tracking state.
  void setRoute(NavRouteOption route) {
    _route = route;
    _segments.clear();
    _cumulative.clear();
    _totalLength = 0.0;
    _progressSegment = 0;
    _progressFraction = 0.0;
    _offRouteStreak = 0;
    _rerouteSignalled = false;

    final points = route.trackingPoints;
    for (var i = 0; i < points.length - 1; i++) {
      final length = GeoMath.distanceMeters(points[i], points[i + 1]);
      _cumulative.add(_totalLength);
      _segments.add(
        _Segment(
          start: points[i],
          end: points[i + 1],
          length: length,
          stepIndex: _stepIndexForPoint(route, i),
        ),
      );
      _totalLength += length;
    }
  }

  /// Processes one GPS fix and returns the current guidance snapshot.
  GuidanceSnapshot update({
    required NavLatLng position,
    required double? speedMps,
    required DateTime now,
  }) {
    final route = _route;
    if (route == null || _segments.isEmpty) {
      return GuidanceSnapshot(
        stepIndex: 0,
        instruction: 'Waiting for route…',
        maneuverLabel: '',
        distanceToManeuverM: 0,
        remainingDistanceM: 0,
        eta: now,
        offRoute: false,
        arrived: false,
      );
    }

    // Arrival check against the final route point.
    final destination = route.trackingPoints.last;
    final distToDest = GeoMath.distanceMeters(position, destination);
    if (distToDest <= _arrivalRadiusMeters && _isNearEnd()) {
      final arrival = _buildSnapshot(
        stepIndex: route.steps.length - 1,
        distanceToManeuver: 0,
        remaining: 0,
        speedMps: speedMps,
        now: now,
        offRoute: false,
        arrived: true,
        instructionOverride: 'You have arrived at your destination.',
      );
      return arrival;
    }

    // Snap to the nearest segment at/after current progress.
    var bestSeg = _progressSegment;
    var bestFraction = _progressFraction;
    var bestDist = double.infinity;
    final searchEnd = (_progressSegment + 40).clamp(0, _segments.length - 1);
    for (var i = _progressSegment; i <= searchEnd; i++) {
      final seg = _segments[i];
      final proj = GeoMath.projectOntoSegment(position, seg.start, seg.end);
      if (proj.distanceMeters < bestDist) {
        bestDist = proj.distanceMeters;
        bestSeg = i;
        bestFraction = proj.fraction;
      }
    }

    final offRoute = bestDist > _offRouteDeviationMeters;
    if (offRoute) {
      _offRouteStreak++;
    } else {
      _offRouteStreak = 0;
      _rerouteSignalled = false;
      // Only advance progress on on-route fixes.
      if (bestSeg > _progressSegment ||
          (bestSeg == _progressSegment && bestFraction >= _progressFraction)) {
        _progressSegment = bestSeg;
        _progressFraction = bestFraction;
      }
    }

    final stepIndex = _segments[_progressSegment].stepIndex.clamp(
      0,
      route.steps.length - 1,
    );
    final traveled =
        _cumulative[_progressSegment] +
        _segments[_progressSegment].length * _progressFraction;
    final remaining = (_totalLength - traveled).clamp(0.0, _totalLength);
    final distanceToManeuver = _distanceToStepEnd(stepIndex, traveled);

    return _buildSnapshot(
      stepIndex: stepIndex,
      distanceToManeuver: distanceToManeuver,
      remaining: remaining,
      speedMps: speedMps,
      now: now,
      offRoute: offRoute,
      arrived: false,
    );
  }

  /// Returns true exactly once when the UI should request a new route
  /// (off-route streak reached AND cooldown elapsed). The UI calls
  /// [setRoute] with the replacement, which clears the signal.
  bool takeRerouteSignal(DateTime now) {
    if (_rerouteSignalled) return false;
    if (_offRouteStreak < _offRouteFixesRequired) return false;
    if (_lastRerouteAt != null &&
        now.difference(_lastRerouteAt!) < _rerouteCooldown) {
      return false;
    }
    _rerouteSignalled = true;
    _lastRerouteAt = now;
    return true;
  }

  // --- internals ----------------------------------------------------------

  int _stepIndexForPoint(NavRouteOption route, int pointIndex) {
    if (route.steps.isEmpty) return 0;
    var consumed = 0;
    for (var s = 0; s < route.steps.length; s++) {
      final count = route.steps[s].points.length;
      if (count < 2) continue;
      // Point i is the start of the (consumed)-th flattened segment.
      if (pointIndex < consumed + (count - 1)) return s;
      consumed += count - 1;
    }
    return route.steps.length - 1;
  }

  bool _isNearEnd() {
    if (_segments.isEmpty) return false;
    return _progressSegment >= _segments.length - 2;
  }

  double _distanceToStepEnd(int stepIndex, double traveled) {
    double end = _totalLength;
    for (var i = 0; i < _segments.length; i++) {
      if (_segments[i].stepIndex > stepIndex) {
        end = _cumulative[i];
        break;
      }
    }
    return (end - traveled).clamp(0.0, _totalLength);
  }

  GuidanceSnapshot _buildSnapshot({
    required int stepIndex,
    required double distanceToManeuver,
    required double remaining,
    required double? speedMps,
    required DateTime now,
    required bool offRoute,
    required bool arrived,
    String? instructionOverride,
  }) {
    final route = _route!;
    final safeIndex = stepIndex.clamp(
      0,
      route.steps.isEmpty ? 0 : route.steps.length - 1,
    );
    final step = route.steps.isEmpty ? null : route.steps[safeIndex];
    final effectiveSpeed = (speedMps == null || speedMps < 1.0)
        ? _fallbackSpeedMps
        : speedMps;
    final eta = now.add(
      Duration(seconds: (remaining / effectiveSpeed).round()),
    );
    return GuidanceSnapshot(
      stepIndex: safeIndex,
      instruction:
          instructionOverride ?? step?.instruction ?? 'Continue on route.',
      maneuverLabel: step?.maneuverLabel ?? '',
      distanceToManeuverM: distanceToManeuver,
      remainingDistanceM: remaining,
      eta: eta,
      offRoute: offRoute,
      arrived: arrived,
    );
  }
}



