import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:naviapp/data/saved_spot.dart';
import 'package:naviapp/services/saved_spot_storage.dart';
import 'dart:async';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final List<SavedSpot> _savedSpots = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;
  bool _isLoading = true;
  bool _locationFailed = false;
  bool _showManualEntry = false;
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _loadSpots();
    _startLocationTracking();
  }

  Future<void> _loadSpots() async {
    final spots = await SavedSpotStorage.loadSpots();
    if (!mounted) return;
    setState(() {
      _savedSpots.clear();
      _savedSpots.addAll(spots);
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _positionStream?.cancel();
    _nameController.dispose();
    _descriptionController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _startLocationTracking() {
    _searchTimer = Timer(const Duration(seconds: 10), () {
      if (_currentPosition == null && mounted) {
        setState(() {
          _locationFailed = true;
        });
      }
    });

    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 1,
          ),
        ).listen((Position position) {
          if (!mounted) return;
          setState(() {
            _currentPosition = position;
            _locationFailed = false;
          });
          _mapController.move(
            LatLng(position.latitude, position.longitude),
            18.0,
          );
        });
  }

  void _showToast(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveCurrentLocation() async {
    if (!mounted) return;
    
    double? lat;
    double? lng;

    if (_showManualEntry) {
      if (_latController.text.isEmpty || _lngController.text.isEmpty) {
        _showToast("Please enter coordinates", Colors.orange);
        return;
      }
      lat = double.tryParse(_latController.text);
      lng = double.tryParse(_lngController.text);
      if (lat == null || lng == null) {
        _showToast("Invalid coordinates", Colors.red);
        return;
      }
    } else {
      if (_currentPosition == null) {
        _showToast("Waiting for GPS...", Colors.orange);
        return;
      }
      lat = _currentPosition!.latitude;
      lng = _currentPosition!.longitude;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showToast("Please enter a name", Colors.orange);
      return;
    }

    HapticFeedback.heavyImpact();

    final spot = SavedSpot(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      latitude: lat,
      longitude: lng,
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
    );

    await SavedSpotStorage.addSpot(spot);
    if (!mounted) return;
    await _loadSpots();

    _nameController.clear();
    _descriptionController.clear();
    _latController.clear();
    _lngController.clear();
    setState(() {
      _showManualEntry = false;
    });
    _showToast("Spot saved!", Colors.green);
  }

  Future<void> _deleteSpot(String id) async {
    await SavedSpotStorage.removeSpotById(id);
    if (!mounted) return;
    await _loadSpots();
    _showToast("Spot removed", Colors.red);
  }

  void _openLocationSettings() {
    Geolocator.openLocationSettings();
  }

  void _showDeleteDialog(String id, String name) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Spot'),
        content: Text('Delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSpot(id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
      appBar: AppBar(
        title: const Text("Personal Saved Spots"),
      ),
      body: Column(
        children: [
          _buildInputSection(colorScheme),
          _buildStatusIndicator(theme, colorScheme),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _savedSpots.isEmpty
                    ? _buildEmptyState(theme, colorScheme)
                    : _buildSpotsList(theme, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: "Enter spot name",
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _saveCurrentLocation(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _saveCurrentLocation,
                icon: const Icon(Icons.add_location_alt),
                label: const Text("Save"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              hintText: "Enter description (optional)",
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(10),
      color: colorScheme.inverseSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _locationFailed ? "GPS UNAVAILABLE" : (_currentPosition == null ? "SEARCHING..." : "GPS READY"),
                style: TextStyle(
                  color: colorScheme.onInverseSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              if (_currentPosition != null)
                Text(
                  "Accuracy: ${_currentPosition!.accuracy.toStringAsFixed(1)}m",
                  style: TextStyle(color: Colors.greenAccent.shade700, fontSize: 12),
                ),
            ],
          ),
          if (_locationFailed) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openLocationSettings,
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text("Enable Location", style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showManualEntry = true;
                      });
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text("Manual", style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_showManualEntry) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latController,
                    decoration: InputDecoration(
                      hintText: "Latitude",
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _lngController,
                    decoration: InputDecoration(
                      hintText: "Longitude",
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 72,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No personal spots saved',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a name and tap "Save"\nto save your current location.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpotsList(ThemeData theme, ColorScheme colorScheme) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentPosition != null 
                ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                : const LatLng(8.0645, 123.7510),
            initialZoom: 16.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.naviapp',
            ),
            MarkerLayer(
              markers: _savedSpots.map((spot) {
                return Marker(
                  point: spot.position,
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _showToast(spot.name, Colors.blue),
                    onLongPress: () => _showDeleteDialog(spot.id, spot.name),
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
                  ),
                );
              }).toList(),
            ),
            if (_currentPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    width: 30,
                    height: 30,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.small(
            onPressed: () {
              if (_currentPosition != null) {
                _mapController.move(
                  LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                  18.0,
                );
              }
            },
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}