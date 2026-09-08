// lib/services/navigation_service.dart
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:naviapp/providers/user_location_provider.dart';
import 'package:naviapp/services/indoor_positioning/indoor_position.dart';
import 'package:naviapp/services/indoor_positioning/indoor_position_provider.dart';

/// The computed navigation route with dot positions for rendering.
@immutable
class NavigationRoute {
  /// Full path from current position to destination (normalized coordinates).
  final List<Offset> fullPath;

  /// Floor index for each point in fullPath.
  final List<int> floorIndices;

  /// Dot positions to render (normalized coordinates, subset of fullPath).
  final List<Offset> dotPositions;

  /// Floor index for each dot.
  final List<int> dotFloorIndices;

  const NavigationRoute({
    required this.fullPath,
    required this.floorIndices,
    required this.dotPositions,
    required this.dotFloorIndices,
  });

  bool get hasPath => fullPath.length >= 2;
}

/// Configuration for the navigation service.
@immutable
class NavigationConfig {
  /// Spacing between dots in pixels.
  final double dotSpacingPixels;

  /// Minimum movement (in pixels) to trigger route recalculation.
  final double recalculationThresholdPixels;

  /// Maximum time between recalculations (debounce).
  final Duration recalculationDebounce;

  const NavigationConfig({
    this.dotSpacingPixels = 25.0,
    this.recalculationThresholdPixels = 15.0,
    this.recalculationDebounce = const Duration(milliseconds: 500),
  });
}

/// Service that manages dynamic navigation.
///
/// Calculates routes from the user's current position,
/// generates dot positions for rendering, and updates the route as the user moves.
class NavigationService extends ChangeNotifier {
  NavigationService({
    NavigationConfig? config,
    UserLocationProvider? userLocationProvider,
    IndoorPositionProvider? positionProvider,
  }) : _config = config ?? const NavigationConfig(),
       _userLocationProvider = userLocationProvider,
       _positionProvider = positionProvider {
    _initListeners();
  }

  final NavigationConfig _config;
  final UserLocationProvider? _userLocationProvider;
  final IndoorPositionProvider? _positionProvider;

  NavigationRoute? _currentRoute;
  IndoorPosition? _lastPosition;
  Timer? _debounceTimer;
  bool _isCalculating = false;

  /// The current navigation route with dots (null if no active navigation).
  NavigationRoute? get currentRoute => _currentRoute;

  /// Whether navigation is currently active.
  bool get isNavigating => _currentRoute != null;

  /// Whether a route calculation is in progress.
  bool get isCalculating => _isCalculating;

  void _initListeners() {
    if (_userLocationProvider != null) {
      _userLocationProvider.addListener(_onUserPositionChanged);
    }
    if (_positionProvider != null) {
      _positionProvider.positions.listen(_onLivePosition);
    }
  }

  /// Gets the current active user position (manual QR pin takes precedence).
  IndoorPosition? get _activePosition {
    if (_userLocationProvider != null &&
        _userLocationProvider.hasManualPosition) {
      return _userLocationProvider.position;
    }
    return _lastPosition;
  }

  void _onLivePosition(IndoorPosition position) {
    _lastPosition = position;
    _maybeRecalculateRoute();
  }

  void _onUserPositionChanged() {
    _maybeRecalculateRoute();
  }

  /// Called when user's position changes. Debounces route recalculation.
  void _maybeRecalculateRoute() {
    if (_isCalculating) return;

    final position = _activePosition;
    if (position == null) return;

    // Check if position changed enough to warrant recalculation
    if (_shouldRecalculate(position)) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(_config.recalculationDebounce, () {
        _recalculateRoute();
      });
    }
  }

  bool _shouldRecalculate(IndoorPosition newPosition) {
    final lastPosition = _lastPosition;
    if (lastPosition == null) return true;

    final dx = newPosition.x - lastPosition.x;
    final dy = newPosition.y - lastPosition.y;
    // Approximate pixel distance (normalized * average floor image dimension)
    final pixelDistance = sqrt(dx * dx + dy * dy) * 1500.0;
    return pixelDistance >= _config.recalculationThresholdPixels;
  }

  /// Calculates the route from current position.
  Future<void> _recalculateRoute() async {
    if (_isCalculating) return;

    final position = _activePosition;
    if (position == null) return;

    _isCalculating = true;
    _isCalculating = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _userLocationProvider?.removeListener(_onUserPositionChanged);
    super.dispose();
  }
}