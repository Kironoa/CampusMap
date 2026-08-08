// lib/ar/ar_mode_screen.dart
import 'dart:async';

import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../services/room_catalog.dart';
import '../widgets/ai_nav_sheet.dart';
import 'ar_config.dart';
import 'models/ar_route_data.dart';
import 'services/ar_anchor_mapper.dart';
import 'services/ar_calibration_service.dart';
import 'widgets/ar_nodes.dart';

class ArModeScreen extends StatefulWidget {
  const ArModeScreen({super.key});

  @override
  State<ArModeScreen> createState() => _ArModeScreenState();
}

class _ArModeScreenState extends State<ArModeScreen> {
  ARSessionManager? _sessionManager;
  ARObjectManager? _objectManager;

  ArRouteData? _route;
  ArCalibrationService? _calibration;
  ArAnchorMapper? _mapper;

  final List<ARNode> _placedNodes = [];
  Timer? _cameraPoseTimer;

  String? _nearbyRoomName;
  double? _nearbyRoomDistance;

  bool _cameraGranted = false;
  bool _cameraUnknown = true;
  bool _cameraPermanentlyDenied = false;
  String? _arSessionError;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
    _startCameraPosePolling();
  }

  @override
  void dispose() {
    _cameraPoseTimer?.cancel();
    _sessionManager?.dispose();
    super.dispose();
  }

  void _onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    _sessionManager = sessionManager;
    _objectManager = objectManager;

    sessionManager.onInitialize(
      showAnimatedGuide: false,
      showFeaturePoints: false,
      showPlanes: true,
      showWorldOrigin: false,
      handleTaps: true,
    );

    sessionManager.onPlaneOrPointTap = _onPlaneOrPointTap;
    objectManager.onNodeTap = (nodes) => _onNodeTap(nodes);
    sessionManager.onError = (error) {
      if (!mounted) return;
      final e = error.toLowerCase();
      final isFatal = e.contains('arcore') ||
          e.contains('ar core') ||
          e.contains('session') ||
          e.contains('unsupported') ||
          e.contains('camera');
      if (isFatal) {
        setState(() => _arSessionError = error);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AR error: $error')),
        );
      }
    };
  }

  Future<void> _requestCameraPermission() async {
    if (mounted) {
      setState(() {
        _cameraUnknown = true;
        _cameraPermanentlyDenied = false;
      });
    }
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    if (!mounted) return;
    setState(() {
      _cameraGranted = status.isGranted;
      _cameraUnknown = false;
      _cameraPermanentlyDenied = status.isPermanentlyDenied;
    });
  }

  void _retryArSession() {
    setState(() => _arSessionError = null);
    _sessionManager?.onInitialize(
      showAnimatedGuide: false,
      showFeaturePoints: false,
      showPlanes: true,
      showWorldOrigin: false,
      handleTaps: true,
    );
  }

  Future<void> _onPlaneOrPointTap(List<ARHitTestResult> hits) async {
    if (_route == null || !_route!.hasRoute) return;
    if (_calibration!.isCalibrated) return;
    if (hits.isEmpty) return;

    final worldPosition = hits.first.worldTransform.getTranslation();
    await _calibrateAndPlace(worldPosition);
  }

  Future<void> _calibrateAndPlace(Vector3 worldPosition) async {
    final route = _route!;
    _calibration!.calibrate(worldPosition, route.path.first);
    await _placeRouteElements();
  }

  Future<void> _placeRouteElements() async {
    if (_objectManager == null || _route == null) return;
    await _removePlacedNodes();

    final route = _route!;
    final mapper = _mapper!;

    final arrowPoints = mapper.buildArrowPoints(route.path);
    final destinationPoint = mapper.buildDestinationPoint(route.path);

    final floorKey = RoomCatalog.floorKeys[route.floorIndex];
    final rooms = RoomCatalog.allRooms[floorKey] ?? const [];
    final roomPoints = mapper.buildRoomMarkerPoints(route.path, rooms);

    final nodes = <ARNode>[
      ...arrowPoints.map(ArNodes.arrow),
      if (destinationPoint != null) ArNodes.destination(destinationPoint),
      ...roomPoints.map(ArNodes.roomMarker),
    ];

    for (final node in nodes) {
      final added = await _objectManager!.addNode(node);
      if (added == true) {
        _placedNodes.add(node);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Calibrated — ${_placedNodes.length} of ${nodes.length} elements placed. Follow the arrows.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      setState(() {});
    }
  }

  Future<void> _removePlacedNodes() async {
    for (final node in _placedNodes) {
      _objectManager?.removeNode(node);
    }
    _placedNodes.clear();
  }

  void _onNodeTap(List<String> nodeNames) {
    if (nodeNames.isEmpty) return;
    final name = nodeNames.first;
    if (!name.startsWith('room_')) return;
    final roomId = name.substring('room_'.length);
    final roomName = RoomCatalog.roomNameById(roomId);
    if (roomName == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Room: $roomName'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _startCameraPosePolling() {
    _cameraPoseTimer = Timer.periodic(ArConfig.cameraPoseInterval, (_) async {
      if (!mounted || _sessionManager == null) return;
      final pose = await _sessionManager!.getCameraPose();
      if (pose == null || !mounted) return;
      _updateNearbyRoom(pose.getTranslation());
    });
  }

  void _updateNearbyRoom(Vector3 cameraPosition) {
    if (_route == null || _placedNodes.isEmpty) {
      _setNearbyRoom(null, null);
      return;
    }

    String? nearestId;
    var nearestDistance = double.infinity;
    for (final node in _placedNodes) {
      final roomId = node.data?['roomId'] as String?;
      if (roomId == null) continue;
      final dist = (node.position - cameraPosition).length;
      if (dist < nearestDistance) {
        nearestDistance = dist;
        nearestId = roomId;
      }
    }

    if (nearestId == null || nearestDistance > ArConfig.roomLabelRadius) {
      _setNearbyRoom(null, null);
    } else {
      _setNearbyRoom(RoomCatalog.roomNameById(nearestId), nearestDistance);
    }
  }

  void _setNearbyRoom(String? name, double? distance) {
    if (_nearbyRoomName == name && _nearbyRoomDistance == distance) return;
    if (!mounted) return;
    setState(() {
      _nearbyRoomName = name;
      _nearbyRoomDistance = distance;
    });
  }

  Future<void> _pickDestination() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AINavSheet(
        currentFloorIndex: 0,
        onNavigationResult: (pathOffsets, floorIndex, roomId) {
          if (!mounted) return;
          final route = ArRouteData(
            path: pathOffsets,
            floorIndex: floorIndex,
            roomId: roomId,
          );
          setState(() {
            _route = route;
            _nearbyRoomName = null;
            _nearbyRoomDistance = null;
          });
          _calibration?.reset();
          _removePlacedNodes();
          _setupForRoute(route);
        },
      ),
    );
  }

  void _setupForRoute(ArRouteData route) {
    _calibration = ArCalibrationService(route.floorIndex);
    _mapper = ArAnchorMapper(
      floorIndex: route.floorIndex,
      calibration: _calibration!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1711),
      appBar: AppBar(
        title: const Text(
          'AR Navigation',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0A7040),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _cameraGranted
                ? ARView(
                    onARViewCreated: _onARViewCreated,
                    planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
                  )
                : _buildCameraGate(),
          ),
          if (_cameraGranted && _arSessionError != null) _buildArErrorOverlay(),
          if (_cameraGranted && (_route == null || !_route!.hasRoute))
            _buildEmptyOverlay()
          else if (_cameraGranted &&
              !(_calibration?.isCalibrated ?? false))
            _buildCalibrationOverlay()
          else if (_cameraGranted)
            _buildLiveOverlay(),
          if (_cameraGranted && _nearbyRoomName != null) _buildNearbyRoomChip(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickDestination,
        icon: const Icon(Icons.travel_explore),
        label: Text(
          _route == null ? 'Choose Destination' : 'Change Destination',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF16A34A),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildCameraGate() {
    return Container(
      color: const Color(0xFF0D1711),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _cameraUnknown
                    ? Icons.hourglass_top
                    : Icons.no_photography,
                size: 64,
                color: const Color(0xFFA8C8B0),
              ),
              const SizedBox(height: 16),
              const Text(
                'Camera access',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _cameraUnknown
                    ? 'Requesting camera permission…'
                    : _cameraPermanentlyDenied
                        ? 'Camera permission was permanently denied. '
                            'Enable it in Settings to use AR navigation.'
                        : 'Camera permission is required for AR navigation. '
                            'It is only used to show the live camera view.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_cameraUnknown)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF16A34A),
                      ),
                    )
                  else ...[
                    if (!_cameraPermanentlyDenied)
                      TextButton(
                        onPressed: _requestCameraPermission,
                        child: const Text('Try Again'),
                      ),
                    const TextButton(
                      onPressed: openAppSettings,
                      child: Text('Open Settings'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArErrorOverlay() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xCC5B1711),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF7A2B2B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error_outline, color: Color(0xFFF87171)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AR session could not start',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _arSessionError!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _retryArSession,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyOverlay() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.view_in_ar,
              size: 96,
              color: Color(0xFFA8C8B0),
            ),
            SizedBox(height: 24),
            Text(
              'Augmented Reality Mode',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Pick a destination to see 3D arrows guiding you through the campus in AR.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalibrationOverlay() {
    final route = _route!;
    return Column(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xCC0D1711),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2B4A36)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.touch_app, color: Color(0xFF16A34A)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tap the floor where you are standing',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Aiming for ${route.roomName ?? route.roomId ?? 'the destination'} · ${_floorName(route.floorIndex)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveOverlay() {
    final route = _route!;
    return Column(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xCC0D1711),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2B4A36)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.directions_walk,
                  color: Color(0xFF16A34A),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Follow the arrows · ${_floorName(route.floorIndex)} · ~${route.estimatedDistanceMeters.toStringAsFixed(0)} m',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyRoomChip() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xEE16A34A),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.near_me, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Nearby: $_nearbyRoomName (${_nearbyRoomDistance!.toStringAsFixed(1)} m)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _floorName(int index) {
    const names = ['Ground Floor', '2nd Floor', '3rd Floor'];
    return index >= 0 && index < names.length ? names[index] : 'Floor';
  }
}
