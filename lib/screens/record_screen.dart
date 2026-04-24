import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:convert'; // For JSON export

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final List<Map<String, dynamic>> _capturedPoints = [];
  final TextEditingController _nameController = TextEditingController();
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;

  static const LatLng _tcgcCenter = LatLng(8.0645, 123.7508);

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
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
            distanceFilter: 1, // Update every 1 meter to reduce jitter
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

  // Exports data as a JSON string for easy DB integration
  void _copyAsJson() {
    if (_capturedPoints.isEmpty) return;
    String jsonString = jsonEncode(_capturedPoints);
    Clipboard.setData(ClipboardData(text: jsonString)).then((_) {
      _showToast("Points copied as JSON!", Colors.blue);
    });
  }

  void _copyToClipboard() {
    if (_capturedPoints.isEmpty) return;

    String buffer = "// TCGC MARKER DATA\n";
    for (var point in _capturedPoints) {
      buffer +=
          "Marker(markerId: MarkerId('${point['name']}'), "
          "position: LatLng(${point['lat']}, ${point['lng']})),\n";
    }

    Clipboard.setData(ClipboardData(text: buffer)).then((_) {
      _showToast("Marker code copied!", Colors.green);
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

  void _savePoint() {
    if (_currentPosition == null) {
      _showToast("Waiting for GPS...", Colors.orange);
      return;
    }

    // Haptic feedback so you know it clicked while walking
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Name this Spot"),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(hintText: "Registrar, Lab 1, etc."),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _capturedPoints.add({
                  'name': _nameController.text.trim().isEmpty
                      ? "Point ${_capturedPoints.length + 1}"
                      : _nameController.text.trim(),
                  'lat': _currentPosition!.latitude,
                  'lng': _currentPosition!.longitude,
                  'timestamp': DateTime.now().toIso8601String(),
                });
              });
              _nameController.clear();
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Campus Mapper"),
        actions: [
          if (_capturedPoints.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.code),
              onPressed: _copyAsJson,
              tooltip: "Copy JSON",
            ),
            IconButton(
              icon: const Icon(Icons.copy_all),
              onPressed: _copyToClipboard,
              tooltip: "Copy Code",
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              onPressed: () => setState(() => _capturedPoints.clear()),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          _buildMapHeader(),
          _buildStatusIndicator(),
          Expanded(
            child: _capturedPoints.isEmpty
                ? _buildEmptyState()
                : _buildPointsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _savePoint,
        label: const Text("Record Spot"),
        icon: const Icon(Icons.add_location_alt),
      ),
    );
  }

  Widget _buildMapHeader() {
    return SizedBox(
      height: 220,
      child: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: _tcgcCenter,
          zoom: 18,
        ),
        onMapCreated: (controller) => _mapController = controller,
        myLocationEnabled: true,
        mapType: MapType.hybrid,
        markers: _capturedPoints
            .map(
              (p) => Marker(
                markerId: MarkerId(p['name']),
                position: LatLng(p['lat'], p['lng']),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueCyan,
                ),
              ),
            )
            .toSet(),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.blueGrey[900],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _currentPosition == null ? "🛰️ SEARCHING..." : "🛰️ GPS READY",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          if (_currentPosition != null)
            Text(
              "Accuracy: ${_currentPosition!.accuracy.toStringAsFixed(1)}m",
              style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildPointsList() {
    return ListView.separated(
      itemCount: _capturedPoints.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final point = _capturedPoints[index];
        return ListTile(
          leading: CircleAvatar(child: Text("${index + 1}")),
          title: Text(
            point['name'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text("${point['lat']}, ${point['lng']}"),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => setState(() => _capturedPoints.removeAt(index)),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        "No points recorded yet.\nWalk around TCGC and tap 'Record Spot'.",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}
