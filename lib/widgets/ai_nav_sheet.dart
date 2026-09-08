// lib/widgets/ai_nav_sheet.dart
import 'package:flutter/material.dart';
import '../services/ai_navigation_service.dart';
import '../services/indoor_positioning/indoor_position.dart';
import '../services/navigation_graph.dart';
import '../services/pathfinder.dart';
import '../services/room_catalog.dart';
import '../services/route_calculator.dart';

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
  });

  @override
  State<AINavSheet> createState() => _AINavSheetState();
}

class _AINavSheetState extends State<AINavSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _loadingRoomName;

  List<String> get _floorKeys => RoomCatalog.floorKeys;

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, String>> _getFilteredRooms() {
    final floor = _floorKeys[_tabController.index];
    return RoomCatalog.allRooms[floor]!;
  }

  Future<void> _onRoomTap(Map<String, String> room) async {
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
      final floorName = _floorKeys[floorIndex];

      AINavigationService.getDirectionsText(
        fromLabel: fromLabel,
        toRoomName: roomName,
        floorName: floorName,
      ).then((directions) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                directions ?? 'Following the paw trail to $roomName',
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });

      widget.onNavigationResult(result);
      Navigator.of(context).pop();
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
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF0A7040),
            unselectedLabelColor: isDark
                ? Colors.grey.shade400
                : Colors.grey.shade600,
            indicatorColor: const Color(0xFF0A7040),
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Ground'),
              Tab(text: '2nd Floor'),
              Tab(text: '3rd Floor'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Color(0xFF0A7040)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Finding route to $_loadingRoomName...',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  )
                : _buildRoomList(filteredRooms),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomList(List<Map<String, String>> rooms) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        return _buildRoomTile(room);
      },
    );
  }

  Widget _buildRoomTile(Map<String, String> room) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      elevation: 0,
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
      child: ListTile(
        title: Text(room['name']!),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _onRoomTap(room),
      ),
    );
  }
}
