// lib/screens/floor_plan_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:naviapp/config/staircase_locations.dart';
import 'package:naviapp/models/starting_location.dart';
import 'package:naviapp/providers/user_location_provider.dart';
import 'package:naviapp/services/indoor_positioning/indoor_position.dart';
import 'package:naviapp/services/indoor_positioning/indoor_position_provider.dart';
import 'package:naviapp/services/navigation_graph.dart';
import 'package:naviapp/services/navigation_service.dart';
import 'package:naviapp/services/pathfinder.dart';
import 'package:naviapp/services/room_catalog.dart';
import 'package:naviapp/services/route_calculator.dart';

class FloorPlanScreen extends StatefulWidget {
  final int initialFloor;
  final IndoorPositionProvider? positionProvider;
  const FloorPlanScreen({
    super.key,
    this.initialFloor = 0,
    this.positionProvider,
  });

  @override
  State<FloorPlanScreen> createState() => _FloorPlanScreenState();
}

class _FloorPlanScreenState extends State<FloorPlanScreen>
    with TickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late int _currentFloor;
  late AnimationController _pathAnimationController;
  late Animation<double> _pathAnimation;
  List<Offset> _navigationPath = [];
  bool _isNavigating = false;
  List<int> _pathFloorIndices = [];

  // Track if user manually selected a floor
  bool _userSelectedFloor = false;

  // Indoor positioning
  IndoorPositionProvider? _positionProvider;
  StreamSubscription<IndoorPosition>? _positionSubscription;
  IndoorPosition? _currentPosition;

  // Viewport size captured during layout (used to center on a position).
  Size? _viewportSize;

  // ID of the QR location currently applied to this screen.
  String? _appliedPinId;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  late final UserLocationProvider _userLocation;

  // Dynamic navigation service
  late final NavigationService _navigationService;

  static const List<String> _floorNames = ['Ground', '2nd Floor', '3rd Floor'];
  static const List<String> _floorImagePaths = [
    'assets/images/ground_floor.png',
    'assets/images/second_floor.png',
    'assets/images/third_floor.png',
  ];

  Size _getFloorImageSize(int floor) {
    switch (floor) {
      case 0:
        return const Size(1485, 704);
      case 1:
        return const Size(1464, 720);
      default:
        return const Size(1600, 671);
    }
  }

  String get _currentFloorName => _floorNames[_currentFloor];
  String get _currentFloorImage => _floorImagePaths[_currentFloor];

  @override
  void initState() {
    super.initState();
    _currentFloor = widget.initialFloor;
    SystemChrome.setPreferredOrientations(const <DeviceOrientation>[]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
    _pathAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _pathAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _pathAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _pathAnimationController.addListener(() {
      setState(() {});
    });
    _initPositioning();
    _userLocation = context.read<UserLocationProvider>();
    _userLocation.addListener(_onUserLocationChanged);

    // Initialize navigation service
    _navigationService = NavigationService(
      userLocationProvider: _userLocation,
      positionProvider: _positionProvider,
    );
    _navigationService.addListener(_onNavigationRouteChanged);
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(() => _searchQuery = _searchController.text);
  }

  void _onSearchFocusChanged() {
    if (mounted) setState(() {});
  }

  List<_RoomSearchMatch> get _roomMatches {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return const [];

    final matches = <_RoomSearchMatch>[];
    for (var floor = 0; floor < RoomCatalog.floorKeys.length; floor++) {
      for (final room in RoomCatalog.allRooms[RoomCatalog.floorKeys[floor]]!) {
        final name = room['name']!;
        if (name.toLowerCase().contains(query)) {
          matches.add(_RoomSearchMatch(room: room, floor: floor));
        }
      }
    }
    matches.sort((a, b) {
      final aStarts = a.name.toLowerCase().startsWith(query) ? 0 : 1;
      final bStarts = b.name.toLowerCase().startsWith(query) ? 0 : 1;
      final rank = aStarts.compareTo(bStarts);
      return rank != 0 ? rank : a.name.compareTo(b.name);
    });
    return matches.take(8).toList();
  }

  void _selectSearchResult(_RoomSearchMatch match) {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _currentFloor = match.floor;
      _userSelectedFloor = true;
    });
    navigateTo(match.room['id']!);
  }

  /// Reacts to a newly pinned QR starting location: switches to that
  /// floor, centers the plan on the point and shows it as "You are here".
  void _onUserLocationChanged() {
    if (!mounted) return;
    final pin = _userLocation.startingLocation;
    if (pin == null || pin.id == _appliedPinId) return;
    _appliedPinId = pin.id;
    setState(() {
      _currentFloor = pin.floor;
      // The scanned floor is authoritative; keep it selected.
      _userSelectedFloor = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _centerOnPosition(pin.x, pin.y);
    });
  }

  void _initPositioning() {
    _positionProvider = widget.positionProvider ?? createPositionProvider();
    _positionSubscription = _positionProvider!.positions.listen(
      _onIndoorPosition,
      onError: (Object error) {
        if (!mounted) return;
        debugPrint('Indoor positioning error: $error');
      },
    );
    _positionProvider!.start();
  }

  /// The position used for the marker and route origin.
  ///
  /// A QR-scanned starting location is exact and pinned, so it overrides
  /// live BLE/mock estimates until cleared or replaced by another scan.
  IndoorPosition? get _activePosition {
    if (_userLocation.hasManualPosition) return _userLocation.position;
    return _currentPosition;
  }

  void _onIndoorPosition(IndoorPosition position) {
    if (!mounted) return;
    // Ignore live updates while a QR starting point pins the position.
    if (_userLocation.hasManualPosition) return;
    setState(() {
      _currentPosition = position;
      // Auto-switch floor only if user hasn't manually selected a floor
      if (!_userSelectedFloor && position.floor != _currentFloor) {
        _currentFloor = position.floor;
      }
    });
  }

  /// Called when the navigation service updates the route.
  void _onNavigationRouteChanged() {
    if (!mounted) return;
    final route = _navigationService.currentRoute;
    if (route != null && route.hasPath) {
      setState(() {
        _navigationPath = route.fullPath;
        _pathFloorIndices = route.floorIndices;
        _isNavigating = true;
      });
      _pathAnimationController.forward(from: 0);
    } else if (route == null) {
      // Navigation cleared
      setState(() {
        _navigationPath = [];
        _pathFloorIndices = [];
        _isNavigating = false;
      });
    }
  }

  void navigateTo(String roomId) {
    final destinationFloor = _findFloorForRoom(roomId);
    final position = _activePosition;

    if (position != null && position.floor == destinationFloor) {
      // Same floor with known position
      _navigateSameFloor(roomId, destinationFloor);
    } else if (position != null) {
      // Cross-floor with known position
      _navigateCrossFloor(roomId, destinationFloor);
    } else {
      // No position - use default start node
      _navigateDefault(roomId);
    }
  }

  int _findFloorForRoom(String roomId) {
    final mappedNodeId = NavigationGraph.roomToNode[roomId];
    if (mappedNodeId != null) {
      for (int f = 0; f < 3; f++) {
        final nodes = NavigationGraph.nodesForFloor(f);
        if (nodes.any((n) => n.id == mappedNodeId)) {
          return f;
        }
      }
    }
    return _currentFloor;
  }

  void _navigateSameFloor(String roomId, int floor) {
    final floorIndex = floor;
    final nodes = NavigationGraph.getNodes(floorIndex);
    final edges = NavigationGraph.getEdges(floorIndex);
    final position = _activePosition;

    final startNodeId = position != null
        ? Pathfinder.findNearestNodeToPosition(
            Offset(position.x, position.y),
            floorIndex,
          )
        : NavigationGraph.getDefaultStartNode(floorIndex) ?? nodes.first.id;

    final endNodeId = Pathfinder.findNearestNodeToRoom(roomId, floorIndex);

    final pathPoints = Pathfinder.findPath(
      startNodeId: startNodeId,
      endNodeId: endNodeId,
      nodes: nodes,
      edges: edges,
    );

    if (pathPoints.isNotEmpty) {
      setState(() {
        _navigationPath = pathPoints;
        _pathFloorIndices = List.filled(pathPoints.length, floorIndex);
        _isNavigating = true;
      });
      _pathAnimationController.forward(from: 0);
    }
  }

  void _navigateCrossFloor(String roomId, int destinationFloor) {
    final pos = _activePosition;
    if (pos == null) {
      _navigateDefault(roomId);
      return;
    }
    final result = RouteCalculator.fromLivePosition(
      position: pos,
      roomId: roomId,
      destinationFloor: destinationFloor,
    );
    if (result != null && result.hasPath) {
      setState(() {
        _navigationPath = result.path;
        _pathFloorIndices = result.floorIndices;
        _isNavigating = true;
      });
      _pathAnimationController.forward(from: 0);
      return;
    }
    _navigateDefault(roomId);
  }

  void _navigateDefault(String roomId) {
    final floorIndex = _currentFloor;
    final nodes = NavigationGraph.getNodes(floorIndex);
    final edges = NavigationGraph.getEdges(floorIndex);

    final startNodeId =
        NavigationGraph.getDefaultStartNode(floorIndex) ?? nodes.first.id;
    final endNodeId = Pathfinder.findNearestNodeToRoom(roomId, floorIndex);

    final pathPoints = Pathfinder.findPath(
      startNodeId: startNodeId,
      endNodeId: endNodeId,
      nodes: nodes,
      edges: edges,
    );

    if (pathPoints.isEmpty) {
      for (int floor = 0; floor < 3; floor++) {
        final altNodes = NavigationGraph.getNodes(floor);
        final altEdges = NavigationGraph.getEdges(floor);
        final altEndNodeId = Pathfinder.findNearestNodeToRoom(roomId, floor);
        final altPath = Pathfinder.findPath(
          startNodeId:
              NavigationGraph.getDefaultStartNode(floor) ?? altNodes.first.id,
          endNodeId: altEndNodeId,
          nodes: altNodes,
          edges: altEdges,
        );
        if (altPath.isNotEmpty) {
          setState(() {
            _currentFloor = floor;
            _navigationPath = altPath;
            _pathFloorIndices = List.filled(altPath.length, floor);
            _isNavigating = true;
          });
          _pathAnimationController.forward(from: 0);
          return;
        }
      }
      return;
    }

    setState(() {
      _navigationPath = pathPoints;
      _pathFloorIndices = List.filled(pathPoints.length, floorIndex);
      _isNavigating = pathPoints.isNotEmpty;
    });
    if (pathPoints.isNotEmpty) {
      _pathAnimationController.forward(from: 0);
    }
  }

  /// Pans/zooms the InteractiveViewer so the normalized point sits at the
  /// center of the viewport. Works for any viewport size / resolution.
  void _centerOnPosition(double x, double y) {
    final vp = _viewportSize;
    if (vp == null || vp.width <= 0 || vp.height <= 0) return;
    final imageSize = _getFloorImageSize(_currentFloor);
    final scaleFactor = min(
      vp.width / imageSize.width,
      vp.height / imageSize.height,
    );
    final scaledWidth = imageSize.width * scaleFactor;
    final scaledHeight = imageSize.height * scaleFactor;
    final px = x * scaledWidth;
    final py = y * scaledHeight;
    final originX = (vp.width - scaledWidth) / 2;
    final originY = (vp.height - scaledHeight) / 2;
    _transformationController.value = Matrix4.translationValues(
      vp.width / 2 - (originX + px),
      vp.height / 2 - (originY + py),
      0,
    );
  }

  @override
  void dispose() {
    _userLocation.removeListener(_onUserLocationChanged);
    _navigationService.removeListener(_onNavigationRouteChanged);
    _navigationService.dispose();
    _positionSubscription?.cancel();
    _positionProvider?.stop();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _transformationController.dispose();
    _pathAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userLocation = context.watch<UserLocationProvider>();
    final pinnedLocation = userLocation.startingLocation;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
          title: Text(
            _currentFloorName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          backgroundColor: const Color(0xFF0A7040),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          toolbarHeight: 52,
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
          final imageSize = _getFloorImageSize(_currentFloor);
          final scaleX = constraints.maxWidth / imageSize.width;
          final scaleY = constraints.maxHeight / imageSize.height;
          final scaleFactor = scaleX < scaleY ? scaleX : scaleY;
          final scaledWidth = imageSize.width * scaleFactor;
          final scaledHeight = imageSize.height * scaleFactor;

          return Stack(
            children: [
              InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: SizedBox(
                    width: scaledWidth,
                    height: scaledHeight,
                    child: GestureDetector(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            // Smooth cross-fade when switching floors.
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              switchInCurve: Curves.ease,
                              switchOutCurve: Curves.ease,
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                              child: Image.asset(
                                _currentFloorImage,
                                key: ValueKey<String>(_currentFloorImage),
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                          // Premium 400ms ease-in for newly drawn routes,
                          // layered over the existing path-progress painter.
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                              begin: 0,
                              end: _isNavigating ? 1 : 1,
                            ),
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.ease,
                            builder: (context, opacity, child) => Opacity(
                              opacity: opacity.clamp(0.0, 1.0),
                              child: child,
                            ),
                            child: CustomPaint(
                              size: Size(scaledWidth, scaledHeight),
                              painter: FloorPlanPainter(
                                isDark:
                                    Theme.of(context).brightness ==
                                    Brightness.dark,
                                navigationPath: _navigationPath,
                                pathFloorIndices: _pathFloorIndices,
                                currentFloor: _currentFloor,
                                pathProgress: _pathAnimation.value,
                                isNavigating: _isNavigating,
                                imageOriginalSize: imageSize,
                                livePosition: _activePosition,
                                routeDots:
                                    _navigationService
                                        .currentRoute
                                        ?.dotPositions ??
                                    [],
                                routeDotFloorIndices:
                                    _navigationService
                                        .currentRoute
                                        ?.dotFloorIndices ??
                                    [],
                                isFlipped: false,
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: _StaircaseLabelLayer(
                              controller: _transformationController,
                              staircases: StaircaseLocations.forFloor(
                                _currentFloor,
                              ),
                              mapSize: Size(scaledWidth, scaledHeight),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 12,
                right: 12,
                child: _buildSearchOverlay(context),
              ),
              if (pinnedLocation != null)
                Positioned(
                  left: 12,
                  bottom: 72, // Account for bottom NavigationBar (56) + margin
                  width: min(constraints.maxWidth * 0.58, 230),
                  child: _CurrentLocationCard(
                    locationName: pinnedLocation.name,
                    floorName: _floorNames[pinnedLocation.floor],
                    onClear: () {
                      userLocation.clear();
                      setState(() => _userSelectedFloor = false);
                    },
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentFloor,
        onDestinationSelected: (index) {
          setState(() {
            _currentFloor = index;
            _userSelectedFloor = true;
          });
        },
        height: 56,
        indicatorColor: const Color(0xFF0A7040),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.stairs, size: 22),
            label: 'Ground',
          ),
          NavigationDestination(
            icon: Icon(Icons.business, size: 22),
            label: '2nd',
          ),
          NavigationDestination(
            icon: Icon(Icons.apartment, size: 22),
            label: '3rd',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchOverlay(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1B2E20) : Colors.white;
    final surfaceText = isDark
        ? const Color(0xFFE7F4EA)
        : const Color(0xFF0E2B1C);
    final matches = _roomMatches;
    final showMatches =
        _searchFocusNode.hasFocus && _searchQuery.trim().isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              textInputAction: TextInputAction.search,
              onTapOutside: (_) => _searchFocusNode.unfocus(),
              style: TextStyle(color: surfaceText, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search a room...',
                hintStyle: TextStyle(
                  color: isDark
                      ? const Color(0xFFA8C8B0)
                      : Colors.grey.shade600,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: Color(0xFF0A7040),
                ),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: _searchController.clear,
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ),
        if (showMatches) ...[
          const SizedBox(height: 6),
          Material(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            elevation: 8,
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: matches.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No rooms found',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFA8C8B0)
                              : Colors.grey.shade700,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: matches.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.grey.shade200,
                      ),
                      itemBuilder: (context, index) {
                        final match = matches[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.meeting_room_outlined,
                            size: 20,
                            color: Color(0xFF0A7040),
                          ),
                          title: Text(
                            match.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            RoomCatalog.floorKeys[match.floor],
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 18),
                          onTap: () => _selectSearchResult(match),
                        );
                      },
                    ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RoomSearchMatch {
  const _RoomSearchMatch({required this.room, required this.floor});

  final Map<String, String> room;
  final int floor;

  String get name => room['name']!;
}

/// Renders staircase labels at their normalized floor-plan points.
///
/// Labels are counter-scaled against the [InteractiveViewer] transform so
/// they stay legible (and tappable) at every zoom level while still panning
/// and zooming with the map.
class _StaircaseLabelLayer extends StatelessWidget {
  final TransformationController controller;
  final List<StartingLocation> staircases;
  final Size mapSize;

  const _StaircaseLabelLayer({
    required this.controller,
    required this.staircases,
    required this.mapSize,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final zoom = controller.value.getMaxScaleOnAxis();
        final inverseZoom = zoom > 0 ? 1 / zoom : 1.0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final staircase in staircases)
              Positioned(
                left: staircase.x * mapSize.width,
                top: staircase.y * mapSize.height,
                child: FractionalTranslation(
                  translation: Offset(_anchorX(staircase.x), -0.5),
                  child: Transform.scale(
                    scale: inverseZoom,
                    child: _StaircaseLabel(staircase: staircase),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Keeps labels inside the plan edges and points paired staircases apart.
  double _anchorX(double x) {
    if (x < 0.18) return 0;
    if (x > 0.82) return -1;
    if (x < 0.5) return -1;
    return 0;
  }
}

class _StaircaseLabel extends StatelessWidget {
  final StartingLocation staircase;

  const _StaircaseLabel({required this.staircase});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: StaircaseLocations.labelFor(staircase),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF0A7040).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.85),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stairs, size: 12, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              StaircaseLocations.labelFor(staircase),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                height: 1.1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact card shown after a successful QR scan, confirming the detected
/// starting location.
class _CurrentLocationCard extends StatelessWidget {
  final String locationName;
  final String floorName;
  final VoidCallback onClear;

  const _CurrentLocationCard({
    required this.locationName,
    required this.floorName,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2E20) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2B4A36) : const Color(0xFF2563EB),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.my_location,
                size: 16,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You are here',
                    style: textTheme.labelSmall?.copyWith(
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  Text(
                    locationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFE7F4EA)
                          : const Color(0xFF0E2B1C),
                    ),
                  ),
                  Text(
                    floorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? const Color(0xFFA8C8B0)
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Clear location',
              onPressed: onClear,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              icon: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

class FloorPlanPainter extends CustomPainter {
  final bool isDark;
  final List<Offset> navigationPath;
  final List<int> pathFloorIndices;
  final int currentFloor;
  final double pathProgress;
  final bool isNavigating;
  final Size imageOriginalSize;
  final IndoorPosition? livePosition;
  final List<Offset> routeDots;
  final List<int> routeDotFloorIndices;
  final bool isFlipped;

  FloorPlanPainter({
    required this.isDark,
    this.navigationPath = const [],
    this.pathFloorIndices = const [],
    this.currentFloor = 0,
    this.pathProgress = 0,
    this.isNavigating = false,
    this.imageOriginalSize = const Size(1464, 720),
    this.livePosition,
    this.routeDots = const [],
    this.routeDotFloorIndices = const [],
    this.isFlipped = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final baseSize = imageOriginalSize.width;
    final height = imageOriginalSize.height;
    final scaleX = size.width / baseSize;
    final scaleY = size.height / height;
    final scaleFactor = scaleX < scaleY ? scaleX : scaleY;
    final scaledWidth = baseSize * scaleFactor;
    final scaledHeight = height * scaleFactor;
    final offsetX = (size.width - scaledWidth) / 2;
    final offsetY = (size.height - scaledHeight) / 2;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scaleFactor);
    if (isFlipped) {
      canvas.translate(baseSize / 2, height / 2);
      canvas.rotate(pi);
      canvas.translate(-baseSize / 2, -height / 2);
    }

    // Draw route dots (new dynamic navigation)
    if (isNavigating && routeDots.isNotEmpty) {
      _drawRouteDots(canvas, baseSize, height, scaleFactor);
    }
    // Fallback to legacy animated path (for room-to-room navigation from AINavSheet)
    else if (isNavigating && navigationPath.isNotEmpty) {
      _drawNavigationPath(canvas, baseSize, height, scaleFactor);
    }

    // Draw live position marker
    if (livePosition != null && livePosition!.floor == currentFloor) {
      _drawLiveMarker(canvas, baseSize, height, scaleFactor);
    }

    canvas.restore();
  }

  void _drawLiveMarker(
    Canvas canvas,
    double baseSize,
    double height,
    double scaleFactor,
  ) {
    final pos = livePosition!;
    final x = pos.x * baseSize;
    final y = pos.y * height;
    final inv = 1.0 / scaleFactor;

    // Accuracy circle
    if (pos.accuracy < 20.0) {
      final accuracyPx = pos.accuracy * baseSize / 50.0;
      canvas.drawCircle(
        Offset(x, y),
        accuracyPx.clamp(8.0, 160.0),
        Paint()..color = const Color(0x332563EB),
      );
    }

    // Pulsing outer ring (using a simple static ring for now)
    canvas.drawCircle(
      Offset(x, y),
      11.0 * inv,
      Paint()
        ..color = const Color(0xAA3B82F6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * inv,
    );

    // White outer ring
    canvas.drawCircle(
      Offset(x, y),
      8.5 * inv,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * inv,
    );

    // Blue fill + white center dot
    canvas.drawCircle(
      Offset(x, y),
      6.5 * inv,
      Paint()..color = const Color(0xFF2563EB),
    );
    canvas.drawCircle(Offset(x, y), 1.8 * inv, Paint()..color = Colors.white);
  }

  /// Draws the route as a series of dots from current position to destination.
  void _drawRouteDots(
    Canvas canvas,
    double baseSize,
    double height,
    double scaleFactor,
  ) {
    if (routeDots.isEmpty) return;

    final inv = 1.0 / scaleFactor;
    final dotRadius = 4.0 * inv;
    final dotPaint = Paint()
      ..color = const Color(0xFF0A7040)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < routeDots.length; i++) {
      final dotFloor = i < routeDotFloorIndices.length
          ? routeDotFloorIndices[i]
          : currentFloor;
      if (dotFloor != currentFloor) continue;

      final dot = routeDots[i];
      final x = dot.dx * baseSize;
      final y = dot.dy * height;

      // Fade dots slightly as they get further from the start
      final alpha = (255 * (1.0 - (i / routeDots.length) * 0.3)).round();
      dotPaint.color = const Color(0xFF0A7040).withAlpha(alpha);

      canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
    }
  }

  void _drawNavigationPath(
    Canvas canvas,
    double baseSize,
    double height,
    double scaleFactor,
  ) {
    if (navigationPath.isEmpty) return;

    final totalPathLength = _calculatePixelPathLength(
      navigationPath,
      baseSize,
      height,
    );
    final progressDistance = totalPathLength * pathProgress;
    if (progressDistance <= 0) return;

    double traveledDistance = 0;
    final dotRadius = 3.0 / scaleFactor;
    final pixelSpacing = (totalPathLength / 50.0).clamp(3.0, 20.0);

    for (int i = 0; i < navigationPath.length - 1; i++) {
      final pathFloor = pathFloorIndices.length > i
          ? pathFloorIndices[i]
          : currentFloor;
      if (pathFloor != currentFloor) {
        final p1 = navigationPath[i];
        final p2 = navigationPath[i + 1];
        final x1 = p1.dx * baseSize;
        final y1 = p1.dy * height;
        final x2 = p2.dx * baseSize;
        final y2 = p2.dy * height;
        traveledDistance += (Offset(x2 - x1, y2 - y1)).distance;
        continue;
      }

      final p1 = navigationPath[i];
      final p2 = navigationPath[i + 1];
      final x1 = p1.dx * baseSize;
      final y1 = p1.dy * height;
      final x2 = p2.dx * baseSize;
      final y2 = p2.dy * height;
      final segmentLength = (Offset(x2 - x1, y2 - y1)).distance;
      if (segmentLength <= 0) continue;

      final stepsInSegment = (segmentLength / pixelSpacing).ceil().clamp(
        1,
        500,
      );
      for (int step = 0; step <= stepsInSegment; step++) {
        final t = step / stepsInSegment;
        final x = x1 + (x2 - x1) * t;
        final y = y1 + (y2 - y1) * t;
        final currentPixel = traveledDistance + t * segmentLength;
        if (currentPixel > progressDistance) break;

        final paint = Paint()
          ..color = const Color(0xFF0A7040)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }

      traveledDistance += segmentLength;
      if (traveledDistance >= progressDistance) break;
    }

    if (navigationPath.isNotEmpty) {
      final startPoint = navigationPath[0];
      final pathFloor0 = pathFloorIndices.isNotEmpty
          ? pathFloorIndices[0]
          : currentFloor;
      if (pathFloor0 == currentFloor) {
        final sx = startPoint.dx * baseSize;
        final sy = startPoint.dy * height;

        final startMarker = Paint()
          ..color = const Color(0xFF16A34A)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(sx, sy), 8.0 / scaleFactor, startMarker);

        final startTextPainter = TextPainter(
          text: TextSpan(
            text: 'S',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9 / scaleFactor,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        startTextPainter.layout();
        startTextPainter.paint(
          canvas,
          Offset(
            sx - startTextPainter.width / 2,
            sy - startTextPainter.height / 2,
          ),
        );
      }
    }

    if (pathProgress >= 0.95) {
      final lastPoint = navigationPath.last;
      final lastFloor = pathFloorIndices.isNotEmpty
          ? pathFloorIndices.last
          : currentFloor;
      if (lastFloor == currentFloor) {
        final ex = lastPoint.dx * baseSize;
        final ey = lastPoint.dy * height;

        final endMarker = Paint()
          ..color = const Color(0xFFDC2626)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(ex, ey), 8.0 / scaleFactor, endMarker);

        final endTextPainter = TextPainter(
          text: TextSpan(
            text: 'E',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9 / scaleFactor,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        endTextPainter.layout();
        endTextPainter.paint(
          canvas,
          Offset(ex - endTextPainter.width / 2, ey - endTextPainter.height / 2),
        );
      }
    }
  }

  double _calculatePixelPathLength(
    List<Offset> path,
    double baseSize,
    double height,
  ) {
    if (path.length < 2) return 0;
    double length = 0;
    for (int i = 0; i < path.length - 1; i++) {
      final dx = (path[i + 1].dx - path[i].dx) * baseSize;
      final dy = (path[i + 1].dy - path[i].dy) * height;
      length += sqrt(dx * dx + dy * dy);
    }
    return length > 0 ? length : 1;
  }

  @override
  bool shouldRepaint(FloorPlanPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.navigationPath != navigationPath ||
        oldDelegate.pathFloorIndices != pathFloorIndices ||
        oldDelegate.currentFloor != currentFloor ||
        oldDelegate.pathProgress != pathProgress ||
        oldDelegate.isNavigating != isNavigating ||
        oldDelegate.livePosition != livePosition ||
        oldDelegate.routeDots != routeDots ||
        oldDelegate.isFlipped != isFlipped ||
        oldDelegate.routeDotFloorIndices != routeDotFloorIndices;
  }
}
