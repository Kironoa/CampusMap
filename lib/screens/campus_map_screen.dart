import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:geolocator/geolocator.dart';
import '../data/database_helper.dart';
import '../data/campus_landmarks.dart';
import '../repositories/local_landmark_repository.dart';
import '../services/gemini_walkthrough_service.dart';
import '../data/floor_plan_step.dart';
import '../utils/error_handler.dart';

class CampusMapScreen extends StatefulWidget {
  const CampusMapScreen({super.key});

  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen> {
  final Completer<gmap.GoogleMapController> _controller = Completer();
  final _landmarkRepo = LocalLandmarkRepository(DatabaseHelper());
  final _searchController = TextEditingController();
  final _geminiService = GeminiWalkthroughService();

  List<CampusLandmark> _landmarks = [];
  List<gmap.Marker> _markers = [];
  String? _mapStyle;
  Position? _currentPosition;

  bool _isLoading = false;
  bool _showFloorPlanOverlay = false;
  List<FloorPlanStep> _floorPlanSteps = [];
  int _currentStepIndex = 0;
  String? _selectedFloorPlanPath;

  static const gmap.CameraPosition _initialPosition = gmap.CameraPosition(
    target: gmap.LatLng(8.0644, 123.7512),
    zoom: 17.5,
  );

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _initializeMap() async {
    await Future.wait([
      _loadMapStyle(),
      _loadLandmarks(),
      _getCurrentLocation(),
    ]);
  }

  Future<void> _loadMapStyle() async {
    try {
      final style = await DefaultAssetBundle.of(context)
          .loadString('assets/map_style.json');
      if (mounted) setState(() => _mapStyle = style);
    } catch (_) {
      // Use default style if custom fails
    }
  }

  Future<void> _loadLandmarks() async {
    try {
      final maps = await _landmarkRepo.getLandmarks();
      if (maps.isEmpty) {
        await _cacheDefaultLandmarks();
        final refreshed = await _landmarkRepo.getLandmarks();
        _landmarks = refreshed.map((m) => _landmarkFromMap(m)).toList();
      } else {
        _landmarks = maps.map((m) => _landmarkFromMap(m)).toList();
      }
      _updateMarkers();
    } catch (e) {
      if (mounted) AppErrorHandler.showErrorSnackBar(context, e);
    }
  }

  CampusLandmark _landmarkFromMap(Map<String, dynamic> map) {
    return CampusLandmark(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String? ?? 'Unknown',
      description: map['description'] as String? ?? '',
      position: gmap.LatLng(
        map['latitude'] as double,
        map['longitude'] as double,
      ),
      floor: map['floor'] as String?,
    );
  }

  Future<void> _cacheDefaultLandmarks() async {
    final maps = tcgcLandmarks
        .map((l) => {
              'id': l.id,
              'name': l.name,
              'latitude': l.position.latitude,
              'longitude': l.position.longitude,
              'description': l.description,
              'category': l.category,
              'floor': l.floor,
            })
        .toList();
    await _landmarkRepo.cacheLandmarks(maps);
  }

  void _updateMarkers() {
    _markers = _landmarks.map((l) {
      return gmap.Marker(
        markerId: gmap.MarkerId(l.id),
        position: l.position,
        infoWindow: gmap.InfoWindow(
          title: l.name,
          snippet: l.description,
        ),
        icon: gmap.BitmapDescriptor.defaultMarkerWithHue(
          _getMarkerHue(l.category),
        ),
      );
    }).toList();
    if (mounted) setState(() {});
  }

  double _getMarkerHue(String category) {
    return switch (category.toLowerCase()) {
      'buildings' => gmap.BitmapDescriptor.hueBlue,
      'offices' => gmap.BitmapDescriptor.hueOrange,
      'labs' => gmap.BitmapDescriptor.hueViolet,
      'facilities' => gmap.BitmapDescriptor.hueGreen,
      _ => gmap.BitmapDescriptor.hueRed,
    };
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      if (mounted) AppErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<void> _centerOnUser() async {
    if (_currentPosition == null) {
      await _getCurrentLocation();
      if (_currentPosition == null) return;
    }
    final controller = await _controller.future;
    await controller.animateCamera(
      gmap.CameraUpdate.newLatLngZoom(
        gmap.LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        18,
      ),
    );
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      _updateMarkers();
      return;
    }
    final filtered = _landmarks.where((l) {
      return l.name.toLowerCase().contains(query) ||
          l.description.toLowerCase().contains(query) ||
          l.category.toLowerCase().contains(query);
    }).toList();
    _markers = filtered.map((l) {
      return gmap.Marker(
        markerId: gmap.MarkerId(l.id),
        position: l.position,
        infoWindow: gmap.InfoWindow(title: l.name, snippet: l.description),
      );
    }).toList();
    setState(() {});
  }

  Future<void> _selectFloorPlan(File imageFile, String floorPlanId) async {
    setState(() {
      _isLoading = true;
      _selectedFloorPlanPath = imageFile.path;
    });

    try {
      final hasCached = await _landmarkRepo.hasCachedSteps(floorPlanId);
      if (hasCached) {
        _floorPlanSteps = await _landmarkRepo.getFloorPlanSteps(floorPlanId);
      } else {
        _floorPlanSteps = await _geminiService.analyzeFloorPlan(
          imageFile: imageFile,
          floorPlanId: floorPlanId,
        );
        await _landmarkRepo.cacheFloorPlanSteps(_floorPlanSteps);
      }
      _currentStepIndex = 0;
      setState(() => _showFloorPlanOverlay = true);
    } catch (e) {
      if (mounted) AppErrorHandler.showErrorSnackBar(context, e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _nextStep() {
    if (_currentStepIndex < _floorPlanSteps.length - 1) {
      setState(() => _currentStepIndex++);
    }
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      setState(() => _currentStepIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Campus Map',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          gmap.GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: (controller) => _controller.complete(controller),
            markers: Set<gmap.Marker>.from(_markers),
            style: _mapStyle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildSearchBar(),
          ),
          if (_isLoading)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text(
                        'Analyzing floor plan with AI...',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_showFloorPlanOverlay && _selectedFloorPlanPath != null)
            _buildFloorPlanOverlay(),
          Positioned(
            bottom: 24,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  onPressed: _centerOnUser,
                  heroTag: 'location',
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  onPressed: () => _showFloorPlanPicker(),
                  heroTag: 'floorplan',
                  child: const Icon(Icons.layers),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return SearchBar(
      controller: _searchController,
      hintText: 'Search campus buildings...',
      hintStyle: WidgetStateProperty.all(
        const TextStyle(fontFamily: 'Poppins', color: Colors.grey),
      ),
      textStyle: WidgetStateProperty.all(
        const TextStyle(fontFamily: 'Poppins'),
      ),
      leading: const Icon(Icons.search),
      trailing: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              _onSearchChanged();
            },
          ),
      ],
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevation: WidgetStateProperty.all(4),
    );
  }

  Widget _buildFloorPlanOverlay() {
    final step = _floorPlanSteps[_currentStepIndex];
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Floor Plan Walkthrough',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () =>
                        setState(() => _showFloorPlanOverlay = false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    Image.file(
                      File(_selectedFloorPlanPath!),
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                    Positioned(
                      left: step.x * 200 - 10,
                      top: step.y * 200 - 10,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Step ${_currentStepIndex + 1} of ${_floorPlanSteps.length}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                step.description,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStepIndex > 0)
                    TextButton.icon(
                      onPressed: _previousStep,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text(
                        'Previous',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  if (_currentStepIndex < _floorPlanSteps.length - 1)
                    TextButton.icon(
                      onPressed: _nextStep,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text(
                        'Next',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFloorPlanPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Floor Plan',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.layers),
              title: const Text(
                'Second Floor',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              subtitle: const Text(
                'Main academic building - 2nd floor',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              onTap: () {
                Navigator.pop(context);
                _selectFloorPlan(
                  File('assets/images/second_floor.png'),
                  'second_floor',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.layers),
              title: const Text(
                'Ground Floor',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              subtitle: const Text(
                'Main academic building - Ground floor',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              onTap: () {
                Navigator.pop(context);
                _selectFloorPlan(
                  File('assets/images/ground_floor.png'),
                  'ground_floor',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
