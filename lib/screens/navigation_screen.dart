import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import 'package:naviapp/data/campus_landmarks.dart';
import 'package:naviapp/config/env.dart';
import 'package:naviapp/services/directions_service.dart';
import 'package:naviapp/screens/settings_screen.dart';
import 'package:naviapp/utils/ui_utils.dart' as ui;

class NavigationScreen extends StatefulWidget {
  final ValueNotifier<String>? categoryFilter;
  final ValueNotifier<bool>? searchOpen;

  const NavigationScreen({
    super.key,
    this.categoryFilter,
    this.searchOpen,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  static const LatLng _tcgcCenter = LatLng(8.0645, 123.7508);
  LatLng? _lastKnownPosition;
  bool _followUser = true;
  bool _isSearching = false;
  bool _isOffline = false;
  String _selectedCategory = 'All';
  Set<Polyline> _polylines = {};
  CampusLandmark? _selectedLandmark;
  final TextEditingController _searchController = TextEditingController();
  final Connectivity _connectivity = Connectivity();
  List<CampusLandmark> _filteredLandmarks = tcgcLandmarks;

  bool _isLoadingRoute = false;
  bool _isNavigatingActive = false;
  MapType _mapType = MapType.hybrid;
  CampusLandmark? _activeDest;
  double? _liveDistance;

  final List<String> _categories = ['All', 'Buildings', 'Offices', 'Labs', 'Facilities'];

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
    _initConnectivity();
    _loadMapSettings();
    widget.categoryFilter?.addListener(_onCategoryFilterChanged);
    widget.searchOpen?.addListener(_onSearchOpenChanged);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _connectivitySubscription?.cancel();
    _searchController.dispose();
    widget.categoryFilter?.removeListener(_onCategoryFilterChanged);
    widget.searchOpen?.removeListener(_onSearchOpenChanged);
    super.dispose();
  }

  void _onCategoryFilterChanged() {
    final filter = widget.categoryFilter?.value ?? 'All';
    if (filter != _selectedCategory) {
      setState(() {
        _selectedCategory = filter;
        _updateSearchResults();
      });
    }
  }

  void _onSearchOpenChanged() {
    if (widget.searchOpen?.value == true) {
      setState(() => _isSearching = true);
      widget.searchOpen?.value = false;
    }
  }

  Future<void> _loadMapSettings() async {
    await MapSettings.load();
    if (mounted) {
      setState(() {
        _mapType = MapType.values[MapSettings.mapType.clamp(0, 3)];
        _followUser = MapSettings.followLocation;
      });
    }
  }

  Future<void> _initConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectivityStatus(result);
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectivityStatus);
  }

  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    final wasOffline = _isOffline;
    _isOffline = !results.contains(ConnectivityResult.wifi) &&
        !results.contains(ConnectivityResult.mobile) &&
        !results.contains(ConnectivityResult.ethernet);
    if (wasOffline != _isOffline && mounted) {
      setState(() {});
      if (_isOffline) {
        _showOfflineBanner();
      } else {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      }
    }
  }

  void _showOfflineBanner() {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: const Text("You're offline — map may be limited"),
        backgroundColor: Colors.orange.shade100,
        leading: const Icon(Icons.wifi_off, color: Colors.orange),
        actions: [
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
            child: const Text("DISMISS"),
          ),
        ],
      ),
    );
  }

  Future<void> _initLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationServiceDialog();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) {
      _showPermissionDeniedDialog();
      return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
      ),
    ).listen((Position position) {
      LatLng newPos = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() => _lastKnownPosition = newPos);
        if (_followUser && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: newPos, zoom: 19.0, tilt: 45.0),
            ),
          );
        }
        if (_isNavigatingActive && _activeDest != null) {
          final distance = DirectionsService.calculateDistance(newPos, _activeDest!.position);
          setState(() => _liveDistance = distance);
          if (distance < 15) {
            _showArrivalDialog();
          }
        }
      }
    });
  }

  void _showArrivalDialog() {
    _isNavigatingActive = false;
    _activeDest = null;
    _liveDistance = null;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('You\'ve Arrived!'),
        content: Text('You\'ve arrived at ${_selectedLandmark?.name ?? "your destination"}!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _polylines = {};
                _selectedLandmark = null;
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services'),
        content: const Text('Please enable location services to use navigation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Denied'),
        content: const Text('Location permission is required. Please enable it in settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _updateSearchResults() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _filteredLandmarks = filterByCategory(_selectedCategory);
      });
    } else {
      final results = searchLandmarks(_searchController.text);
      if (_selectedCategory != 'All') {
        setState(() {
          _filteredLandmarks = results.where((l) => l.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
        });
      } else {
        setState(() {
          _filteredLandmarks = results;
        });
      }
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _updateSearchResults();
  }

  Color _getCategoryColor(String category) {
    return switch (category.toLowerCase()) {
      'buildings' => const Color(0xFF2563EB),
      'offices' => const Color(0xFFEA580C),
      'labs' => const Color(0xFF7C3AED),
      'facilities' => const Color(0xFF059669),
      _ => const Color(0xFF0891B2),
    };
  }

  Future<void> _navigateToLandmark(CampusLandmark landmark) async {
    setState(() {
      _selectedLandmark = landmark;
    });
    _showLandmarkDetailSheet(landmark);
  }

  void _showLandmarkDetailSheet(CampusLandmark landmark) {
    final distance = _lastKnownPosition != null
        ? DirectionsService.calculateDistance(_lastKnownPosition!, landmark.position)
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(landmark.category),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    landmark.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                landmark.category,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              landmark.description,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            if (landmark.floor != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.layers, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Floor: ${landmark.floor}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
            if (distance != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.location_on, size: 18, color: _getCategoryColor(landmark.category)),
                  const SizedBox(width: 8),
                  Text(
                    DirectionsService.formatDistance(distance),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 24),
                  Icon(Icons.directions_walk, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    DirectionsService.formatWalkingTime(distance),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _fetchRoute(landmark);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getCategoryColor(landmark.category),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Get Directions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchRoute(CampusLandmark landmark) async {
    if (_lastKnownPosition == null) return;

    setState(() {
      _selectedLandmark = landmark;
      _polylines = {};
      _isLoadingRoute = true;
    });

    final routePoints = await DirectionsService.getRoute(
      _lastKnownPosition!,
      landmark.position,
      Env.mapsApiKey,
    );

    if (!mounted) return;

    setState(() => _isLoadingRoute = false);

    if (routePoints.isNotEmpty) {
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: routePoints,
            color: _getCategoryColor(landmark.category),
            width: 5,
          ),
        };
      });
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(landmark.position, 18),
    );

    _showRouteBottomSheet(landmark);
  }

  void _showRouteBottomSheet(CampusLandmark landmark) {
    final distance = _lastKnownPosition != null
        ? DirectionsService.calculateDistance(_lastKnownPosition!, landmark.position)
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoadingRoute) const LinearProgressIndicator(),
            if (!_isLoadingRoute) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(landmark.category).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: _getCategoryColor(landmark.category),
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
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _polylines = {};
                        _selectedLandmark = null;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              if (distance != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.directions_walk, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(DirectionsService.formatDistance(distance)),
                    const SizedBox(width: 24),
                    Icon(Icons.schedule, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(DirectionsService.formatWalkingTime(distance)),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _startNavigation(landmark);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getCategoryColor(landmark.category),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'START NAVIGATION',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _startNavigation(CampusLandmark landmark) {
    setState(() {
      _isNavigatingActive = true;
      _activeDest = landmark;
      _liveDistance = _lastKnownPosition != null
          ? DirectionsService.calculateDistance(_lastKnownPosition!, landmark.position)
          : null;
    });
  }

  void _stopNavigation() {
    setState(() {
      _isNavigatingActive = false;
      _activeDest = null;
      _liveDistance = null;
      _polylines = {};
    });
  }

  BitmapDescriptor _getMarkerIcon(String category) {
    return BitmapDescriptor.defaultMarkerWithHue(switch (category.toLowerCase()) {
      'buildings' => BitmapDescriptor.hueBlue,
      'offices' => BitmapDescriptor.hueOrange,
      'labs' => BitmapDescriptor.hueViolet,
      'facilities' => BitmapDescriptor.hueCyan,
      _ => BitmapDescriptor.hueRose,
    });
  }

  Set<Marker> _buildMarkers() {
    if (!MapSettings.showMarkers) return {};
    return _filteredLandmarks.map((landmark) => Marker(
      markerId: MarkerId(landmark.id),
      position: landmark.position,
      icon: _getMarkerIcon(landmark.category),
      infoWindow: InfoWindow(
        title: landmark.name,
        snippet: landmark.floor ?? landmark.description,
      ),
      onTap: () => _navigateToLandmark(landmark),
    )).toSet();
  }

  IconData _getCategoryIcon(String category) {
    return switch (category.toLowerCase()) {
      'buildings' => Icons.business,
      'offices' => Icons.meeting_room,
      'labs' => Icons.computer,
      'facilities' => Icons.local_activity,
      _ => Icons.place,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    double r(double v) => ui.res(context, v);

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _tcgcCenter,
              zoom: 18.0,
            ),
            onMapCreated: (controller) => _mapController = controller,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            mapType: _mapType,
            onCameraMoveStarted: () {
              if (_followUser) setState(() => _followUser = false);
            },
            markers: _buildMarkers(),
            polylines: _polylines,
          ),
          _buildSearchOverlay(theme, colorScheme, r),
          _buildCategoryChips(theme, colorScheme, r),
          Positioned(
            right: r(16),
            bottom: 200,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoomIn',
                  backgroundColor: colorScheme.surface,
                  onPressed: () => _mapController?.animateCamera(
                    CameraUpdate.zoomIn(),
                  ),
                  child: Icon(Icons.add, color: colorScheme.primary),
                ),
                SizedBox(height: r(8)),
                FloatingActionButton.small(
                  heroTag: 'zoomOut',
                  backgroundColor: colorScheme.surface,
                  onPressed: () => _mapController?.animateCamera(
                    CameraUpdate.zoomOut(),
                  ),
                  child: Icon(Icons.remove, color: colorScheme.primary),
                ),
                SizedBox(height: r(16)),
                if (!_followUser && _lastKnownPosition != null)
                  FloatingActionButton(
                    heroTag: 'recenter',
                    backgroundColor: colorScheme.primary,
                    onPressed: () {
                      setState(() => _followUser = true);
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLng(_lastKnownPosition!),
                      );
                    },
                    child: const Icon(Icons.my_location, color: Colors.white),
                  ),
              ],
            ),
          ),
          _buildInfoPanel(theme, colorScheme, r),
          if (_isNavigatingActive) _buildNavigationStatusBar(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildSearchOverlay(ThemeData theme, ColorScheme colorScheme, double Function(double) r) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(r(16)),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: r(12), vertical: r(10)),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: Offset(0, r(4)),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: _isSearching
                        ? const Icon(Icons.close)
                        : const Icon(Icons.arrow_back),
                    onPressed: () {
                      if (_isSearching) {
                        setState(() {
                          _isSearching = false;
                          _searchController.clear();
                          _updateSearchResults();
                        });
                      } else if (widget.categoryFilter == null) {
                        Navigator.maybePop(context);
                      }
                    },
                  ),
                  SizedBox(width: r(8)),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search campus locations...',
                        border: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (_) => _updateSearchResults(),
                      onSubmitted: (value) {
                        setState(() => _isSearching = true);
                        _updateSearchResults();
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      setState(() => _isSearching = true);
                      _updateSearchResults();
                    },
                  ),
                ],
              ),
            ),
            if (_isSearching && _filteredLandmarks.isNotEmpty) ...[
              SizedBox(height: r(8)),
              Container(
                constraints: BoxConstraints(maxHeight: r(250)),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: Offset(0, r(4)),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.all(r(8)),
                  itemCount: _filteredLandmarks.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final landmark = _filteredLandmarks[index];
                    return _buildSearchResultTile(landmark, r);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultTile(CampusLandmark landmark, double Function(double) r) {
    final color = _getCategoryColor(landmark.category);
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          _getCategoryIcon(landmark.category),
          color: color,
          size: 20,
        ),
      ),
      title: Text(landmark.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        landmark.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (landmark.floor != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                landmark.floor!,
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.directions, size: 20),
        ],
      ),
      onTap: () {
        setState(() => _isSearching = false);
        _searchController.clear();
        _navigateToLandmark(landmark);
      },
    );
  }

  Widget _buildCategoryChips(ThemeData theme, ColorScheme colorScheme, double Function(double) r) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 0,
      right: 0,
      child: SafeArea(
        child: SizedBox(
          height: r(40),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: r(16)),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = category == _selectedCategory;
              final chipColor = _getCategoryColor(category);
              return Padding(
                padding: EdgeInsets.only(right: r(8)),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) => _onCategorySelected(category),
                  selectedColor: chipColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : colorScheme.onSurface,
                    fontSize: 12,
                  ),
                  backgroundColor: colorScheme.surface,
                  checkmarkColor: Colors.white,
                  side: isSelected ? BorderSide.none : BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPanel(ThemeData theme, ColorScheme colorScheme, double Function(double) r) {
    return DraggableScrollableSheet(
      initialChildSize: 0.12,
      minChildSize: 0.08,
      maxChildSize: 0.5,
      snapSizes: const [0.12, 0.35, 0.6],
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.all(r(20)),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: r(16)),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.school,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  SizedBox(width: r(16)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TCGC Campus',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: r(4)),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _lastKnownPosition != null ? Colors.green : Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: r(8)),
                            Text(
                              _lastKnownPosition != null ? 'GPS Active' : 'Finding GPS...',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _lastKnownPosition != null ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: r(16)),
              const Divider(),
              SizedBox(height: r(8)),
              _buildQuickActionTile(
                icon: Icons.layers,
                title: 'Switch to Indoor',
                subtitle: 'View floor plans',
                color: Colors.blue,
                onTap: () => _showIndoorComingSoon(),
                r: r,
              ),
              _buildQuickActionTile(
                icon: Icons.edit_location_alt,
                title: 'Record Landmark',
                subtitle: 'Save current GPS spot',
                color: Colors.orange,
                onTap: () => Navigator.pushNamed(context, '/record'),
                r: r,
              ),
              _buildQuickActionTile(
                icon: Icons.share,
                title: 'Share Location',
                subtitle: 'Share your current spot',
                color: Colors.green,
                onTap: () => _shareLocation(),
                r: r,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavigationStatusBar(ThemeData theme, ColorScheme colorScheme) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.navigation, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Navigating to: ${_activeDest?.name ?? ""}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_liveDistance != null)
                    Text(
                      '${DirectionsService.formatDistance(_liveDistance!)} · ${DirectionsService.formatWalkingTime(_liveDistance!)} walk',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: _stopNavigation,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Stop', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _showIndoorComingSoon() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Indoor Maps'),
        content: const Text(
          'Indoor floor plan navigation is coming in a future update. For now, use the landmark markers to locate rooms and offices.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareLocation() async {
    if (_lastKnownPosition != null) {
      final lat = _lastKnownPosition!.latitude;
      final lng = _lastKnownPosition!.longitude;
      await Share.share(
        'I\'m at TCGC campus: https://maps.google.com/?q=$lat,$lng',
        subject: 'My location at TCGC',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS not available yet'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required double Function(double) r,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: r(44),
        height: r(44),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.outline,
      ),
      onTap: onTap,
    );
  }
}