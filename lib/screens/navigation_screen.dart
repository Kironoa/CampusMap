import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:naviapp/data/campus_landmarks.dart';
import 'package:naviapp/data/saved_spot.dart';
import 'package:naviapp/services/saved_spot_storage.dart';

class NavigationScreen extends StatefulWidget {
  final String? initialSearch;
  final bool autoNavigate;
  final ValueNotifier<String> categoryFilter;
  final ValueNotifier<bool> searchOpen;

  const NavigationScreen({
    super.key,
    this.initialSearch,
    this.autoNavigate = false,
    required this.categoryFilter,
    required this.searchOpen,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  static const LatLng _tcgcCenter = LatLng(8.0600, 123.7540);
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  CampusLandmark? _selectedLandmark;
  List<SavedSpot> _personalSpots = [];

  final List<String> _categories = [
    'All',
    'Buildings',
    'Offices',
    'Labs',
    'Facilities',
  ];

  List<CampusLandmark> _getFilteredLandmarks(String category) {
    return filterByCategory(category);
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialSearch != null) {
      _searchController.text = widget.initialSearch!;
    }
    _loadPersonalSpots();
  }

  Future<void> _loadPersonalSpots() async {
    final spots = await SavedSpotStorage.loadSpots();
    if (mounted) {
      setState(() {
        _personalSpots = spots;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onCategorySelected(String category) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.categoryFilter.value = category;
    });
  }

  void _navigateToLandmark(CampusLandmark landmark) {
    setState(() {
      _selectedLandmark = landmark;
    });
    _mapController.move(landmark.position, 18.0);
    _showLandmarkBottomSheet(landmark);
  }

  void _showLandmarkBottomSheet(CampusLandmark landmark) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: categoryColor(landmark.category).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    categoryIcon(landmark.category),
                    color: categoryColor(landmark.category),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        landmark.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        landmark.floor ?? landmark.category,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedLandmark = null;
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              landmark.description,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: categoryColor(landmark.category),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text("GET DIRECTIONS"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: widget.categoryFilter,
      builder: (context, activeCategory, _) {
        final filteredLandmarks = _getFilteredLandmarks(activeCategory);
        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _tcgcCenter,
                initialZoom: 16.0,
                onTap: (tapPos, point) {
                  setState(() {
                    _selectedLandmark = null;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.naviapp',
                ),
                MarkerLayer(
                  markers: [
                    ...filteredLandmarks.map((landmark) {
                      final isSelected = _selectedLandmark?.id == landmark.id;
                      return Marker(
                        point: landmark.position,
                        width: isSelected ? 50 : 40,
                        height: isSelected ? 50 : 40,
                        child: GestureDetector(
                          onTap: () => _navigateToLandmark(landmark),
                          child: Container(
                            decoration: BoxDecoration(
                              color: categoryColor(landmark.category),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              categoryIcon(landmark.category),
                              color: Colors.white,
                              size: isSelected ? 28 : 22,
                            ),
                          ),
                        ),
                      );
                    }),
                    ..._personalSpots.map((spot) {
                      return Marker(
                        point: spot.position,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.bookmark,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 0,
              right: 0,
              child: _buildCategoryChips(activeCategory),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryChips(String activeCategory) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _categories.map((cat) {
          final isSelected = cat == activeCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (_) => _onCategorySelected(cat),
              showCheckmark: false,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF2563EB),
              elevation: 2,
              shadowColor: Colors.black26,
            ),
          );
        }).toList(),
      ),
    );
  }
}