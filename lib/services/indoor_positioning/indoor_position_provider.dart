// lib/services/indoor_positioning/indoor_position_provider.dart
import 'dart:async';

import 'ble_indoor_position_provider.dart';
import 'indoor_position.dart';
import 'mock_indoor_position_provider.dart';
import 'positioning_settings.dart';

/// Abstraction over the real-time indoor location source.
///
/// The FloorPlan UI only depends on this interface, so the mock provider
/// can be swapped for the BLE provider without touching the UI.
abstract class IndoorPositionProvider {
  /// Stream of position estimates. Broadcast; multiple listeners allowed.
  Stream<IndoorPosition> get positions;

  /// The most recent estimate, or null before the first update.
  IndoorPosition? get currentPosition;

  /// Starts acquiring positions. Idempotent.
  Future<void> start();

  /// Stops acquiring positions and releases timers/scanners. Idempotent.
  Future<void> stop();

  bool get isRunning;
}

/// Creates the provider selected in [PositioningSettings].
///
/// Currently defaults to [MockIndoorPositionProvider] so the whole app can
/// be developed and demonstrated without BLE hardware.
IndoorPositionProvider createPositionProvider() {
  switch (PositioningSettings.instance.mode) {
    case IndoorPositioningMode.ble:
      return BleIndoorPositionProvider();
    case IndoorPositioningMode.mock:
      return MockIndoorPositionProvider();
  }
}
