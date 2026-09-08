import 'package:flutter_test/flutter_test.dart';
import 'package:naviapp/services/indoor_positioning/indoor_position.dart';
import 'package:naviapp/services/indoor_positioning/mock_indoor_position_provider.dart';

void main() {
  group('MockIndoorPositionProvider', () {
    test('emits an initial position on start', () async {
      final provider = MockIndoorPositionProvider(
        updateInterval: const Duration(milliseconds: 10),
      );
      expect(provider.currentPosition, isNull);

      await provider.start();

      expect(provider.isRunning, isTrue);
      expect(provider.currentPosition, isNotNull);
      expect(provider.currentPosition!.source, PositionSource.mock);
      expect(provider.currentPosition!.x, inInclusiveRange(0.0, 1.0));
      expect(provider.currentPosition!.y, inInclusiveRange(0.0, 1.0));
      await provider.stop();
    });

    test('setPosition teleports and clamps coordinates', () async {
      final provider = MockIndoorPositionProvider();
      await provider.start();

      provider.setPosition(-1.0, 2.0, 1);

      expect(provider.currentPosition!.x, 0.0);
      expect(provider.currentPosition!.y, 1.0);
      expect(provider.currentPosition!.floor, 1);
      expect(provider.currentPosition!.source, PositionSource.mock);
      await provider.stop();
    });

    test(
      'walkTo moves the simulated user incrementally toward the target',
      () async {
        final provider = MockIndoorPositionProvider(
          updateInterval: const Duration(milliseconds: 10),
          walkSpeedUnitsPerSecond: 0.1,
        );
        await provider.start();
        provider.setPosition(0.5, 0.5, 0);

        final samples = <IndoorPosition>[];
        final sub = provider.positions.listen(samples.add);

        provider.walkTo(0.6, 0.5, 0);

        final deadline = DateTime.now().add(const Duration(seconds: 5));
        while (provider.currentPosition!.x < 0.599 &&
            DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }

        expect(provider.currentPosition!.x, closeTo(0.6, 0.01));
        expect(provider.currentPosition!.y, closeTo(0.5, 0.01));
        expect(provider.currentPosition!.floor, 0);
        // Movement was smooth: multiple intermediate samples, never backwards.
        expect(samples.length, greaterThan(1));
        for (int i = 1; i < samples.length; i++) {
          expect(samples[i].x, greaterThanOrEqualTo(samples[i - 1].x - 0.0001));
        }

        await sub.cancel();
        await provider.stop();
      },
    );

    test('walkTo can change the floor', () async {
      final provider = MockIndoorPositionProvider(
        updateInterval: const Duration(milliseconds: 10),
        walkSpeedUnitsPerSecond: 1.0,
      );
      await provider.start();
      provider.setPosition(0.5, 0.5, 0);

      provider.walkTo(0.5, 0.5, 2);

      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (provider.currentPosition!.floor != 2 &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(provider.currentPosition!.floor, 2);
      await provider.stop();
    });

    test('stop halts emission', () async {
      final provider = MockIndoorPositionProvider(
        updateInterval: const Duration(milliseconds: 10),
      );
      await provider.start();
      var count = 0;
      final sub = provider.positions.listen((_) => count++);

      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(count, greaterThan(0));
      final before = count;

      await provider.stop();
      expect(provider.isRunning, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(count, before);

      await sub.cancel();
    });

    test('start is idempotent', () async {
      final provider = MockIndoorPositionProvider();
      await provider.start();
      await provider.start();
      expect(provider.isRunning, isTrue);
      await provider.stop();
    });
  });
}
