// lib/widgets/ai_nav_sheet.dart
import 'package:flutter/material.dart';
import '../services/ai_navigation_service.dart';
import '../services/navigation_graph.dart';
import '../services/pathfinder.dart';

typedef RoomEntry = Map<String, String>;
typedef RoomList = List<RoomEntry>;

class AINavSheet extends StatefulWidget {
  final Function(AINavigationResult) onNavigationResult;
  final String initialFloor;

  const AINavSheet({
    super.key,
    required this.onNavigationResult,
    this.initialFloor = 'Ground Floor',
  });

  @override
  State<AINavSheet> createState() => _AINavSheetState();
}

class _AINavSheetState extends State<AINavSheet> with SingleTickerProviderStateMixin {
  static const Map<String, List<Map<String, String>>> startingPoints = {
    'Ground Floor': [
      {'label': 'Main Entrance / Driveway', 'nodeId': 'gf_entry_driveway'},
      {'label': 'Top Center Door', 'nodeId': 'gf_entry_top'},
      {'label': 'Left Staircase', 'nodeId': 'gf_entry_stairs_left'},
      {'label': 'Right Staircase', 'nodeId': 'gf_entry_stairs_right'},
    ],
    '2nd Floor': [
      {'label': 'Left Staircase', 'nodeId': 'sf_entry_stairs_left'},
      {'label': 'Right Staircase', 'nodeId': 'sf_entry_stairs_right'},
      {'label': 'Center Staircase', 'nodeId': 'sf_h_spine'},
      {'label': 'Deck Canopy Entrance', 'nodeId': 'sf_entry_deck'},
    ],
    '3rd Floor': [
      {'label': 'Left Staircase', 'nodeId': 'tf_entry_stairs_left'},
      {'label': 'Right Staircase', 'nodeId': 'tf_entry_stairs_right'},
      {'label': 'Elevator', 'nodeId': 'tf_entry_elevator'},
    ],
  };

