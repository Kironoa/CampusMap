import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:naviapp/data/campus_landmarks.dart';
import 'package:naviapp/data/saved_spot.dart';
import 'package:naviapp/services/saved_spot_storage.dart';
import 'package:naviapp/services/osrm_service.dart';
import 'package:naviapp/screens/settings_screen.dart';
import 'dart:async';

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
  static const LatLng _tcgcCenter = LatLng(8.0645, 123.7510);
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  CampusLandmark? _selectedLandmark;
  List<SavedSpot> _personalSpots = [];
  bool _showMarkers = true;
  bool _followLocation = true;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;

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
    _loadMapSettings();
    _loadPersonalSpots();
    _startLocationTracking();
  }

  Future<void> _loadPersonalSpots() async {
    final spots = await SavedSpotStorage.loadSpots();
    if (!mounted) return;
    setState(() {
      _personalSpots = spots;
    });
  }

  Future<void> _loadMapSettings() async {
    await MapSettings.load();
    if (!mounted) return;
    setState(() {
      _showMarkers = MapSettings.showMarkers;
      _followLocation = MapSettings.followLocation;
    });
  }

  void _startLocationTracking() {
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 2,
          ),
        ).listen((Position position) {
          if (!mounted) return;
          setState(() {
            _currentPosition = position;
          });
          if (_followLocation) {
            _mapController.move(
              LatLng(position.latitude, position.longitude),
              _mapController.camera.zoom,
            );
          }
        });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onCategorySelected(String category) {
    widget.categoryFilter.value = category;
  }

  void _navigateToLandmark(CampusLandmark landmark) {
    setState(() {
      _selectedLandmark = landmark;
      _routePoints = [];
    });
    _mapController.move(landmark.position, 18.0);
    _showLandmarkBottomSheet(landmark);
  }

  Future<void> _getDirections(CampusLandmark landmark) async {
    if (!mounted) return;
    Navigator.pop(context);
    
    if (_currentPosition == null) {
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to get your location. Please enable GPS.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _isLoadingRoute = true;
    });

    final origin = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    final destination = landmark.position;

    final route = await OSRMRouteService.getRoute(origin, destination);

    if (!mounted) return;
    setState(() {
      _routePoints = route;
      _isLoadingRoute = false;
    });
    if (route.isNotEmpty) {
      _mapController.move(LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 18.0);
    }
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
                onPressed: _isLoadingRoute ? null : () => _getDirections(landmark),
                style: ElevatedButton.styleFrom(
                  backgroundColor: categoryColor(landmark.category),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isLoadingRoute
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text("GET DIRECTIONS"),
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
                    _routePoints = [];
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.naviapp',
                ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        color: const Color(0xFF2563EB),
                        strokeWidth: 4.0,
                      ),
                    ],
                  ),
                if (_showMarkers)
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
                if (_currentPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                        width: 24,
                        height: 24,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
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