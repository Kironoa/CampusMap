// lib/services/indoor_positioning/ble_indoor_position_provider.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:permission_handler/permission_handler.dart';

import 'beacon_config.dart';
import 'beacon_parser.dart';
import 'indoor_position.dart';
import 'indoor_position_provider.dart';
import 'position_estimator.dart';
import 'position_filter.dart';
import 'positioning_settings.dart';
import 'rssi_buffer.dart';

/// Real-time position from BLE beacon scanning.
///
/// Pipeline per advertisement: iBeacon parse → configured-beacon match →
/// RSSI buffering (averaged) → weighted-centroid estimation → EMA smoothing
/// → [positions] stream, throttled to [PositioningSettings.positionUpdateInterval].
///
/// Every platform interaction (permissions, BLE support, adapter state,
/// scan start/stop, result stream) is injectable so the provider logic can
/// be tested without BLE hardware.
class BleIndoorPositionProvider implements IndoorPositionProvider {
  BleIndoorPositionProvider({
    Future<bool> Function()? ensurePermissions,
    Future<bool> Function()? platformIsSupported,
    bool Function()? adapterIsOn,
    Future<void> Function()? startScan,
    Future<void> Function()? stopScan,
    Stream<List<fbp.ScanResult>>? scanResults,
    RssiBuffer? buffer,
  }) : _ensurePermissionsOverride = ensurePermissions,
       _platformIsSupportedOverride = platformIsSupported,
       _adapterIsOnOverride = adapterIsOn,
       _startScanOverride = startScan,
       _stopScanOverride = stopScan,
       _scanResultsOverride = scanResults,
       _buffer = buffer ?? RssiBuffer();

  final StreamController<IndoorPosition> _controller =
      StreamController<IndoorPosition>.broadcast();
  final Future<bool> Function()? _ensurePermissionsOverride;
  final Future<bool> Function()? _platformIsSupportedOverride;
  final bool Function()? _adapterIsOnOverride;
  final Future<void> Function()? _startScanOverride;
  final Future<void> Function()? _stopScanOverride;
  final Stream<List<fbp.ScanResult>>? _scanResultsOverride;
  final RssiBuffer _buffer;

  IndoorPosition? _current;
  StreamSubscription<List<fbp.ScanResult>>? _scanSub;
  DateTime? _lastEmitAt;
  bool _running = false;

  @override
  Stream<IndoorPosition> get positions => _controller.stream;

  @override
  IndoorPosition? get currentPosition => _current;

  @override
  bool get isRunning => _running;

  @override
  Future<void> start() async {
    if (_running) return;

    final ensurePermissions =
        _ensurePermissionsOverride ?? _defaultEnsurePermissions;
    if (!await ensurePermissions()) {
      _fail(
        'Bluetooth or location permission was denied. '
        'Indoor positioning needs it to scan for beacons.',
      );
      return;
    }

    final isSupported = _platformIsSupportedOverride ?? _defaultIsSupported;
    if (!await isSupported()) {
      _fail('Bluetooth is not supported on this device.');
      return;
    }

    final adapterIsOn = _adapterIsOnOverride ?? _defaultAdapterIsOn;
    if (!adapterIsOn() && _adapterIsOnOverride == null) {
      if (Platform.isAndroid) {
        try {
          await fbp.FlutterBluePlus.turnOn();
        } catch (_) {
          _fail('Bluetooth is off. Turn it on to use indoor positioning.');
          return;
        }
      } else {
        _fail('Bluetooth is off. Turn it on to use indoor positioning.');
        return;
      }
    }

    _running = true;
    _buffer.clear();

    final startScan = _startScanOverride ?? _defaultStartScan;
    try {
      await startScan();
    } catch (e) {
      _running = false;
      _fail('Could not start Bluetooth scanning: $e');
      return;
    }

    _scanSub = (_scanResultsOverride ?? fbp.FlutterBluePlus.scanResults).listen(
      _onScanResults,
      onError: (Object e) => _fail('Bluetooth scan error: $e'),
    );
  }