  static const Map<String, RoomList> allRooms = {
    'Ground Floor': [
      {'name': 'Main Lobby', 'id': 'gf_main_lobby'},
      {'name': 'Drive Way', 'id': 'gf_drive_way'},
      {'name': 'Scholarship and Welfare Office', 'id': 'gf_scholarship_welfare'},
      {'name': 'OJT & Placement / Alumni Affairs Office', 'id': 'gf_ojt_placement'},
      {'name': 'Accreditation Room', 'id': 'gf_accreditation'},
      {'name': 'Record Section Registrar', 'id': 'gf_record_registrar'},
      {"name": "Registrar's Office", 'id': 'gf_registrar'},
      {'name': 'VP Admin and Finance', 'id': 'gf_vp_admin'},
      {'name': 'Criminology Laboratory', 'id': 'gf_crim_lab'},
      {'name': 'Institute of Criminal Justice Education', 'id': 'gf_icje'},
      {'name': 'Student Life and Development Office', 'id': 'gf_sldo'},
      {'name': 'CISO', 'id': 'gf_ciso'},
      {'name': 'Audio Visual Room', 'id': 'gf_avr'},
      {'name': 'Dressing Room', 'id': 'gf_dressing'},
      {'name': 'Music Room', 'id': 'gf_music'},
      {'name': 'Dance Studio', 'id': 'gf_dance'},
      {'name': 'Maintenance Student Assistant Personnel Barracks', 'id': 'gf_barracks'},
      {'name': 'Medical & Dental Clinic', 'id': 'gf_medical'},
      {'name': 'Rest Room (Left Wing)', 'id': 'gf_restroom_left'},
      {'name': 'Rest Room (Center)', 'id': 'gf_restroom_center'},
      {'name': 'Rest Room (Right)', 'id': 'gf_restroom_right'},
      {'name': 'MB 105', 'id': 'gf_mb105'},
      {'name': 'MB 103 / Demo Room', 'id': 'gf_mb103'},
      {'name': 'Multi-Purpose Room', 'id': 'gf_mpr'},
      {'name': 'Midwifery Laboratory', 'id': 'gf_midwifery'},
      {'name': 'Physical Facilities Operation & Maintenance (PFOM)', 'id': 'gf_pfom'},
      {'name': 'Institute of Arts & Sciences', 'id': 'gf_ias'},
      {'name': 'Institute of Teacher Education', 'id': 'gf_ite'},
      {'name': 'Institute of Business & Financial Services', 'id': 'gf_ibfs'},
      {'name': 'Institute of Health Sciences', 'id': 'gf_ihs'},
      {"name": "TCGC Dev't Training Center", 'id': 'gf_training'},
      {'name': 'Institute of Computer Studies', 'id': 'gf_ics'},
      {'name': 'CR (Left 1)', 'id': 'gf_cr_left1'},
      {'name': 'CR (Left 2)', 'id': 'gf_cr_left2'},
      {'name': 'CR (Right 1)', 'id': 'gf_cr_right1'},
      {'name': 'CR (Right 2)', 'id': 'gf_cr_right2'},
      {'name': 'Elevator', 'id': 'gf_elevator'},
    ],
    '2nd Floor': [
      {'name': 'Main Stage', 'id': 'sf_main_stage'},
      {'name': 'Guidance Testing Center', 'id': 'sf_guidance_testing'},
      {'name': 'Sub-Lobby', 'id': 'sf_sub_lobby'},
      {'name': 'Computer Laboratory', 'id': 'sf_computer_lab'},
      {'name': 'Computer Room (1)', 'id': 'sf_computer_room_1'},
      {'name': 'Computer Room (2)', 'id': 'sf_computer_room_2'},
      {'name': 'Computer Room (3)', 'id': 'sf_computer_room_3'},
      {'name': 'Rest Room (Left)', 'id': 'sf_restroom_left'},
      {'name': 'Rest Room (Center Left)', 'id': 'sf_restroom_center_left'},
      {'name': 'Rest Room (Center Right)', 'id': 'sf_restroom_center_right'},
      {'name': 'Rest Room (Right)', 'id': 'sf_restroom_right'},
      {'name': 'VIP Lounge', 'id': 'sf_vip_lounge'},
      {'name': 'Faculty and Staff Lounge', 'id': 'sf_faculty_lounge'},
      {'name': 'Speech Lab', 'id': 'sf_speech_lab'},
      {'name': 'BSEED Simulation Room (Left)', 'id': 'sf_bseed_left'},
      {'name': 'BSEED Simulation Room (Right)', 'id': 'sf_bseed_right'},
      {'name': 'Guidance Counseling Room', 'id': 'sf_guidance_counseling'},
      {'name': 'Moot Court', 'id': 'sf_moot_court'},
      {'name': 'Business Center', 'id': 'sf_business_center'},
      {'name': 'Classroom (Left)', 'id': 'sf_classroom_left'},
      {'name': 'Class Room (Center)', 'id': 'sf_classroom_center'},
      {'name': 'Class Room (Right)', 'id': 'sf_classroom_right'},
      {'name': 'Board Room', 'id': 'sf_board_room'},
      {'name': 'Human Resource Management Office', 'id': 'sf_hrmo'},
      {'name': 'Faculty Room', 'id': 'sf_faculty_room'},
      {'name': 'Supply Office', 'id': 'sf_supply'},
      {'name': 'VP for Planning', 'id': 'sf_vp_planning'},
      {'name': 'Executive Vice President Office', 'id': 'sf_evp'},
      {"name": "Dean's Office", 'id': 'sf_deans'},
      {'name': 'VP for Academic Affairs', 'id': 'sf_vpaa'},
      {'name': 'Office of the President', 'id': 'sf_president'},
      {'name': 'Deck Canopy', 'id': 'sf_deck_canopy'},
      {'name': 'Bleacher (Left Wing)', 'id': 'sf_bleacher_left'},
      {'name': 'Bleacher (Right Wing)', 'id': 'sf_bleacher_right'},
    ],
    '3rd Floor': [
      {'name': 'Library', 'id': 'tf_library'},
      {'name': 'LRC Extension 1', 'id': 'tf_lrc1'},
      {'name': 'LRC Extension 2', 'id': 'tf_lrc2'},
      {'name': 'Prayer Room', 'id': 'tf_prayer'},
      {'name': 'Activity Area', 'id': 'tf_activity'},
      {'name': 'Research Extension Development', 'id': 'tf_research'},
      {'name': 'Rest Room (Left)', 'id': 'tf_restroom_left'},
      {'name': 'Rest Room (Right)', 'id': 'tf_restroom_right'},
      {'name': 'Classroom (1)', 'id': 'tf_classroom_1'},
      {'name': 'Classroom (2)', 'id': 'tf_classroom_2'},
      {'name': 'Classroom (3)', 'id': 'tf_classroom_3'},
      {'name': 'Classroom (4)', 'id': 'tf_classroom_4'},
      {'name': 'Classroom (5)', 'id': 'tf_classroom_5'},
      {'name': 'Classroom (6)', 'id': 'tf_classroom_6'},
      {'name': 'Science Laboratory', 'id': 'tf_science_lab'},
      {'name': 'Elevator', 'id': 'tf_elevator'},
      {'name': 'Main Stage', 'id': 'tf_main_stage'},
      {'name': 'Bleacher (Left Wing)', 'id': 'tf_bleacher_left'},
      {'name': 'Bleacher (Right Wing)', 'id': 'tf_bleacher_right'},
    ],
  };

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  String? _loadingRoomName;

