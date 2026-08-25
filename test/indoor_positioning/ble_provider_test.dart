// test/indoor_positioning/ble_provider_test.dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:flutter_test/flutter_test.dart';
import 'package:naviapp/services/indoor_positioning/beacon_parser.dart';
import 'package:naviapp/services/indoor_positioning/ble_indoor_position_provider.dart';
import 'package:naviapp/services/indoor_positioning/indoor_position.dart';
import 'package:naviapp/services/indoor_positioning/indoor_position_provider.dart';
import 'package:naviapp/services/indoor_positioning/positioning_settings.dart';

void main() {
  // Standard iBeacon test UUID (lowercase, as the parser emits it).
  const uuid = 'e2c56db5-dffb-48d2-b060-d0f5a71096e0';
  final uuidBytes = Uint8List.fromList([
    0xE2, 0xC5, 0x6D, 0xB5, 0xDF, 0xFB, 0x48, 0xD2, //
    0xB0, 0x60, 0xD0, 0xF5, 0xA7, 0x10, 0x96, 0xE0,
  ]);

  List<int> payload(int major, int minor, int txPower) => [
        0x02, 0x15, //
        ...uuidBytes,
        (major >> 8) & 0xFF, major & 0xFF,
        (minor >> 8) & 0xFF, minor & 0xFF,
        txPower & 0xFF,
      ];

  fbp.ScanResult advertisement({
    required String beaconId,
    required int rssi,
    required int txPower,
  }) {
    final parts = beaconId.split(':');
    final major = int.parse(parts[1]);
    final minor = int.parse(parts[2]);
    return fbp.ScanResult(
      device: fbp.BluetoothDevice(
        remoteId: fbp.DeviceIdentifier(beaconId),
      ),
      advertisementData: fbp.AdvertisementData(
        advName: '',
        txPowerLevel: null,
        appearance: null,
        connectable: false,
        manufacturerData: {
          BeaconParser.appleCompanyId: payload(major, minor, txPower),
        },
        serviceData: const {},
        serviceUuids: const [],
      ),
      rssi: rssi,
      timeStamp: DateTime.now(),
    );
  }

  BleIndoorPositionProvider providerWith(
    StreamController<List<fbp.ScanResult>> controller, {
    Future<bool> Function()? ensurePermissions,
  }) {
    return BleIndoorPositionProvider(
      ensurePermissions: ensurePermissions ?? () async => true,
      platformIsSupported: () async => true,
      adapterIsOn: () => true,
      startScan: () async {},
      stopScan: () async {},
      scanResults: controller.stream,
    );
  }

  test('emits a smoothed ble position from iBeacon advertisements', () async {
    final controller = StreamController<List<fbp.ScanResult>>();
    final provider = providerWith(controller);
    final positions = <dynamic>[];
    final sub = provider.positions.listen(positions.add, onError: (Object e) => fail('$e'));

    await provider.start();
    expect(provider.isRunning, isTrue);

    // Three beacons on floor 0 (near the .2,.3 corridor beacon → stronger).
    controller.add([
      advertisement(beaconId: '$uuid:1:1', rssi: -45, txPower: -59),
      advertisement(beaconId: '$uuid:1:2', rssi: -55, txPower: -59),
      advertisement(beaconId: '$uuid:1:3', rssi: -65, txPower: -59),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(positions, isNotEmpty);
    // NOTE: keep this statically typed — dynamic dispatch on enum `.name`
    // throws NoSuchMethodError in the Dart VM.
    final position = positions.last as IndoorPosition;
    expect(position.source, PositionSource.ble);
    expect(position.floor, 0);
    expect(position.x, inInclusiveRange(0.0, 1.0));
    expect(position.y, inInclusiveRange(0.0, 1.0));
    expect(position.accuracy, greaterThan(0));

    await provider.stop();
    expect(provider.isRunning, isFalse);
    await sub.cancel();
    await controller.close();
  });

  test('ignores advertisements from unconfigured beacons', () async {
    final controller = StreamController<List<fbp.ScanResult>>();
    final provider = providerWith(controller);
    final positions = <dynamic>[];
    final sub = provider.positions.listen(positions.add, onError: (Object e) => fail('$e'));

    await provider.start();
    // Unknown major/minor: not in BeaconConfig.
    controller.add([
      advertisement(beaconId: '$uuid:99:99', rssi: -45, txPower: -59),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(positions, isEmpty);

    await provider.stop();
    await sub.cancel();
    await controller.close();
  });

  test('does not emit while below minBeaconsForFix', () async {
    final controller = StreamController<List<fbp.ScanResult>>();
    final provider = providerWith(controller);
    final positions = <dynamic>[];
    final sub = provider.positions.listen(positions.add, onError: (Object e) => fail('$e'));

    await provider.start();
    controller.add([
      advertisement(beaconId: '$uuid:1:1', rssi: -45, txPower: -59),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(positions, isEmpty);

    await provider.stop();
    await sub.cancel();
    await controller.close();
  });

  test('surfaces an error when permissions are denied', () async {
    final controller = StreamController<List<fbp.ScanResult>>();
    final provider = providerWith(controller, ensurePermissions: () async => false);
    final errors = <Object>[];
    final sub = provider.positions.listen((_) {}, onError: errors.add);

    await provider.start();
    expect(provider.isRunning, isFalse);
    // Error delivery on a broadcast stream is asynchronous.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(errors, isNotEmpty);

    await sub.cancel();
    // Note: controller.close() is deliberately skipped here — after an
    // error was delivered on a broadcast controller, awaiting close()
    // never completes in the test VM. Production code never closes it.
  });

  test('the factory creates a BleIndoorPositionProvider in ble mode',
      () async {
    PositioningSettings.instance.mode = IndoorPositioningMode.ble;
    addTearDown(() => PositioningSettings.instance.mode = IndoorPositioningMode.mock);

    final provider = createPositionProvider();
    expect(provider, isA<BleIndoorPositionProvider>());
  });
}
