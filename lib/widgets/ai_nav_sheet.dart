// lib/widgets/ai_nav_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:shimmer/shimmer.dart';
import 'app_ui.dart';
import '../features/live_navigation/config/campus_buildings.dart';
import '../services/indoor_positioning/indoor_position.dart';
import '../services/location_resolver.dart';
import '../services/navigation_graph.dart';
import '../services/pathfinder.dart';
import '../services/room_catalog.dart';
import '../services/route_calculator.dart';
import '../services/route_describer.dart';

class AINavSheet extends StatefulWidget {
  final String floorImagePath;
  final String? currentFloor;
  final int currentFloorIndex;
  final String? currentRoomId;

  /// Live indoor position, when available. When non-null the sheet skips
  /// the manual starting-point step and routes from the live position.
  final IndoorPosition? livePosition;

  /// Human-readable name of the pinned starting location (e.g. from a QR
  /// scan). Shown instead of raw coordinates when available.
  final String? currentLocationName;

  final void Function(NavigationResult result) onNavigationResult;
  final void Function(String fromLabel, String toRoomName, String floorName)?
  onNavigateRequest;

  /// Callback when user selects an external building (AB or TAB) to navigate
  /// in satellite/live navigation mode.
  final void Function(CampusBuilding building)? onExternalBuildingSelected;

  const AINavSheet({
    super.key,
    this.floorImagePath = '',
    this.currentFloor,
    this.currentFloorIndex = 0,
    this.currentRoomId,
    this.livePosition,
    this.currentLocationName,
    required this.onNavigationResult,
    this.onNavigateRequest,
    this.onExternalBuildingSelected,
  });

  @override
  State<AINavSheet> createState() => _AINavSheetState();
}

class _AINavSheetState extends State<AINavSheet> with TickerProviderStateMixin {
  late TabController _tabController;
  late TabController _buildingTabController;
  bool _isLoading = false;
  String? _loadingRoomName;

  // 0 = Main Building (show floors), 1 = Annex Building, 2 = Tangub Asenso Building
  int _selectedBuildingIndex = 0;

  List<String> get _floorKeys => RoomCatalog.floorKeys;
  List<CampusBuilding> get _buildings => CampusBuildings.all;

