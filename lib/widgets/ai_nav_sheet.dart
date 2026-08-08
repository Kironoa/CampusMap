// lib/widgets/ai_nav_sheet.dart
import 'package:flutter/material.dart';
import '../services/ai_navigation_service.dart';
import '../services/navigation_graph.dart';
import '../services/pathfinder.dart';
import '../services/room_catalog.dart';

class AINavSheet extends StatefulWidget {
  final String floorImagePath;
  final String? currentFloor;
  final int currentFloorIndex;
  final String? currentRoomId;
  final void Function(List<Offset> pathOffsets, int floorIndex, String? roomId) onNavigationResult;
  final void Function(String fromLabel, String toRoomName, String floorName)? onNavigateRequest;

  const AINavSheet({
    super.key,
    this.floorImagePath = '',
    this.currentFloor,
    this.currentFloorIndex = 0,
    this.currentRoomId,
    required this.onNavigationResult,
    this.onNavigateRequest,
  });

  @override
  State<AINavSheet> createState() => _AINavSheetState();
}

class _AINavSheetState extends State<AINavSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  String? _loadingRoomName;

  int _step = 1;
  int? _selectedFloorIndex;
  String? _selectedStartNodeId;
  String? _selectedStartLabel;

  final List<String> _floorKeys = ['Ground Floor', '2nd Floor', '3rd Floor'];

  @override
  void initState() {
    super.initState();
    _selectedFloorIndex = widget.currentFloorIndex;
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
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> _getFilteredRooms() {
    final floor = _floorKeys[_tabController.index];
    final rooms = RoomCatalog.allRooms[floor]!;
    if (_searchQuery.isEmpty) {
      return rooms;
    }
    final query = _searchQuery.toLowerCase();
    return rooms.where((room) =>
      room['name']!.toLowerCase().contains(query)).toList();
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
      final nodes = NavigationGraph.nodesForFloor(floorIndex);
      final edges = NavigationGraph.edgesForFloor(floorIndex);

      final startNodeId = _selectedStartNodeId ??
          NavigationGraph.startingPoints[floorIndex]?.first['nodeId'] ??
          nodes.first.id;
      final endNodeId = Pathfinder.findNearestNodeToRoom(roomId, floorIndex);

      final pathPoints = Pathfinder.findPath(
        startNodeId: startNodeId,
        endNodeId: endNodeId,
        nodes: nodes,
        edges: edges,
      );

      if (pathPoints.isEmpty) {
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

      final fromLabel = _selectedStartLabel ?? 'your location';
      final floorName = _floorKeys[floorIndex];

      AINavigationService.getDirectionsText(
        fromLabel: fromLabel,
        toRoomName: roomName,
        floorName: floorName,
      ).then((directions) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(directions ?? 'Following the paw trail to $roomName'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });

      widget.onNavigationResult(pathPoints, floorIndex, roomId);
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

  void _onStartPointSelected(int floorIndex, Map<String, String> start) {
    setState(() {
      _selectedFloorIndex = floorIndex;
      _selectedStartNodeId = start['nodeId'];
      _selectedStartLabel = start['label'];
      _step = 2;
    });
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
            child: Text(
              _step == 1 ? '📍 Where are you starting from?' : '🏁 Where do you want to go?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_step == 1)
            _buildStartPointSelector()
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search rooms...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF0A7040),
              unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              indicatorColor: const Color(0xFF0A7040),
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Ground'),
                Tab(text: '2nd Floor'),
                Tab(text: '3rd Floor'),
              ],
            ),
            const SizedBox(height: 8),
          ],
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
                : _step == 1
                    ? const SizedBox.shrink()
                    : _buildRoomList(filteredRooms),
          ),
        ],
      ),
    );
  }

  Widget _buildStartPointSelector() {
    _selectedFloorIndex ??= widget.currentFloorIndex;
    final floorStartPoints = NavigationGraph.startingPoints[_selectedFloorIndex!] ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select your current location:',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: floorStartPoints.map((start) {
              final isSelected = _selectedStartNodeId == start['nodeId'];
              return ChoiceChip(
                label: Text(start['label']!),
                selected: isSelected,
                selectedColor: const Color(0xFF0A7040),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : null,
                ),
                onSelected: (selected) {
                  if (selected) {
                    _onStartPointSelected(_selectedFloorIndex!, start);
                  }
                },
              );
            }).toList(),
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