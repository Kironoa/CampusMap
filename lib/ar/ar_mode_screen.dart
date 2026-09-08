// lib/ar/ar_mode_screen.dart
import 'dart:async';

import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../services/room_catalog.dart';
import 'ar_config.dart';

class ArModeScreen extends StatefulWidget {
  const ArModeScreen({super.key});

  @override
  State<ArModeScreen> createState() => _ArModeScreenState();
}

class _ArModeScreenState extends State<ArModeScreen> {
  ARSessionManager? _sessionManager;

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

    sessionManager.onInitialize(
      showAnimatedGuide: false,
      showFeaturePoints: false,
      showPlanes: true,
      showWorldOrigin: false,
      handleTaps: true,
    );

    sessionManager.onError = (error) {
      if (!mounted) return;
      final e = error.toLowerCase();
      final isFatal =
          e.contains('arcore') ||
          e.contains('ar core') ||
          e.contains('session') ||
          e.contains('unsupported') ||
          e.contains('camera');
      if (isFatal) {
        setState(() => _arSessionError = error);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('AR error: $error')));
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

  void _startCameraPosePolling() {
    _cameraPoseTimer = Timer.periodic(ArConfig.cameraPoseInterval, (_) async {
      if (!mounted || _sessionManager == null) return;
      final pose = await _sessionManager!.getCameraPose();
      if (pose == null || !mounted) return;
      _updateNearbyRoom(pose.getTranslation());
    });
  }

  void _updateNearbyRoom(Vector3 cameraPosition) {
    if (_placedNodes.isEmpty) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1711),
      appBar: AppBar(
        title: const Text(
          'AR Navigation',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
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
                    planeDetectionConfig:
                        PlaneDetectionConfig.horizontalAndVertical,
                  )
                : _buildCameraGate(),
          ),
          if (_cameraGranted && _arSessionError != null) _buildArErrorOverlay(),
          if (_cameraGranted)
            _buildEmptyOverlay(),
          if (_cameraGranted && _nearbyRoomName != null) _buildNearbyRoomChip(),
        ],
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
                _cameraUnknown ? Icons.hourglass_top : Icons.no_photography,
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
            Icon(Icons.view_in_ar, size: 96, color: Color(0xFFA8C8B0)),
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
              'AR navigation is available from the map screen.',
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

  }