  @override
  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    await _scanSub?.cancel();
    _scanSub = null;
    // Only touch the real scanner when we are not running on injected data.
    if (_scanResultsOverride == null && _startScanOverride == null) {
      final stopScan = _stopScanOverride ?? _defaultStopScan;
      await stopScan();
    }
    _buffer.clear();
    _lastEmitAt = null;
  }

  void _onScanResults(List<fbp.ScanResult> results) {
    for (final result in results) {
      _onScanResult(result);
    }
  }

  void _onScanResult(fbp.ScanResult result) {
    if (!PositionEstimator.isUsableRssi(result.rssi.toDouble())) return;

    final packet = BeaconParser.parseIBeacon(
      result.advertisementData.manufacturerData,
    );
    if (packet == null) return;
    if (BeaconConfig.beaconById(packet.beaconId) == null) return;

    _buffer.add(packet.beaconId, result.rssi.toDouble());
    _maybeEmit();
  }

  void _maybeEmit() {
    final now = DateTime.now();
    final interval = PositioningSettings.instance.positionUpdateInterval;
    if (_lastEmitAt != null && now.difference(_lastEmitAt!) < interval) {
      return;
    }

    final readings = _buffer.readings();
    if (readings.length < BeaconConfig.minBeaconsForFix) return;

    final estimate = PositionEstimator.estimatePosition(
      readings: readings,
      beacons: BeaconConfig.beacons,
    );
    if (!estimate.hasFix) return;

    _lastEmitAt = now;
    final raw = estimate.position!;
    final smoothed = PositionFilter.ema(
      previous: _current,
      next: raw,
      alpha: PositioningSettings.instance.bleFilterAlpha,
    );
    _current = smoothed;
    _controller.add(smoothed);
  }

  void _fail(String message) {
    // The screen listens to the stream and surfaces this as a SnackBar.
    _controller.addError(StateError(message));
  }

  /// Requests the runtime permissions required to scan for beacons.
  ///
  /// - Android 12+: `BLUETOOTH_SCAN` + `BLUETOOTH_CONNECT`.
  /// - Android 6..11: location (BLE scanning is gated behind it).
  /// - iOS: Bluetooth + location-in-use.
  static Future<bool> _defaultEnsurePermissions() async {
    if (Platform.isIOS) {
      final bluetooth = await Permission.bluetooth.request();
      final location = await Permission.locationWhenInUse.request();
      return bluetooth.isGranted && location.isGranted;
    }
    if (Platform.isAndroid) {
      final sdk = _androidSdkVersion();
      if (sdk >= 31) {
        final scan = await Permission.bluetoothScan.request();
        final connect = await Permission.bluetoothConnect.request();
        return scan.isGranted && connect.isGranted;
      }
      final location = await Permission.location.request();
      return location.isGranted;
    }
    return false;
  }

  static Future<bool> _defaultIsSupported() => fbp.FlutterBluePlus.isSupported;

  static bool _defaultAdapterIsOn() =>
      fbp.FlutterBluePlus.adapterStateNow == fbp.BluetoothAdapterState.on;

  static Future<void> _defaultStartScan() => fbp.FlutterBluePlus.startScan(
    timeout: Duration.zero, // keep scanning until stop() is called
    continuousUpdates: true,
    oneByOne: true,
    continuousDivisor: 1,
    androidScanMode: fbp.AndroidScanMode.lowLatency,
  );

  static Future<void> _defaultStopScan() => fbp.FlutterBluePlus.stopScan();

  /// Parses the Android API level from `Platform.operatingSystemVersion`
  /// (e.g. "Android 14 (SDK 34)"). Returns 0 when it cannot be determined.
  static int _androidSdkVersion() {
    final version = Platform.operatingSystemVersion;
    final match = RegExp(r'SDK\s*(\d+)').firstMatch(version);
    if (match != null) return int.tryParse(match.group(1)!) ?? 0;
    return 0;
  }
}