  int _step = 1;
  String? _selectedStartFloor;
  String? _selectedStartNodeId;
  String? _selectedStartLabel;

  final List<String> _floorKeys = ['Ground Floor', '2nd Floor', '3rd Floor'];

  final Map<String, int> _floorIndices = {
    'Ground Floor': 0,
    '2nd Floor': 1,
    '3rd Floor': 2,
  };

  @override
  void initState() {
    super.initState();
    final initialIndex = _floorKeys.indexOf(widget.initialFloor);
    _selectedStartFloor = widget.initialFloor;
    _tabController = TabController(length: 3, vsync: this, initialIndex: initialIndex >= 0 ? initialIndex : 0);
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

  Map<String, RoomList> _filterRooms() {
    if (_searchQuery.isEmpty) {
      return allRooms;
    }
    final query = _searchQuery.toLowerCase();
    final Map<String, RoomList> filtered = {};
    for (final floor in _floorKeys) {
      final rooms = allRooms[floor]!.where((room) =>
        room['name']!.toLowerCase().contains(query)).toList();
      if (rooms.isNotEmpty) {
        filtered[floor] = rooms;
      }
    }
    return filtered;
  }

  int _getFloorIndex(String floorKey) {
    return _floorIndices[floorKey] ?? 0;
  }

  Future<void> _onRoomTap(RoomEntry room) async {
    final roomName = room['name']!;
    final roomId = room['id']!;
    final currentFloor = _floorKeys[_tabController.index];
    final floorIndex = _getFloorIndex(currentFloor);

    setState(() {
      _isLoading = true;
      _loadingRoomName = roomName;
    });

    try {
      final nodes = NavigationGraph.getNodes(floorIndex);
      final edges = NavigationGraph.getEdges(floorIndex);

      final startNodeId = _selectedStartNodeId ?? NavigationGraph.getDefaultStartNode(floorIndex) ?? nodes.first.id;
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
          SnackBar(
            content: const Text('No accessible path found'),
            backgroundColor: Colors.red.shade700,
          ),
        );
        setState(() {
          _isLoading = false;
          _loadingRoomName = null;
        });
        return;
      }

      final fromLabel = _selectedStartLabel ?? 'your location';
      final result = await AINavigationService.instance.navigate(
        roomName: roomName,
        roomId: roomId,
        floorIndex: floorIndex,
        startNodeId: startNodeId,
        endNodeId: endNodeId,
        fromLabel: fromLabel,
      );

      if (!mounted) return;

      final fullResult = AINavigationResult(
        answer: result.answer,
        floor: floorIndex.toString(),
        pathPoints: pathPoints,
        steps: result.steps,
      );

      widget.onNavigationResult(fullResult);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigation error: ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
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

  void _onStartPointSelected(String floor, Map<String, String> start) {
    setState(() {
      _selectedStartFloor = floor;
      _selectedStartNodeId = start['nodeId'];
      _selectedStartLabel = start['label'];
      _step = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filteredRooms = _filterRooms();
    final currentFloor = _floorKeys[_tabController.index];
    final currentStartPoints = startingPoints[_selectedStartFloor ?? widget.initialFloor] ?? [];

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
              _step == 1 ? 'Where are you now?' : 'Where do you want to go?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_step == 1)
            _buildStartPointSelector(currentStartPoints, _selectedStartFloor ?? widget.initialFloor)
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
              labelColor: Colors.orange,
              unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              indicatorColor: Colors.orange,
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
                          valueColor: AlwaysStoppedAnimation(Colors.orange),
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
                    : _searchQuery.isNotEmpty
                        ? _buildSearchResults(filteredRooms)
                        : _buildFloorRooms(currentFloor),
          ),
        ],
      ),
    );
  }

  Widget _buildStartPointSelector(List<Map<String, String>> points, String floor) {
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
            children: points.map((start) {
              final isSelected = _selectedStartNodeId == start['nodeId'];
              return ChoiceChip(
                label: Text(start['label']!),
                selected: isSelected,
                selectedColor: Colors.orange,
                onSelected: (selected) {
                  if (selected) {
                    _onStartPointSelected(floor, start);
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorRooms(String floor) {
    final rooms = allRooms[floor] ?? [];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        return _buildRoomTile(room);
      },
    );
  }

  Widget _buildSearchResults(Map<String, RoomList> filteredRooms) {
    final floors = filteredRooms.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: floors.length,
      itemBuilder: (context, floorIndex) {
        final floor = floors[floorIndex];
        final rooms = filteredRooms[floor]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                floor == 'Ground Floor' ? 'Ground Floor' : floor,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                  fontSize: 14,
                ),
              ),
            ),
            ...rooms.map((room) => _buildRoomTile(room)),
          ],
        );
      },
    );
  }

  Widget _buildRoomTile(RoomEntry room) {
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