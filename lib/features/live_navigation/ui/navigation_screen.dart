// lib/features/live_navigation/ui/navigation_screen.dart
//
// Live Navigation screen: MapLibre map, GPS position, tap-to-set
// destination, campus routes (with custom pathways), on-device turn-by-turn guidance.
//
// The screen depends ONLY on provider abstractions ([MapProvider],
// [LocationProvider], [RoutingService]) — never on maplibre, geolocator,
// OSRM, or any backend directly. Swap implementations by injecting
// different providers (see constructors).
//
// Routing uses [CampusRoutingService] which wraps OSRM and adds
// campus-specific pathways (e.g., Main Building ↔ Annex Building).
//
// Invariant: nothing outside lib/features/live_navigation/ may depend on
// this file (except the single HomeScreen entry point), so the feature can
// be disabled via [LiveNavFeatureFlag] or deleted outright.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:naviapp/models/user_role.dart';
import 'package:naviapp/screens/floor_plan_screen.dart';

import '../config/campus_buildings.dart';
import '../config/nav_config.dart';
import '../config/nav_theme.dart';
import '../live_navigation.dart' show LiveNavFeatureFlag;
import '../models/geo_math.dart';
import '../models/nav_route.dart';
import '../models/navigation_state.dart';
import '../providers/location/geolocator_location_provider.dart';
import '../providers/location/location_provider.dart';
import '../providers/map/map_provider.dart';
import '../providers/map/maplibre_map_provider.dart';
import '../providers/routing/campus_routing_service.dart';
import '../providers/routing/routing_service.dart';
import '../services/guidance_engine.dart';
import '../services/nav_errors.dart';
import 'widgets/destination_bar.dart';
import 'widgets/guidance_banner.dart';
import 'widgets/trip_panel.dart';

class LiveNavigationScreen extends StatefulWidget {
  const LiveNavigationScreen({
    super.key,
    MapProvider? mapProvider,
    LocationProvider? locationProvider,
    RoutingService? routingService,
    this.initialPosition,
    this.initialDestination,
    this.userRole,
  }) : _mapProvider = mapProvider,
       _locationProvider = locationProvider,
       _routingService = routingService;

  final MapProvider? _mapProvider;
  final LocationProvider? _locationProvider;
  final RoutingService? _routingService;

  /// Optional outdoor GPS coordinate to use as the starting position instead of waiting for GPS.
  /// When provided, this is used immediately for routing and map centering.
  final NavLatLng? initialPosition;

  /// Optional destination to route to as soon as the current position is known.
  final NavDestination? initialDestination;

  /// Role selected during onboarding; controls which gates may be used.
  final UserRole? userRole;

  @override
  State<LiveNavigationScreen> createState() => _LiveNavigationScreenState();
}

class _LiveNavigationScreenState extends State<LiveNavigationScreen> {
  late final MapProvider _maps = widget._mapProvider ?? MapLibreMapProvider();
  late final LocationProvider _location =
      widget._locationProvider ?? GeolocatorLocationProvider();
  late final RoutingService _routing =
      widget._routingService ?? CampusRoutingService(role: widget.userRole);
  final GuidanceEngine _guidance = GuidanceEngine();

  NavMapController? _mapController;
  StreamSubscription<NavFix>? _positionSub;

  NavPhase _phase = NavPhase.idle;
  LocationReadiness? _readiness;
  NavFix? _lastFix;
  DateTime? _lastGuidanceAt;

  NavDestination? _destination;
  List<NavRouteOption> _options = const [];
  int _selectedOption = 0;

  bool _isLoadingRoute = false;
  bool _isRerouting = false;
  bool _initialRouteRequested = false;
  String? _notice;

  TripProgress? _progress;
  bool _followUser = true;

  bool _orientationCaptured = false;
  bool _restoreLandscape = false;

  // --- Building geofence (outdoor -> indoor handoff) -----------------------
  // Consecutive-fix hysteresis + cooldown so a single noisy GPS fix never
  // pops the dialog, and dismissing it doesn't nag until exit + re-entry.
  int _insideStreak = 0;
  int _outsideStreak = 0;
  String? _insideBuildingId;
  bool _buildingPromptOpen = false;
  DateTime? _lastBuildingPromptAt;

