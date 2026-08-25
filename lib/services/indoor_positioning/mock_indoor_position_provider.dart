// lib/services/indoor_positioning/mock_indoor_position_provider.dart
import 'dart:async';
import 'dart:ui';

import 'indoor_position.dart';
import 'indoor_position_provider.dart';
import 'positioning_settings.dart';

/// Simulates a moving user on the floor plan. No BLE hardware required.
///
/// Usage:
///  - [setPosition] teleports the simulated user.
///  - [walkTo] smoothly walks toward a target at a configurable speed,
///    emitting intermediate positions so the UI shows continuous movement.
///  - [startDemoLoop] / [stopDemoLoop] walk a small circuit for demos.
class MockIndoorPositionProvider extends IndoorPositionProvider {
  MockIndoorPositionProvider({
    Duration? updateInterval,
    double? walkSpeedUnitsPerSecond,
    double? accuracyMeters,
  })  : updateInterval =
            updateInterval ?? PositioningSettings.instance.positionUpdateInterval,
        _walkSpeed = walkSpeedUnitsPerSecond ??
            PositioningSettings.instance.mockWalkSpeedUnitsPerSecond,
        _accuracy = accuracyMeters ??
            PositioningSettings.instance.mockAccuracyMeters;

  final Duration updateInterval;
  final double _walkSpeed;
  final double _accuracy;

  IndoorPosition? _current;
  Timer? _timer;
  bool _running = false;
  bool _demoMode = false;

  Offset? _target;
  int _targetFloor = 0;

  /// Demo circuit waypoints (normalized), walked clockwise.
  static const List<Offset> _demoWaypoints = [
    Offset(0.30, 0.30),
    Offset(0.70, 0.30),
    Offset(0.70, 0.70),
    Offset(0.30, 0.70),
  ];
  int _demoIndex = 0;

  final StreamController<IndoorPosition> _controller =
      StreamController<IndoorPosition>.broadcast();

  @override
  Stream<IndoorPosition> get positions => _controller.stream;

  @override
  IndoorPosition? get currentPosition => _current;

  @override
  bool get isRunning => _running;

  /// Teleports the simulated user. If running, emits immediately.
  void setPosition(double x, double y, int floor) {
    _target = null;
    _current = IndoorPosition(
      x: IndoorPosition.clampCoordinate(x),
      y: IndoorPosition.clampCoordinate(y),
      floor: floor,
      accuracy: _accuracy,
      timestamp: DateTime.now(),
      source: PositionSource.mock,
    );
    if (_running) _emit(_current!);
  }

  /// Walks smoothly toward a target coordinate on the given floor.
  void walkTo(double x, double y, int floor) {
    _target = Offset(
      IndoorPosition.clampCoordinate(x),
      IndoorPosition.clampCoordinate(y),
    );
    _targetFloor = floor;
  }

  /// Starts walking a demo circuit on the current floor.
  void startDemoLoop() {
    _demoMode = true;
  }

  /// Stops the demo circuit (current walk finishes naturally).
  void stopDemoLoop() {
    _demoMode = false;
  }

  @override
  Future<void> start() async {
    if (_running) return;
    _running = true;
    _current ??= IndoorPosition(
      x: 0.5,
      y: 0.5,
      floor: 0,
      accuracy: _accuracy,
      timestamp: DateTime.now(),
      source: PositionSource.mock,
    );
    _emit(_current!);
    _timer = Timer.periodic(updateInterval, (_) => _tick());
  }

  @override
  Future<void> stop() async {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  void _tick() {
    if (_target != null) {
      _stepTowardTarget();
    } else if (_demoMode) {
      final waypoint = _demoWaypoints[_demoIndex % _demoWaypoints.length];
      _demoIndex++;
      walkTo(waypoint.dx, waypoint.dy, _current?.floor ?? 0);
    }
    if (_current != null) {
      _emit(_current!);
    }
  }

  void _stepTowardTarget() {
    final target = _target!;
    final current = _current!;
    final currentOffset = Offset(current.x, current.y);
    final remaining = (target - currentOffset).distance;

    final stepSize =
        _walkSpeed * updateInterval.inMilliseconds / 1000.0;

    if (remaining <= stepSize) {
      _current = IndoorPosition(
        x: IndoorPosition.clampCoordinate(target.dx),
        y: IndoorPosition.clampCoordinate(target.dy),
        floor: _targetFloor,
        accuracy: _accuracy,
        timestamp: DateTime.now(),
        source: PositionSource.mock,
      );
      _target = null;
    } else {
      final direction = (target - currentOffset) / remaining;
      final next = currentOffset + direction * stepSize;
      _current = IndoorPosition(
        x: IndoorPosition.clampCoordinate(next.dx),
        y: IndoorPosition.clampCoordinate(next.dy),
        floor: _targetFloor,
        accuracy: _accuracy,
        timestamp: DateTime.now(),
        source: PositionSource.mock,
      );
    }
  }

  void _emit(IndoorPosition position) {
    if (!_controller.isClosed) {
      _controller.add(position);
    }
  }
}