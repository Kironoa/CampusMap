// test/features/live_nav/campus_routing_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:naviapp/features/live_navigation/config/campus_buildings.dart';
import 'package:naviapp/models/user_role.dart';
import 'package:naviapp/features/live_navigation/models/geo_math.dart';
import 'package:naviapp/features/live_navigation/models/nav_route.dart';
import 'package:naviapp/features/live_navigation/providers/routing/campus_routing_service.dart';
import 'package:naviapp/features/live_navigation/providers/routing/routing_service.dart';

const _campusBoundary = <NavLatLng>[
  NavLatLng(8.06441, 123.75838),
  NavLatLng(8.06615, 123.75696),
  NavLatLng(8.06444, 123.75502),
  NavLatLng(8.06271, 123.75648),
];

class _FakeRoutingService implements RoutingService {
  _FakeRoutingService(this.onRoute);

  final List<NavRouteOption> Function(NavLatLng origin, NavLatLng destination)
  onRoute;
  int calls = 0;

  @override
  Future<List<NavRouteOption>> computeRoutes({
    required NavLatLng origin,
    required NavLatLng destination,
  }) async {
    calls++;
    return onRoute(origin, destination);
  }
}

NavRouteOption _route(List<NavLatLng> points) {
  final distance = GeoMath.polylineLength(points);
  return NavRouteOption(
    summary: 'Test route',
    distanceMeters: distance,
    durationSeconds: (distance / 1.4).round(),
    overviewPoints: points,
    steps: [
      NavRouteStep(
        instruction: 'Walk',
        maneuver: 'continue',
        distanceMeters: distance,
        durationSeconds: (distance / 1.4).round(),
        points: points,
      ),
    ],
  );
}

bool _insideCampus(NavLatLng point) {
  return CampusBuildings.isPointInRing(point, _campusBoundary);
}

void main() {
  final annex = CampusBuildings.annexBuilding.labelPoint;
  final main = CampusBuildings.mainBuilding.labelPoint;

  test('inside to Annex uses the internal pathway without OSRM', () async {
    final fake = _FakeRoutingService(
      (_, __) => throw StateError('OSRM must not be used for MB to AB'),
    );
    final service = CampusRoutingService(osrmService: fake);

    final routes = await service.computeRoutes(
      origin: main,
      destination: annex,
    );

    expect(routes, hasLength(1));
    final route = routes.single;
    expect(fake.calls, 0);
    expect(route.overviewPoints.first, main);
    expect(route.overviewPoints.last, annex);
    expect(
      route.overviewPoints,
      contains(CampusRoutingService.mbToAbPath.last),
    );
    for (final point in route.overviewPoints) {
      expect(_insideCampus(point), isTrue, reason: '$point is outside campus');
    }
  });

  test('outside to Annex enters through a gate and ends inside', () async {
    const outside = NavLatLng(8.06630, 123.75695);
    final gate = CampusEntrances.all.where((gate) => gate.walkInEntry).toList()
      ..sort(
        (a, b) => GeoMath.distanceMeters(
          outside,
          a.location,
        ).compareTo(GeoMath.distanceMeters(outside, b.location)),
      );
    final expectedGate = gate.first;
    const outsideBesideAnnex = NavLatLng(8.065332, 123.757734);

    final fake = _FakeRoutingService((origin, destination) {
      if (destination == expectedGate.location) {
        return [
          _route([origin, expectedGate.location]),
        ];
      }
      return [
        _route([origin, outsideBesideAnnex]),
      ];
    });
    final service = CampusRoutingService(osrmService: fake);

    final routes = await service.computeRoutes(
      origin: outside,
      destination: annex,
    );

    expect(routes, hasLength(1));
    final route = routes.single;
    expect(route.overviewPoints.first, outside);
    expect(route.overviewPoints.last, annex);
    expect(route.overviewPoints, contains(expectedGate.location));
    expect(route.summary, contains(expectedGate.name));
    expect(
      route.steps.any(
        (step) => step.instruction == 'Pass through ${expectedGate.name}',
      ),
      isTrue,
    );
    for (final point in route.overviewPoints.skip(2)) {
      expect(_insideCampus(point), isTrue, reason: '$point is outside campus');
    }
  });

  test('inside to outside keeps origin -> gate -> destination order', () async {
    const outside = NavLatLng(8.06630, 123.75695);
    final fake = _FakeRoutingService(
      (origin, destination) => [
        _route([origin, destination]),
      ],
    );
    final service = CampusRoutingService(osrmService: fake);

    final routes = await service.computeRoutes(
      origin: main,
      destination: outside,
    );

    expect(routes, hasLength(1));
    final route = routes.single;
    expect(route.overviewPoints.first, main);
    expect(route.overviewPoints.last, outside);
    expect(route.summary, contains('Via Gate'));
    expect(
      route.steps.any((step) => step.instruction.startsWith('Pass through')),
      isTrue,
    );
  });

  test('exiting skips entrance-only gates', () async {
    const outside = NavLatLng(8.06476, 123.75510);
    final service = CampusRoutingService(
      osrmService: _FakeRoutingService(
        (origin, destination) => [
          _route([origin, destination]),
        ],
      ),
    );

    final route = (await service.computeRoutes(
      origin: main,
      destination: outside,
    )).single;

    final allowed = CampusEntrances.all.where((gate) => gate.walkInExit);
    expect(route.summary, isNot('Via Gate 1'));
    expect(route.summary, isNot('Via Gate 2'));
    expect(allowed.any((gate) => route.summary == 'Via ${gate.name}'), isTrue);
  });

  test('entering skips exit-only and vehicle-only gates', () async {
    final outside = CampusEntrances.entrance4.location;
    final service = CampusRoutingService(
      osrmService: _FakeRoutingService(
        (origin, destination) => [
          _route([origin, destination]),
        ],
      ),
    );

    final route = (await service.computeRoutes(
      origin: outside,
      destination: main,
    )).single;

    final allowed = CampusEntrances.all.where((gate) => gate.walkInEntry);
    expect(route.summary, isNot('Via Gate 2'));
    expect(route.summary, isNot('Via Gate 4'));
    expect(allowed.any((gate) => route.summary == 'Via ${gate.name}'), isTrue);
  });

  test('student entry never uses Gate 3', () async {
    const outside = NavLatLng(8.06630, 123.75695);
    final requestedGates = <NavLatLng>[];
    final service = CampusRoutingService(
      role: UserRole.student,
      osrmService: _FakeRoutingService((origin, destination) {
        requestedGates.add(destination);
        return [
          _route([origin, destination]),
        ];
      }),
    );

    await service.computeRoutes(origin: outside, destination: main);

    expect(requestedGates, isNot(contains(CampusEntrances.entrance3.location)));
    expect(requestedGates, isNot(contains(CampusEntrances.entrance4.location)));
  });

  test('faculty entry never uses Gate 1', () async {
    const outside = NavLatLng(8.06630, 123.75695);
    final requestedGates = <NavLatLng>[];
    final service = CampusRoutingService(
      role: UserRole.faculty,
      osrmService: _FakeRoutingService((origin, destination) {
        requestedGates.add(destination);
        return [
          _route([origin, destination]),
        ];
      }),
    );

    await service.computeRoutes(origin: outside, destination: main);

    expect(requestedGates, isNot(contains(CampusEntrances.entrance1.location)));
  });
}