  /// Base-map style state. Tiles need internet; until the style loads the
  /// map surface is blank, so we show a loader — and after a grace period
  /// a hint pointing at the network instead of failing silently.
  bool _styleLoaded = false;
  bool _mapSlow = false;
  Timer? _styleTimer;

  /// Available map appearances + current selection (style button cycles).
  late final List<MapStylePreset> _styles = navStylePresets();
  int _styleIndex = 0;

  /// Zoom-based auto style switching.
  /// When zoomed in past this level, switch to terrain; when zoomed out, back to satellite.
  static const double _terrainZoomThreshold = 16.5;
  bool _autoStyleSwitchEnabled = true;
  bool _isTerrainMode = false;

  @override
  void initState() {
    super.initState();
    assert(
      LiveNavFeatureFlag.enabled,
      'LiveNavigationScreen opened while the feature flag is off.',
    );
    _destination = widget.initialDestination;
    _restartStyleTimer();
    _initLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_orientationCaptured) return;
    _orientationCaptured = true;
    _restoreLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    _styleTimer?.cancel();
    _positionSub?.cancel();
    SystemChrome.setPreferredOrientations(
      _restoreLandscape
          ? const [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : const [DeviceOrientation.portraitUp],
    );
    super.dispose();
  }

  // --- Location ------------------------------------------------------------

  Future<void> _initLocation() async {
    // If an initial position was provided (e.g., from a QR scan), use it immediately
    // for map centering and routing, skipping the GPS wait.
    if (widget.initialPosition != null) {
      final initialFix = NavFix(
        latitude: widget.initialPosition!.latitude,
        longitude: widget.initialPosition!.longitude,
        accuracyM: 5.0, // High accuracy for QR-scanned position
        speedMps: 0.0,
        headingDeg: 0.0,
        timestamp: DateTime.now(),
      );
      if (!mounted) return;
      setState(() {
        _lastFix = initialFix;
        _readiness = LocationReadiness.ready;
      });
      _mapController?.animateTo(target: widget.initialPosition!, zoom: 16);
      _showNotice(
        'Starting from QR location: ${widget.initialPosition!.latitude.toStringAsFixed(6)}, ${widget.initialPosition!.longitude.toStringAsFixed(6)}',
      );
      _maybeLoadInitialRoute();
      // Still start listening to GPS for live updates during navigation
      _positionSub = _location.liveFixes().listen(_onFix, onError: (_) {});
      return;
    }

    // Any failure here (e.g. a platform error on the very first permission
    // grant) must degrade to the GPS gate — never an unhandled exception.
    LocationReadiness readiness;
    try {
      readiness = await _location.ensureReady();
    } catch (e) {
      if (!mounted) return;
      setState(() => _readiness = LocationReadiness.denied);
      _showNotice('Could not check location status ($e).');
      return;
    }
    if (!mounted) return;
    setState(() => _readiness = readiness);
    if (readiness != LocationReadiness.ready) return;
    try {
      final fix = await _location.currentFix();
      if (!mounted) return;
      setState(() => _lastFix = fix);
      _mapController?.animateTo(
        target: NavLatLng(fix.latitude, fix.longitude),
        zoom: 16,
      );
      _checkBuildingGeofence(fix);
      _maybeLoadInitialRoute();
    } on NavError catch (e) {
      _showNotice(e.friendlyMessage);
    }
    _positionSub = _location.liveFixes().listen(
      _onFix,
      onError: (_) {
        // Stream errors are non-fatal; the last fix stays on screen.
      },
    );
  }

