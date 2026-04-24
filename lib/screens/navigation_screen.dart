import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStream;
  static const LatLng _tcgcCenter = LatLng(8.0645, 123.7508);
  LatLng? _lastKnownPosition;
  bool _followUser = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _searchController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
          ),
          _buildSearchOverlay(theme, colorScheme),
          Positioned(
            right: 16,
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
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoomOut',
                  backgroundColor: colorScheme.surface,
                  onPressed: () => _mapController?.animateCamera(
                    CameraUpdate.zoomOut(),
                  ),
                  child: Icon(Icons.remove, color: colorScheme.primary),
                ),
                const SizedBox(height: 16),
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
          _buildInfoPanel(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildSearchOverlay(ThemeData theme, ColorScheme colorScheme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search TCGC campus...',
                        border: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (value) {
                        setState(() => _isSearching = true);
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      setState(() => _isSearching = true);
                    },
                  ),
                ],
              ),
            ),
            if (_isSearching) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchResult('Main Building', '2nd Floor'),
                    _buildSearchResult('Deans Office', '2nd Floor'),
                    _buildSearchResult('Computer Lab', '2nd Floor'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResult(String title, String subtitle) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.location_on,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.directions),
      onTap: () {
        setState(() => _isSearching = false);
        _searchController.clear();
      },
    );
  }

  Set<Marker> _buildMarkers() {
    return {
      const Marker(
        markerId: MarkerId('main_building'),
        position: LatLng(8.064562, 123.751025),
        infoWindow: InfoWindow(title: 'TCGC Main Building'),
      ),
      const Marker(
        markerId: MarkerId('canteen'),
        position: LatLng(8.0643, 123.7505),
        infoWindow: InfoWindow(title: 'Campus Canteen'),
      ),
    };
  }

  Widget _buildInfoPanel(ThemeData theme, ColorScheme colorScheme) {
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
            padding: const EdgeInsets.all(20),
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
              const SizedBox(height: 16),
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
                  const SizedBox(width: 16),
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
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'GPS Active',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green,
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
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildQuickActionTile(
                icon: Icons.layers,
                title: 'Switch to Indoor',
                subtitle: 'View floor plans',
                color: Colors.blue,
                onTap: () => Navigator.popUntil(context, ModalRoute.withName('/dashboard')),
              ),
              _buildQuickActionTile(
                icon: Icons.edit_location_alt,
                title: 'Record Landmark',
                subtitle: 'Save current GPS spot',
                color: Colors.orange,
                onTap: () => Navigator.pushNamed(context, '/record'),
              ),
              _buildQuickActionTile(
                icon: Icons.share,
                title: 'Share Location',
                subtitle: 'Share your current spot',
                color: Colors.green,
                onTap: () {},
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
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
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