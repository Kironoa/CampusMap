import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:naviapp/data/campus_landmarks.dart';
import 'package:naviapp/config/env.dart';
import 'package:naviapp/services/directions_service.dart';
import 'package:naviapp/utils/ui_utils.dart' as ui;

class NavigationScreen extends StatefulWidget {
  final String? initialSearch;
  final bool autoNavigate;
  
  const NavigationScreen({super.key, this.initialSearch, this.autoNavigate = false});

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
  List<LatLng> _routePoints = [];
  Set<Polyline> _polylines = {};
  CampusLandmark? _selectedLandmark;
  final TextEditingController _searchController = TextEditingController();
  final Connectivity _connectivity = Connectivity();
  List<CampusLandmark> _filteredLandmarks = tcgcLandmarks;

  final List<String> _categories = ['All', 'Buildings', 'Offices', 'Labs', 'Facilities'];

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
    _initConnectivity();
    if (widget.initialSearch != null) {
      _searchController.text = widget.initialSearch!;
      _isSearching = true;
      _updateSearchResults();
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _connectivitySubscription?.cancel();
    _searchController.dispose();
    super.dispose();
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
      }
    });
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

  Future<void> _navigateToLandmark(CampusLandmark landmark) async {
    if (_lastKnownPosition == null) return;
    
    setState(() {
      _selectedLandmark = landmark;
      _routePoints = [];
      _polylines = {};
    });

    final routePoints = await DirectionsService.getRoute(
      _lastKnownPosition!,
      landmark.position,
      Env.mapsApiKey,
    );

    if (routePoints.isNotEmpty) {
      setState(() {
        _routePoints = routePoints;
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: routePoints,
            color: const Color(0xFF2563EB),
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
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.location_on, color: Color(0xFF2563EB)),
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
            if (_lastKnownPosition != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.directions_walk, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    DirectionsService.formatDistance(
                      DirectionsService.calculateDistance(_lastKnownPosition!, landmark.position),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Icon(Icons.schedule, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    DirectionsService.formatWalkingTime(
                      DirectionsService.calculateDistance(_lastKnownPosition!, landmark.position),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text("START NAVIGATION"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BitmapDescriptor _getMarkerHue(String category) {
    final categoryLower = category.toLowerCase();
    final hue = switch (categoryLower) {
      'buildings' => BitmapDescriptor.hueBlue,
      'offices' => BitmapDescriptor.hueOrange,
      'labs' => BitmapDescriptor.hueViolet,
      'facilities' => BitmapDescriptor.hueCyan,
      'restroom' => BitmapDescriptor.hueYellow,
      _ => BitmapDescriptor.hueAzure,
    };
    return BitmapDescriptor.defaultMarkerWithHue(hue);
  }

  Set<Marker> _buildMarkers() {
    return _filteredLandmarks.map((landmark) => Marker(
      markerId: MarkerId(landmark.id),
      position: landmark.position,
      icon: _getMarkerHue(landmark.category),
      infoWindow: InfoWindow(
        title: landmark.name,
        snippet: landmark.floor ?? landmark.description,
      ),
      onTap: () => _navigateToLandmark(landmark),
    )).toSet();
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
            mapType: MapType.hybrid,
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
            bottom: 180,
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
              padding: EdgeInsets.symmetric(horizontal: r(16), vertical: r(12)),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, r(4)),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: r(8)),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search TCGC campus...',
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
                constraints: BoxConstraints(maxHeight: r(200)),
                padding: EdgeInsets.all(r(12)),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
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
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          _getCategoryIcon(landmark.category),
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(landmark.name),
      subtitle: Text(landmark.floor ?? landmark.category),
      trailing: const Icon(Icons.directions),
      onTap: () {
        setState(() => _isSearching = false);
        _searchController.clear();
        _navigateToLandmark(landmark);
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    final categoryLower = category.toLowerCase();
    return switch (categoryLower) {
      'buildings' => Icons.business,
      'offices' => Icons.meeting_room,
      'labs' => Icons.computer,
      'facilities' => Icons.local_activity,
      'restroom' => Icons.wc,
      _ => Icons.place,
    };
  }

  Widget _buildCategoryChips(ThemeData theme, ColorScheme colorScheme, double Function(double) r) {
    return Positioned(
      top: 100,
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
              return Padding(
                padding: EdgeInsets.only(right: r(8)),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) => _onCategorySelected(category),
                  selectedColor: colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : colorScheme.onSurface,
                    fontSize: 12,
                  ),
                  backgroundColor: colorScheme.surface,
                  checkmarkColor: Colors.white,
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
      initialChildSize: 0.15,
      minChildSize: 0.1,
      maxChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
                    color: colorScheme.outline.withOpacity(0.3),
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
                                color: _lastKnownPosition != null 
                                    ? Colors.green 
                                    : Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: r(8)),
                            Text(
                              _lastKnownPosition != null 
                                  ? 'GPS Active' 
                                  : 'Finding GPS...',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _lastKnownPosition != null 
                                    ? Colors.green 
                                    : Colors.orange,
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
                onTap: () {},
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
                onTap: () {},
                r: r,
              ),
            ],
          ),
        );
      },
    );
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
          color: color.withOpacity(0.1),
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