  static List<BoxShadow> get _softShadow => AppShadows.card;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.currentFloorIndex,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _buildingTabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: 0,
    );
    _buildingTabController.addListener(() {
      if (!_buildingTabController.indexIsChanging) {
        setState(() {
          _selectedBuildingIndex = _buildingTabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _buildingTabController.dispose();
    super.dispose();
  }

  List<Map<String, String>> _getFilteredRooms() {
    final floor = _floorKeys[_tabController.index];
    return RoomCatalog.allRooms[floor]!;
  }

  Future<void> _onBuildingTap(int buildingIndex) async {
    if (buildingIndex == 0) {
      // Main Building - show floor tabs
      setState(() {
        _selectedBuildingIndex = 0;
      });
      return;
    }

    // External building (AB or TAB) - navigate in satellite mode
    final building = _buildings[buildingIndex];
    if (widget.onExternalBuildingSelected != null) {
      Navigator.of(context).pop();
      widget.onExternalBuildingSelected!(building);
    }
  }

  Future<void> _onRoomTap(Map<String, String> room) async {
    // Premium tactile confirmation on selection (best-effort, fire-and-
    // forget: never block navigation in tests or on devices without haptics).
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
    Haptics.canVibrate()
        .then((can) {
          if (can) {
            return Haptics.vibrate(HapticsType.selection);
          }
        })
        .catchError((_) {});

    final roomName = room['name']!;
    final roomId = room['id']!;
    final floorIndex = _tabController.index;

    setState(() {
      _isLoading = true;
      _loadingRoomName = roomName;
    });

    try {
      // Priority for the route start:
      //  1. The live indoor position (nearest navigation node).
      //  2. The default starting point of the floor.
      NavigationResult? result;
      final live = widget.livePosition;
      if (live != null) {
        result = RouteCalculator.fromLivePosition(
          position: live,
          roomId: roomId,
          destinationFloor: floorIndex,
        );
      } else {
        final nodes = NavigationGraph.nodesForFloor(floorIndex);
        final edges = NavigationGraph.edgesForFloor(floorIndex);
        final startNodeId =
            NavigationGraph.startingPoints[floorIndex]?.first['nodeId'] ??
            nodes.first.id;
        final endNodeId = Pathfinder.findNearestNodeToRoom(roomId, floorIndex);
        final pathPoints = Pathfinder.findPath(
          startNodeId: startNodeId,
          endNodeId: endNodeId,
          nodes: nodes,
          edges: edges,
        );
        result = NavigationResult(
          path: pathPoints,
          floorIndices: List.filled(pathPoints.length, floorIndex),
          floorIndex: floorIndex,
          roomId: roomId,
        );
      }

      if (result == null || result.path.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No accessible path found between selected points'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
          _loadingRoomName = null;
        });
        return;
      }

      final fromLabel =
          widget.currentLocationName ??
          (live != null ? 'your live location' : 'your location');
      final startFloor = live?.floor ?? floorIndex;
      final isDefaultStart = live == null && widget.currentLocationName == null;
      final resolvedStartLabel = live != null
          ? fromLabel
          : (widget.currentLocationName ??
                LocationResolver.labelForNode(
                  NavigationGraph.startingPoints[floorIndex]?.first['nodeId'] ??
                      NavigationGraph.nodesForFloor(floorIndex).first.id,
                  floorIndex,
                ));

      // Grounded summary of the CALCULATED route only — never invented.
      final directions = RouteDescriber.describe(
        startLabel: resolvedStartLabel,
        startFloor: startFloor,
        destRoomId: roomId,
        destFloor: floorIndex,
        result: result,
        startIsDefault: isDefaultStart,
        destLabelOverride: roomName,
        destIsRoomCenter: true,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(directions),
            duration: const Duration(seconds: 4),
          ),
        );
      }

      widget.onNavigationResult(result);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigation error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingRoomName = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filteredRooms = _getFilteredRooms();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppPalette.pine : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
        boxShadow: _softShadow,
      ),
      child: Column(
        children: [
          const SheetHandle(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const TintIcon(
                  icon: Icons.flag_rounded,
                  color: AppPalette.brand,
                  size: 44,
                  iconSize: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '🏁 Where do you want to go?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Building selection tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFF0F6EF),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _buildingTabController,
                labelColor: Colors.white,
                unselectedLabelColor: isDark
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
                indicator: BoxDecoration(
                  color: AppPalette.brand,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                onTap: _onBuildingTap,
                tabs: [
                  _buildingTab(icon: Icons.domain, label: 'Main Building'),
                  _buildingTab(icon: Icons.business, label: 'Annex (AB)'),
                  _buildingTab(icon: Icons.apartment, label: 'Tangub (TAB)'),
                ],
              ),
            ),
          ),
          // Floor tabs (only show for Main Building)
          if (_selectedBuildingIndex == 0) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFF0F6EF),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                  indicator: BoxDecoration(
                    color: AppPalette.brand,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Ground'),
                    Tab(text: '2nd Floor'),
                    Tab(text: '3rd Floor'),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: _selectedBuildingIndex == 0
                ? (_isLoading
                      ? _buildLoadingSkeleton(context)
                      : _buildRoomList(filteredRooms))
                : _buildBuildingInfo(_buildings[_selectedBuildingIndex]),
          ),
        ],
      ),
    );
  }

  Widget _buildingTab({required IconData icon, required String label}) {
    return Tab(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildBuildingInfo(CampusBuilding building) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppPalette.brand.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.satellite_outlined,
                size: 50,
                color: AppPalette.brand,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              building.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'This building is not part of the Main Building indoor floor plans. Tap below to navigate using satellite/GPS mode.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppPalette.mistSoft : AppPalette.inkSoft,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _onBuildingTap(_selectedBuildingIndex),
                icon: const Icon(Icons.navigation),
                label: const Text('Navigate in Satellite Mode'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.brand,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final base = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlight = isDark ? Colors.grey.shade700 : Colors.grey.shade100;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Finding route to $_loadingRoomName...',
            style: theme.textTheme.bodyLarge,
          ),
        ),
        Expanded(
          child: Shimmer.fromColors(
            baseColor: base,
            highlightColor: highlight,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 6,
              itemBuilder: (_, _) => Container(
                height: 64,
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomList(List<Map<String, String>> rooms) {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 350),
            child: SlideAnimation(
              verticalOffset: 24,
              child: FadeInAnimation(child: _buildRoomTile(room)),
            ),
          );
        },
      ),
    );
  }

  /// Leading glyph per room kind (stairs/elevator/door/room).
  IconData _roomIcon(String name) {
    final t = name.toLowerCase();
    if (t.contains('stair')) return Icons.stairs_outlined;
    if (t.contains('elevator')) return Icons.elevator_outlined;
    if (t.contains('entrance') || t.contains('lobby') || t.contains('gate')) {
      return Icons.door_front_door_outlined;
    }
    if (t.contains('rest') || t.contains('cr') || t.contains('toilet')) {
      return Icons.wc_outlined;
    }
    return Icons.meeting_room_outlined;
  }

  Widget _buildRoomTile(Map<String, String> room) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Outer container carries the premium soft shadow (no Material
    // elevation); inner Material provides the ink surface so ListTile
    // ripples/taps keep working in production and widget tests.
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.tile),
        boxShadow: _softShadow,
      ),
      child: Material(
        color: isDark ? const Color(0xFF243B2C) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.tile),
          ),
          leading: TintIcon(
            icon: _roomIcon(room['name']!),
            color: AppPalette.brand,
            size: 44,
            iconSize: 22,
          ),
          title: Text(room['name']!, style: theme.textTheme.bodyLarge),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _onRoomTap(room),
        ),
      ),
    );
  }
}
