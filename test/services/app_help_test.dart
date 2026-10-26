// test/services/app_help_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:naviapp/services/app_help.dart';

void main() {
  group('AppHelp.answerFor', () {
    test('greeting and thanks', () {
      expect(AppHelp.answerFor('hello'), contains('Hello'));
      expect(AppHelp.answerFor('Hi there'), contains('Hello'));
      expect(AppHelp.answerFor('thanks!'), contains('welcome'));
    });

    test('help overview lists capabilities', () {
      final reply = AppHelp.answerFor('help');
      expect(reply, contains('Scan'));
      expect(reply, contains('Floor Plan'));
      expect(reply, contains('Live Navigation'));
    });

    test('QR scan flow', () {
      final reply = AppHelp.answerFor('How do I scan a QR code?');
      expect(reply, contains('Scan Starting Point'));
      expect(reply, contains('You are here'));
    });

    test('QR troubleshooting', () {
      expect(
        AppHelp.answerFor('Invalid QR code, what now?'),
        contains('isn\'t one of ours'),
      );
      expect(
        AppHelp.answerFor('camera unavailable'),
        contains('camera permission'),
      );
    });

    test('indoor floor plan vs outdoor live nav routing', () {
      final indoor = AppHelp.answerFor('How do I navigate to a room?');
      expect(indoor, contains('Floor Plan'));
      final outdoor = AppHelp.answerFor('How does Live Navigation work?');
      expect(outdoor, contains('drop a red pin'));
    });

    test('building entry handoff', () {
      final reply = AppHelp.answerFor(
        'What happens when I enter a building?',
      );
      expect(reply, contains('Continue to the indoor map'));
    });

    test('entrances list who-may-use rules', () {
      final reply = AppHelp.answerFor('Which gate can vehicles use?');
      expect(reply, contains('Gate 2'));
      expect(reply, contains('Gate 3'));
    });

    test('voice, dark mode, styles', () {
      expect(AppHelp.answerFor('how to mute voice replies'), contains('speaker'));
      expect(AppHelp.answerFor('dark mode'), contains('sun/moon'));
      expect(AppHelp.answerFor('change map style'), contains('layers'));
    });

    test('troubleshooting: blank map, offline, permissions, no path', () {
      expect(AppHelp.answerFor('map is blank'), contains('internet'));
      expect(AppHelp.answerFor('no internet'), contains('STILL WORKS'));
      expect(
        AppHelp.answerFor('location permission blocked'),
        contains('Open Settings'),
      );
      expect(
        AppHelp.answerFor('no accessible path'),
        contains('don\'t connect'),
      );
    });

    test('directions requests point at the right screens', () {
      // Indoor-style request gets full indoor steps.
      final indoor = AppHelp.answerFor('Navigate to the Library');
      expect(indoor, contains('Floor Plan'));
      // Open "where is" query gets the both-screens redirect.
      final redirect = AppHelp.answerFor('Where is the library?');
      expect(redirect, contains('Floor Plan'));
      expect(redirect, contains('Live Navigation'));
    });

    test('unknown queries get guided fallback, never empty', () {
      final reply = AppHelp.answerFor('blarg wibble zzz');
      expect(reply.isNotEmpty, isTrue);
      expect(reply, contains('How do I scan'));
    });
  });
}
