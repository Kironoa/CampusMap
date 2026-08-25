// lib/providers/user_location_provider.dart
import 'package:flutter/foundation.dart';

import '../models/starting_location.dart';
import '../services/indoor_positioning/indoor_position.dart';

/// App-wide current-location state.
///
/// A QR scan pins the user to a [StartingLocation]: the stored position is
/// exact (source: manual) and takes precedence over live BLE/mock estimates
/// until it is cleared or replaced by another scan.
class UserLocationProvider extends ChangeNotifier {
  IndoorPosition? _position;

  /// The starting location when the position came from a QR scan.
  StartingLocation? _startingLocation;

  /// Current position, if known.
  ///
  /// When [startingLocation] is non-null this is an exact, manually pinned
  /// position and live positioning updates should be ignored by consumers.
  IndoorPosition? get position => _position;

  /// Non-null after a successful QR scan.
  StartingLocation? get startingLocation => _startingLocation;

  bool get hasManualPosition => _startingLocation != null;

  /// Sets the current location from a scanned starting point.
  void setFromStartingLocation(StartingLocation location) {
    _startingLocation = location;
    _position = location.toIndoorPosition();
    notifyListeners();
  }

  /// Adopts a live positioning estimate (only valid while no manual QR
  /// location is pinned).
  void updateFromLivePosition(IndoorPosition position) {
    if (hasManualPosition) return;
    _position = position;
    notifyListeners();
  }

  /// Clears any pinned QR location so live positioning resumes control.
  void clear() {
    _startingLocation = null;
    _position = null;
    notifyListeners();
  }
}