  void _onFix(NavFix fix) {
    if (!mounted) return;
    setState(() => _lastFix = fix);
    // Geofence runs in every phase (idle/preview/navigating) so entering
    // the building always offers the indoor map. Guidance below stays
    // navigating-only as before.
    _checkBuildingGeofence(fix);
    _maybeLoadInitialRoute();

    if (_phase != NavPhase.navigating || _options.isEmpty) return;
    final now = DateTime.now();
    final lastAt = _lastGuidanceAt;
    if (lastAt != null &&
        now.difference(lastAt) < NavConfig.minGuidanceInterval) {
      return; // throttle: never reroute on every GPS update
    }
    _lastGuidanceAt = now;

    final snapshot = _guidance.update(
      position: NavLatLng(fix.latitude, fix.longitude),
      speedMps: fix.speedMps,
      now: now,
    );
    setState(() {
      _progress = TripProgress(
        instruction: snapshot.instruction,
        maneuverLabel: snapshot.maneuverLabel,
        distanceToManeuverM: snapshot.distanceToManeuverM,
        remainingDistanceM: snapshot.remainingDistanceM,
        eta: snapshot.eta,
        offRoute: snapshot.offRoute,
        arrived: snapshot.arrived,
      );
    });

    if (snapshot.arrived) {
      _onArrive();
      return;
    }
    if (_guidance.takeRerouteSignal(now)) {
      _reroute();
      return;
    }
    if (_followUser) {
      _mapController?.animateTo(
        target: NavLatLng(fix.latitude, fix.longitude),
        zoom: 16.5,
        bearing: fix.headingDeg,
        tilt: 50,
      );
    }
  }

  // --- Destination + routing -------------------------------------------------

  void _onMapTap(NavLatLng point) {
    if (_phase == NavPhase.navigating) return; // avoid accidental retarget
    // Tapping an entrance gate opens its info card (access rules +
    // "Navigate here"). Checked before buildings: gates are small targets.
    final entrance = CampusEntrances.nearestWithin(point);
    if (entrance != null) {
      _showEntranceCard(entrance, point);
      return;
    }
    // Tapping a building footprint opens its photo card instead of dropping
    // a pin — the card offers "Navigate here" for routing to the building.
    final building = CampusBuildings.containing(point);
    if (building != null) {
      _showBuildingPhoto(building, point);
      return;
    }
    setState(() {
      _destination = NavDestination(label: 'Dropped pin', location: point);
      _notice = null;
    });
    _loadRoutes();
  }

