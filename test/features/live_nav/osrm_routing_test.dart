// test/features/live_nav/osrm_routing_test.dart
//
// Verifies OSRM response parsing, instruction building, and error mapping
// with mocked HTTP. No platform plugins involved, so these run on the VM.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:naviapp/features/live_navigation/models/geo_math.dart';
import 'package:naviapp/features/live_navigation/providers/routing/osrm_routing_service.dart';
import 'package:naviapp/features/live_navigation/services/nav_errors.dart';

const _osrmPayload = {
  'code': 'Ok',
  'routes': [
    {
      'weight_name': 'auto',
      'distance': 1500.5,
      'duration': 300.2,
      'geometry': '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
      'legs': [
        {
          'distance': 1500.5,
          'duration': 300.2,
          'steps': [
            {
              'distance': 800.0,
              'duration': 150.0,
              'geometry': '_p~iF~ps|U',
              'name': 'Main St',
              'maneuver': {
                'type': 'turn',
                'modifier': 'right',
                'location': [123.0, 8.0],
              },
            },
            {
              'distance': 700.5,
              'duration': 150.2,
              'geometry': '_ulLnnqC_mqNvxq`@',
              'name': '',
              'maneuver': {
                'type': 'arrive',
                'location': [123.01, 8.01],
              },
            },
          ],
        },
      ],
    },
    {
      'weight_name': 'auto',
      'distance': 1800.0,
      'duration': 360.0,
      'geometry': '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
      'legs': [],
    },
  ],
};

void main() {
  group('OsrmRoutingService', () {
    test('parses primary + alternative routes with instructions', () async {
      final client = MockClient((request) async {
        // OSRM v1 route endpoint shape.
        expect(request.url.path, contains('/route/v1/driving/'));
        expect(
          request.url.queryParameters['alternatives'],
          'true',
        );
        return http.Response(jsonEncode(_osrmPayload), 200);
      });
      final service = OsrmRoutingService(
        client: client,
        baseUrl: 'https://example.test',
      );
      final options = await service.computeRoutes(
        origin: const NavLatLng(8.0, 123.0),
        destination: const NavLatLng(8.1, 123.1),
      );
      expect(options.length, 2);
      expect(options.first.distanceMeters, closeTo(1500.5, 0.01));
      expect(options.first.durationSeconds, 300);
      expect(options.first.steps.length, 2);
      expect(
        options.first.steps.first.instruction,
        'Turn right onto Main St',
      );
      expect(options.first.steps.first.maneuverLabel, 'Turn Right');
      expect(options.first.steps.last.instruction, contains('arrived'));
      expect(options.first.trackingPoints, isNotEmpty);
    });

    test('maps NoRoute code to routeNotFound', () async {
      final client = MockClient(
        (_) async => http.Response(jsonEncode({'code': 'NoRoute'}), 200),
      );
      final service = OsrmRoutingService(
        client: client,
        baseUrl: 'https://example.test',
      );
      expect(
        () => service.computeRoutes(
          origin: const NavLatLng(8.0, 123.0),
          destination: const NavLatLng(8.1, 123.1),
        ),
        throwsA(
          isA<NavError>().having((e) => e.kind, 'kind', NavErrorKind.routeNotFound),
        ),
      );
    });

    test('maps 429 to rateLimited and transport errors to noInternet',
        () async {
      final throttled = OsrmRoutingService(
        client: MockClient((_) async => http.Response('busy', 429)),
        baseUrl: 'https://example.test',
      );
      expect(
        () => throttled.computeRoutes(
          origin: const NavLatLng(8.0, 123.0),
          destination: const NavLatLng(8.1, 123.1),
        ),
        throwsA(
          isA<NavError>().having((e) => e.kind, 'kind', NavErrorKind.rateLimited),
        ),
      );

      final offline = OsrmRoutingService(
        client: MockClient(
          (_) async => throw const SocketLikeException(),
        ),
        baseUrl: 'https://example.test',
      );
      expect(
        () => offline.computeRoutes(
          origin: const NavLatLng(8.0, 123.0),
          destination: const NavLatLng(8.1, 123.1),
        ),
        throwsA(
          isA<NavError>().having((e) => e.kind, 'kind', NavErrorKind.noInternet),
        ),
      );
    });
  });
}

/// Minimal socket-failure stand-in whose message matches what the service
/// maps to [NavErrorKind.noInternet].
class SocketLikeException implements Exception {
  const SocketLikeException();

  @override
  String toString() => 'SocketException: Failed host lookup';
}
