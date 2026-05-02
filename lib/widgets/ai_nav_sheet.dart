import 'package:flutter/material.dart';
import 'package:naviapp/data/floor_plan_data.dart';

class AINavSheet extends StatefulWidget {
  final String? currentFloor;
  final String? currentRoomId;
  final void Function(List<Offset> pathPoints, int? targetFloor, String? targetRoomId)? onNavigationResult;
  final void Function(String destination)? onNavigateRequest;

  const AINavSheet({
    super.key,
    this.currentFloor,
    this.currentRoomId,
    this.onNavigationResult,
    this.onNavigateRequest,
  });

  @override
  State<AINavSheet> createState() => _AINavSheetState();
}

class _AINavSheetState extends State<AINavSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Map<String, String>> get _allPlaces {
    final List<Map<String, String>> places = [];
    for (final room in FloorPlanData.groundFloorRooms) {
      places.add({'name': room.name, 'id': room.id, 'floor': 'Ground Floor'});
    }
    for (final room in FloorPlanData.secondFloorRooms) {
      places.add({'name': room.name, 'id': room.id, 'floor': 'Second Floor'});
    }
    for (final room in FloorPlanData.thirdFloorRooms) {
      places.add({'name': room.name, 'id': room.id, 'floor': 'Third Floor'});
    }
    return places;
  }

  List<Map<String, String>> get _filteredPlaces {
    if (_searchQuery.isEmpty) return _allPlaces;
    return _allPlaces.where((place) =>
      place['name']!.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  void _navigateToPlace(Map<String, String> place) {
    Navigator.pop(context);
    widget.onNavigateRequest?.call(place['id']!);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C1F0E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF4B3621) : const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.psychology_outlined,
                    color: Color(0xFF16A34A), size: 24),
                const SizedBox(width: 8),
                Text('Select Destination',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFFFF7ED) : const Color(0xFF1C0A00),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search places...',
                hintStyle: TextStyle(
                  color: isDark
                      ? const Color(0xFFFED7AA)
                      : const Color(0xFF78350F),
                ),
                prefixIcon: Icon(Icons.search, color: isDark ? const Color(0xFFFED7AA) : const Color(0xFF78350F)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFFFED7AA)
                        : const Color(0xFFD1D5DB),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFFFED7AA)
                        : const Color(0xFFD1D5DB),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: Color(0xFFF97316),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredPlaces.length,
              itemBuilder: (context, index) {
                final place = _filteredPlaces[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isDark ? const Color(0xFF3D2A10) : const Color(0xFFFFF7ED),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.location_on, color: Color(0xFFF97316), size: 20),
                    ),
                    title: Text(
                      place['name']!,
                      style: TextStyle(
                        color: isDark ? const Color(0xFFFFF7ED) : const Color(0xFF1C0A00),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      place['floor']!,
                      style: TextStyle(
                        color: isDark ? const Color(0xFFFED7AA) : const Color(0xFF78350F),
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFFF97316)),
                    onTap: () => _navigateToPlace(place),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}