  /// Partial-screen info card for a tapped gate (name + access rules +
  /// navigate shortcut). Never full-screen — the map stays visible behind.
  void _showEntranceCard(CampusEntrance entrance, NavLatLng point) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: NavTheme.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.login_rounded,
                        color: NavTheme.accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entrance.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  entrance.access,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      setState(() {
                        _destination = NavDestination(
                          label: entrance.name,
                          location: point,
                        );
                        _notice = null;
                      });
                      _loadRoutes();
                    },
                    icon: const Icon(Icons.navigation),
                    label: const Text('Navigate here'),
                    style: FilledButton.styleFrom(
                      backgroundColor: NavTheme.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Partial-screen photo card for a tapped building (photo + name +
  /// navigate shortcut). Never full-screen — the map stays visible behind.
  void _showBuildingPhoto(CampusBuilding building, NavLatLng point) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    child: Image.asset(
                      building.imageAsset,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: NavTheme.buildingOutline.withValues(alpha: 0.12),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.domain_outlined,
                          size: 64,
                          color: NavTheme.buildingOutline,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(sheetContext).pop(),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      building.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          setState(() {
                            _destination = NavDestination(
                              label: building.name,
                              location: point,
                            );
                            _notice = null;
                          });
                          _loadRoutes();
                        },
                        icon: const Icon(Icons.navigation),
                        label: const Text('Navigate here'),
                        style: FilledButton.styleFrom(
                          backgroundColor: NavTheme.accent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onCoordinates(NavLatLng point) {
    if (_phase == NavPhase.navigating) return;
    setState(() {
      _destination = NavDestination(
        label: 'Custom coordinates',
        location: point,
      );
      _notice = null;
    });
    _loadRoutes();
  }

  void _onClearDestination() {
    if (_phase == NavPhase.navigating) return;
    setState(() {
      _destination = null;
      _options = const [];
      _selectedOption = 0;
      _phase = NavPhase.idle;
      _notice = null;
    });
  }

  void _maybeLoadInitialRoute() {
    if (widget.initialDestination == null || _initialRouteRequested) return;
    if (_phase != NavPhase.idle || _isLoadingRoute || _lastFix == null) return;
    _initialRouteRequested = true;
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    final destination = _destination;
    final origin = _lastFix;
    if (destination == null) return;
    if (origin == null) {
      _showNotice('Waiting for your GPS position before routing.');
      return;
    }
    setState(() {
      _isLoadingRoute = true;
      _phase = NavPhase.preview;
    });
    try {
      final options = await _routing.computeRoutes(
        origin: NavLatLng(origin.latitude, origin.longitude),
        destination: destination.location,
      );
      if (!mounted) return;
      setState(() {
        _options = options;
        _selectedOption = 0;
      });
      _fitRoute(options.first);
    } on NavError catch (e) {
      if (!mounted) return;
      setState(() {
        _options = const [];
        _phase = NavPhase.idle;
      });
      _showNotice(e.friendlyMessage);
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  Future<void> _reroute() async {
    if (_isRerouting || _destination == null || _lastFix == null) return;
    setState(() => _isRerouting = true);
    try {
      final options = await _routing.computeRoutes(
        origin: NavLatLng(_lastFix!.latitude, _lastFix!.longitude),
        destination: _destination!.location,
      );
      if (!mounted) return;
      setState(() {
        _options = options;
        _selectedOption = 0;
        _isRerouting = false;
      });
      _guidance.setRoute(options.first);
      _showNotice('Route updated.');
    } on NavError catch (e) {
      if (!mounted) return;
      setState(() => _isRerouting = false);
      _showNotice('Reroute failed: ${e.friendlyMessage}');
    }
  }

  // --- Navigation controls ---------------------------------------------------

  void _onStart() {
    if (_options.isEmpty) return;
    _guidance.setRoute(_options[_selectedOption]);
    final now = DateTime.now();
    final first = _options[_selectedOption];
    setState(() {
      _phase = NavPhase.navigating;
      _followUser = true;
      _progress = TripProgress(
        instruction: first.steps.isEmpty
            ? 'Follow the highlighted route.'
            : first.steps.first.instruction,
        maneuverLabel: first.steps.isEmpty
            ? ''
            : first.steps.first.maneuverLabel,
        distanceToManeuverM: first.steps.isEmpty
            ? first.distanceMeters
            : first.steps.first.distanceMeters,
        remainingDistanceM: first.distanceMeters,
        eta: now.add(Duration(seconds: first.durationSeconds)),
        offRoute: false,
        arrived: false,
      );
    });
  }

  void _onStop() {
    setState(() {
      _phase = _options.isEmpty ? NavPhase.idle : NavPhase.preview;
      _progress = null;
    });
  }

  void _onArrive() {
    if (!mounted) return;
    setState(() {
      _phase = _options.isEmpty ? NavPhase.idle : NavPhase.preview;
      _progress = null;
    });
    _showNotice('You have arrived at your destination.');
  }

  // --- Map helpers (via the MapProvider abstraction only) ---------------------

  MapViewState get _mapState {
    final fix = _lastFix;
    final routes = <RouteLine>[
      for (var i = 0; i < _options.length; i++)
        RouteLine(
          points: _options[i].overviewPoints.isNotEmpty
              ? _options[i].overviewPoints
              : _options[i].trackingPoints,
          selected: i == _selectedOption,
        ),
    ];

    return MapViewState(
      routes: routes,
      destination: _destination?.location,
      position: fix == null ? null : NavLatLng(fix.latitude, fix.longitude),
    );
  }

  void _fitRoute(NavRouteOption option) {
    final points = option.overviewPoints.isNotEmpty
        ? option.overviewPoints
        : option.trackingPoints;
    if (points.length < 2) return;
    _mapController?.fitPoints(points);
  }

  // --- Building geofence -----------------------------------------------------
  // Uses the SAME CampusBuildings data as the map overlay. Requires 2
  // consecutive inside fixes (GPS is noisy at building scale) and ignores
  // low-accuracy fixes (>50m). After a prompt (continued or dismissed),
  // no re-prompt until an exit (2 consecutive outside fixes) + re-entry.
  // Cooldown of 2 minutes guards rapid boundary flicker.

  void _checkBuildingGeofence(NavFix fix) {
    if (!mounted || _readiness != LocationReadiness.ready) return;
    final accuracy = fix.accuracyM;
    if (accuracy != null && accuracy > 50) {
      _insideStreak = 0;
      return;
    }
    final point = NavLatLng(fix.latitude, fix.longitude);
    final building = CampusBuildings.containing(point);
    if (building == null) {
      _insideStreak = 0;
      _outsideStreak++;
      if (_outsideStreak >= 2) _insideBuildingId = null;
      return;
    }
    _outsideStreak = 0;
    if (_insideBuildingId == building.id || _buildingPromptOpen) return;
    _insideStreak++;
    if (_insideStreak < 2) return;
    final now = DateTime.now();
    if (_lastBuildingPromptAt != null &&
        now.difference(_lastBuildingPromptAt!) < const Duration(minutes: 2)) {
      return;
    }
    _showEnterBuildingDialog(building);
  }

  Future<void> _showEnterBuildingDialog(CampusBuilding building) async {
    _buildingPromptOpen = true;
    _lastBuildingPromptAt = DateTime.now();
    _insideStreak = 0;
    final enter = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: Text('Enter ${building.name}?'),
        content: Text(
          'You are about to enter ${building.name}. Continue to the indoor map?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    _buildingPromptOpen = false;
    if (!mounted) return;
    // Mark handled either way so we don't nag until exit + re-entry.
    _insideBuildingId = building.id;
    if (enter == true) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FloorPlanScreen(initialFloor: building.initialFloor),
        ),
      );
    }
  }

  void _restartStyleTimer() {
    _styleTimer?.cancel();
    _styleTimer = Timer(const Duration(seconds: 12), () {
      if (mounted && !_styleLoaded) setState(() => _mapSlow = true);
    });
  }

  /// Cycles to the next map appearance (Satellite → Streets → Bright …).
  /// Disables auto-switching when user manually changes style.
  Future<void> _cycleStyle() async {
    if (_styles.length < 2) return;
    setState(() {
      _styleIndex = (_styleIndex + 1) % _styles.length;
      _styleLoaded = false;
      _mapSlow = false;
      _autoStyleSwitchEnabled = false;
    });
    _restartStyleTimer();
    try {
      await _mapController?.setStyle(_styles[_styleIndex].url);
    } catch (_) {
      // Style switch failed; the loader + slow hint cover messaging.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Map style: ${_styles[_styleIndex].name} (auto-switch off)',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showNotice(String message) {
    setState(() => _notice = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }

  /// Handles zoom level changes to auto-switch between satellite and terrain.
  /// When zoomed in past [_terrainZoomThreshold], switches to terrain style.
  /// When zoomed out below threshold, switches back to satellite.
  void _onZoomChange(double zoom) {
    if (!_autoStyleSwitchEnabled) return;

    final shouldBeTerrain = zoom >= _terrainZoomThreshold;
    if (shouldBeTerrain != _isTerrainMode) {
      _isTerrainMode = shouldBeTerrain;
      final targetStyleIndex = _styles.indexWhere(
        (s) => s.name == (shouldBeTerrain ? 'Terrain' : 'Satellite'),
      );
      if (targetStyleIndex >= 0 && targetStyleIndex != _styleIndex) {
        setState(() {
          _styleIndex = targetStyleIndex;
          _styleLoaded = false;
          _mapSlow = false;
        });
        _restartStyleTimer();
        _mapController?.setStyle(_styles[_styleIndex].url);
      }
    }
  }

  // --- Build -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final fix = _lastFix;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Navigation'),
        backgroundColor: const Color(0xFF0A7040),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.layers_outlined),
            tooltip: 'Change map style (long press to re-enable auto-switch)',
            onPressed: _cycleStyle,
            onLongPress: () {
              setState(() => _autoStyleSwitchEnabled = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Auto terrain/satellite switch enabled'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _maps.buildMap(
            state: _mapState,
            callbacks: MapViewCallbacks(
              onReady: (controller) {
                _mapController = controller;
                if (fix != null) {
                  controller.animateTo(
                    target: NavLatLng(fix.latitude, fix.longitude),
                    zoom: _phase == NavPhase.navigating ? 16.5 : 16,
                  );
                }
              },
              onTap: _onMapTap,
              onUserTakeover: () {
                if (_phase == NavPhase.navigating && _followUser) {
                  setState(() => _followUser = false);
                }
              },
              onStyleLoaded: () {
                _styleTimer?.cancel();
                if (mounted && !_styleLoaded) {
                  setState(() {
                    _styleLoaded = true;
                    _mapSlow = false;
                  });
                }
              },
              onZoomChange: _onZoomChange,
            ),
            initialCenter: fix == null
                ? NavConfig.fallbackCenter
                : NavLatLng(fix.latitude, fix.longitude),
          ),
          if (!_styleLoaded)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(
                          _mapSlow
                              ? 'Map tiles are taking a while — check your internet connection.'
                              : 'Loading map…',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // GPS gate renders above the map loader so permission prompts
          // are never hidden behind it.
          if (_readiness != LocationReadiness.ready) _buildGpsGate(),
          if (_readiness == LocationReadiness.ready) ...[
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: _phase == NavPhase.navigating
                  ? GuidanceBanner(
                      progress:
                          _progress ??
                          TripProgress(
                            instruction: 'Getting GPS fix…',
                            maneuverLabel: '',
                            distanceToManeuverM: 0,
                            remainingDistanceM: 0,
                            eta: DateTime.now(),
                            offRoute: false,
                            arrived: false,
                          ),
                      rerouting: _isRerouting,
                    )
                  : DestinationBar(
                      destination: _destination,
                      onCoordinates: _onCoordinates,
                      onClear: _onClearDestination,
                    ),
            ),
            if (_notice != null && _phase != NavPhase.navigating)
              Positioned(
                top: 92,
                left: 12,
                right: 12,
                child: _buildNoticeCard(),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: TripPanel(
                phase: _phase,
                options: _options,
                selectedIndex: _selectedOption,
                progress: _progress,
                isLoadingRoute: _isLoadingRoute,
                onSelectOption: (i) => setState(() => _selectedOption = i),
                onStart: _onStart,
                onStop: _onStop,
              ),
            ),
            if (_phase == NavPhase.navigating && !_followUser)
              Positioned(
                right: 12,
                bottom: 170,
                child: FloatingActionButton.small(
                  heroTag: 'live_nav_recenter',
                  tooltip: 'Recenter on my location',
                  backgroundColor: Colors.white,
                  foregroundColor: NavTheme.accent,
                  onPressed: () {
                    final current = _lastFix;
                    if (current == null) return;
                    setState(() => _followUser = true);
                    _mapController?.animateTo(
                      target: NavLatLng(current.latitude, current.longitude),
                      zoom: 16.5,
                      bearing: current.headingDeg,
                      tilt: 50,
                    );
                  },
                  child: const Icon(Icons.my_location),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoticeCard() {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      shadowColor: Colors.black.withValues(alpha: 0.25),
      color: Colors.amber.shade100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_notice!, style: const TextStyle(fontSize: 13)),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => setState(() => _notice = null),
            ),
          ],
        ),
      ),
    );
  }

  /// Permission / GPS-state gate shown until location is usable.
  Widget _buildGpsGate() {
    final readiness = _readiness;
    if (readiness == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final String title;
    final String body;
    final List<Widget> actions;
    switch (readiness) {
      case LocationReadiness.denied:
        title = 'Location permission needed';
        body =
            'Live Navigation needs your GPS position to show the map marker, '
            'calculate routes, and guide you turn by turn.';
        actions = [
          FilledButton(
            onPressed: _initLocation,
            child: const Text('Grant permission'),
          ),
        ];
      case LocationReadiness.deniedForever:
        title = 'Location blocked';
        body =
            'Location permission was permanently denied. Enable it in the '
            'app Settings to use Live Navigation.';
        actions = [
          FilledButton(
            onPressed: _location.openAppSettings,
            child: const Text('Open Settings'),
          ),
          TextButton(onPressed: _initLocation, child: const Text('Retry')),
        ];
      case LocationReadiness.serviceDisabled:
        title = 'GPS is turned off';
        body = 'Turn on location services to use Live Navigation.';
        actions = [
          FilledButton(
            onPressed: () async {
              await _location.openLocationSettings();
            },
            child: const Text('Open location settings'),
          ),
          TextButton(onPressed: _initLocation, child: const Text('Retry')),
        ];
      case LocationReadiness.ready:
        return const SizedBox.shrink(); // unreachable; guarded by caller
    }
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off, size: 48),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(body, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Wrap(spacing: 8, children: actions),
            ],
          ),
        ),
      ),
    );
  }
}
