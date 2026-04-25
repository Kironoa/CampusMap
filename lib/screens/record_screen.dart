import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSpots();
    _startLocationTracking();
  }

  Future<void> _loadSpots() async {
    final spots = await SavedSpotStorage.loadSpots();
    if (mounted) {
      setState(() {
        _savedSpots.clear();
        _savedSpots.addAll(spots);
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  void _startLocationTracking() {
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 1,
          ),
        ).listen((Position position) {
          if (mounted) {
            setState(() => _currentPosition = position);
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(position.latitude, position.longitude),
              ),
            );
          }
        });
  }

  void _showToast(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveCurrentLocation() async {
    if (_currentPosition == null) {
      _showToast("Waiting for GPS...", Colors.orange);
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showToast("Please enter a name", Colors.orange);
      return;
    }

    HapticFeedback.heavyImpact();

    final spot = SavedSpot(
      name: name,
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
    );

    await SavedSpotStorage.addSpot(spot);
    await _loadSpots();

    _nameController.clear();
    _showToast("Spot saved!", Colors.green);
  }

  Future<void> _deleteSpot(int index) async {
    await SavedSpotStorage.removeSpot(index);
    await _loadSpots();
    _showToast("Spot removed", Colors.red);
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
      child: Row(
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
    );
  }

  Widget _buildStatusIndicator(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(10),
      color: colorScheme.inverseSurface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _currentPosition == null ? "SEARCHING..." : "GPS READY",
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
    return ListView.separated(
      itemCount: _savedSpots.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final spot = _savedSpots[index];

        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.orange,
            child: Icon(
              Icons.bookmark,
              color: Colors.white,
              size: 20,
            ),
          ),
          title: Text(
            spot.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            "${spot.latitude.toStringAsFixed(5)}, ${spot.longitude.toStringAsFixed(5)}",
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
            onPressed: () => _deleteSpot(index),
          ),
        );
      },
    );
  }
}