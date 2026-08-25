// lib/screens/floor_plan_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naviapp/services/indoor_positioning/indoor_position.dart';
import 'package:naviapp/services/indoor_positioning/indoor_position_provider.dart';
import 'package:naviapp/services/navigation_graph.dart';
import 'package:naviapp/services/pathfinder.dart';
import 'package:naviapp/services/route_calculator.dart';
import 'package:naviapp/widgets/ai_nav_sheet.dart';

class FloorPlanScreen extends StatefulWidget {
  final int initialFloor;
  final IndoorPositionProvider? positionProvider;
  const FloorPlanScreen({
    super.key,
    this.initialFloor = 0,
    this.positionProvider,
  });

  @override
  State<FloorPlanScreen> createState() => _FloorPlanScreenState();
}

class _FloorPlanScreenState extends State<FloorPlanScreen>
    with TickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late int _currentFloor;
  late AnimationController _pathAnimationController;
  late Animation<double> _pathAnimation;
  List<Offset> _navigationPath = [];
  bool _isNavigating = false;
  List<int> _pathFloorIndices = [];

  // Track if user manually selected a floor
  bool _userSelectedFloor = false;

  // Indoor positioning
  IndoorPositionProvider? _positionProvider;
  StreamSubscription<IndoorPosition>? _positionSubscription;
  IndoorPosition? _currentPosition;

  static const List<String> _floorNames = ['Ground', '2nd Floor', '3rd Floor'];
  static const List<String> _floorImagePaths = [
    'assets/images/ground_floor.png',
    'assets/images/second_floor.png',
    'assets/images/third_floor.png',
  ];

  Size _getFloorImageSize(int floor) {
    switch (floor) {
      case 0:
        return const Size(1485, 704);
      case 1:
        return const Size(1464, 720);
      default:
        return const Size(1600, 671);
    }
  }

  String get _currentFloorName => _floorNames[_currentFloor];
  String get _currentFloorImage => _floorImagePaths[_currentFloor];

  @override
  void initState() {
    super.initState();
    _currentFloor = widget.initialFloor;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _pathAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _pathAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pathAnimationController, curve: Curves.easeOutCubic),
    );
    _pathAnimationController.addListener(() {
      setState(() {});
    });
    _initPositioning();
  }

  void _initPositioning() {
    _positionProvider = widget.positionProvider ?? createPositionProvider();
    _positionSubscription = _positionProvider!.positions.listen(
      _onIndoorPosition,
      onError: (Object error) {
        if (!mounted) return;
        debugPrint('Indoor positioning error: $error');
      },
    );
    _positionProvider!.start();
  }

  void _onIndoorPosition(IndoorPosition position) {
    if (!mounted) return;
    setState(() {
      _currentPosition = position;
      // Auto-switch floor only if user hasn't manually selected a floor
      if (!_userSelectedFloor && position.floor != _currentFloor) {
        _currentFloor = position.floor;
      }
    });
  }

  void navigateTo(String roomId) {
    final destinationFloor = _findFloorForRoom(roomId);

    if (_currentPosition != null && _currentPosition!.floor == destinationFloor) {
      // Same floor with live position
      _navigateSameFloor(roomId, destinationFloor);
    } else if (_currentPosition != null) {
      // Cross-floor with live position
      _navigateCrossFloor(roomId, destinationFloor);
    } else {
      // No live position - use default start node
      _navigateDefault(roomId);
    }
  }

  int _findFloorForRoom(String roomId) {
    final mappedNodeId = NavigationGraph.roomToNode[roomId];
    if (mappedNodeId != null) {
      for (int f = 0; f < 3; f++) {
        final nodes = NavigationGraph.nodesForFloor(f);
        if (nodes.any((n) => n.id == mappedNodeId)) {
          return f;
        }
      }
    }
    return _currentFloor;
  }

  void _navigateSameFloor(String roomId, int floor) {
    final floorIndex = floor;
    final nodes = NavigationGraph.getNodes(floorIndex);
    final edges = NavigationGraph.getEdges(floorIndex);

    final startNodeId = _currentPosition != null
        ? Pathfinder.findNearestNodeToPosition(
            Offset(_currentPosition!.x, _currentPosition!.y),
            floorIndex,
          )
        : NavigationGraph.getDefaultStartNode(floorIndex) ?? nodes.first.id;

    final endNodeId = Pathfinder.findNearestNodeToRoom(roomId, floorIndex);

    final pathPoints = Pathfinder.findPath(
      startNodeId: startNodeId,
      endNodeId: endNodeId,
      nodes: nodes,
      edges: edges,
    );

    if (pathPoints.isNotEmpty) {
      setState(() {
        _navigationPath = pathPoints;
        _pathFloorIndices = List.filled(pathPoints.length, floorIndex);
        _isNavigating = true;
      });
      _pathAnimationController.forward(from: 0);
    }
  }

  void _navigateCrossFloor(String roomId, int destinationFloor) {
    final pos = _currentPosition;
    if (pos == null) {
      _navigateDefault(roomId);
      return;
    }
    final result = RouteCalculator.fromLivePosition(
      position: pos,
      roomId: roomId,
      destinationFloor: destinationFloor,
    );
    if (result != null && result.hasPath) {
      setState(() {
        _navigationPath = result.path;
        _pathFloorIndices = result.floorIndices;
        _isNavigating = true;
      });
      _pathAnimationController.forward(from: 0);
      return;
    }
    _navigateDefault(roomId);
  }

  void _navigateDefault(String roomId) {
    final floorIndex = _currentFloor;
    final nodes = NavigationGraph.getNodes(floorIndex);
    final edges = NavigationGraph.getEdges(floorIndex);

    final startNodeId = NavigationGraph.getDefaultStartNode(floorIndex) ?? nodes.first.id;
    final endNodeId = Pathfinder.findNearestNodeToRoom(roomId, floorIndex);

    final pathPoints = Pathfinder.findPath(
      startNodeId: startNodeId,
      endNodeId: endNodeId,
      nodes: nodes,
      edges: edges,
    );

    if (pathPoints.isEmpty) {
      for (int floor = 0; floor < 3; floor++) {
        final altNodes = NavigationGraph.getNodes(floor);
        final altEdges = NavigationGraph.getEdges(floor);
        final altEndNodeId = Pathfinder.findNearestNodeToRoom(roomId, floor);
        final altPath = Pathfinder.findPath(
          startNodeId: NavigationGraph.getDefaultStartNode(floor) ?? altNodes.first.id,
          endNodeId: altEndNodeId,
          nodes: altNodes,
          edges: altEdges,
        );
        if (altPath.isNotEmpty) {
          setState(() {
            _currentFloor = floor;
            _navigationPath = altPath;
            _pathFloorIndices = List.filled(altPath.length, floor);
            _isNavigating = true;
          });
          _pathAnimationController.forward(from: 0);
          return;
        }
      }
      return;
    }

    setState(() {
      _navigationPath = pathPoints;
      _pathFloorIndices = List.filled(pathPoints.length, floorIndex);
      _isNavigating = pathPoints.isNotEmpty;
    });
    if (pathPoints.isNotEmpty) {
      _pathAnimationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _positionProvider?.stop();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _transformationController.dispose();
    _pathAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentFloorName,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0A7040),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final imageSize = _getFloorImageSize(_currentFloor);
          final scaleX = constraints.maxWidth / imageSize.width;
          final scaleY = constraints.maxHeight / imageSize.height;
          final scaleFactor = scaleX < scaleY ? scaleX : scaleY;
          final scaledWidth = imageSize.width * scaleFactor;
          final scaledHeight = imageSize.height * scaleFactor;
          
          return InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: SizedBox(
                width: scaledWidth,
                height: scaledHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        _currentFloorImage,
                        fit: BoxFit.fill,
                      ),
                    ),
                    CustomPaint(
                      size: Size(scaledWidth, scaledHeight),
                      painter: FloorPlanPainter(
                        isDark: Theme.of(context).brightness == Brightness.dark,
                        navigationPath: _navigationPath,
                        pathFloorIndices: _pathFloorIndices,
                        currentFloor: _currentFloor,
                        pathProgress: _pathAnimation.value,
                        isNavigating: _isNavigating,
                        imageOriginalSize: imageSize,
                        livePosition: _currentPosition,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentFloor,
        onDestinationSelected: (index) {
          setState(() {
            _currentFloor = index;
            _userSelectedFloor = true;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.stairs),
            label: 'Ground',
          ),
          NavigationDestination(
            icon: Icon(Icons.business),
            label: '2nd',
          ),
          NavigationDestination(
            icon: Icon(Icons.apartment),
            label: '3rd',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNavigation,
        icon: const Icon(Icons.navigation_outlined),
        label: const Text('Navigate', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF16A34A),
        foregroundColor: Colors.white,
      ),
    );
  }

  void _openNavigation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AINavSheet(
        currentFloorIndex: _currentFloor,
        livePosition: _currentPosition,
        onNavigationResult: (result) {
          setState(() {
            _currentFloor = result.floorIndex;
            if (result.hasPath) {
              _navigationPath = result.path;
              _pathFloorIndices = result.floorIndices;
              _isNavigating = true;
              _pathAnimationController.forward(from: 0);
            }
          });
        },
      ),
    );
  }
}

class FloorPlanPainter extends CustomPainter {
  final bool isDark;
  final List<Offset> navigationPath;
  final List<int> pathFloorIndices;
  final int currentFloor;
  final double pathProgress;
  final bool isNavigating;
  final Size imageOriginalSize;
  final IndoorPosition? livePosition;

  FloorPlanPainter({
    required this.isDark,
    this.navigationPath = const [],
    this.pathFloorIndices = const [],
    this.currentFloor = 0,
    this.pathProgress = 0,
    this.isNavigating = false,
    this.imageOriginalSize = const Size(1464, 720),
    this.livePosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final baseSize = imageOriginalSize.width;
    final height = imageOriginalSize.height;
    final scaleX = size.width / baseSize;
    final scaleY = size.height / height;
    final scaleFactor = scaleX < scaleY ? scaleX : scaleY;
    final scaledWidth = baseSize * scaleFactor;
    final scaledHeight = height * scaleFactor;
    final offsetX = (size.width - scaledWidth) / 2;
    final offsetY = (size.height - scaledHeight) / 2;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scaleFactor);

    if (isNavigating && navigationPath.isNotEmpty) {
      _drawNavigationPath(canvas, baseSize, height, scaleFactor);
    }

    if (livePosition != null && livePosition!.floor == currentFloor) {
      _drawLiveMarker(canvas, baseSize, height, scaleFactor);
    }

    canvas.restore();
  }

  void _drawLiveMarker(
    Canvas canvas,
    double baseSize,
    double height,
    double scaleFactor,
  ) {
    final pos = livePosition!;
    final x = pos.x * baseSize;
    final y = pos.y * height;
    final inv = 1.0 / scaleFactor;

    // Accuracy circle
    if (pos.accuracy < 20.0) {
      final accuracyPx = pos.accuracy * baseSize / 50.0;
      canvas.drawCircle(
        Offset(x, y),
        accuracyPx.clamp(8.0, 160.0),
        Paint()..color = const Color(0x332563EB),
      );
    }

    // Pulsing outer ring (using a simple static ring for now)
    canvas.drawCircle(
      Offset(x, y),
      11.0 * inv,
      Paint()
        ..color = const Color(0xAA3B82F6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * inv,
    );

    // White outer ring
    canvas.drawCircle(
      Offset(x, y),
      8.5 * inv,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * inv,
    );

    // Blue fill + white center dot
    canvas.drawCircle(
      Offset(x, y),
      6.5 * inv,
      Paint()..color = const Color(0xFF2563EB),
    );
    canvas.drawCircle(
      Offset(x, y),
      1.8 * inv,
      Paint()..color = Colors.white,
    );
  }

  void _drawNavigationPath(Canvas canvas, double baseSize, double height, double scaleFactor) {
    if (navigationPath.isEmpty) return;

    final totalPathLength = _calculatePixelPathLength(navigationPath, baseSize, height);
    final progressDistance = totalPathLength * pathProgress;
    if (progressDistance <= 0) return;

    double traveledDistance = 0;
    final dotRadius = 3.0 / scaleFactor;
    final pixelSpacing = (totalPathLength / 50.0).clamp(3.0, 20.0);

    for (int i = 0; i < navigationPath.length - 1; i++) {
      final pathFloor = pathFloorIndices.length > i ? pathFloorIndices[i] : currentFloor;
      if (pathFloor != currentFloor) {
        final p1 = navigationPath[i];
        final p2 = navigationPath[i + 1];
        final x1 = p1.dx * baseSize;
        final y1 = p1.dy * height;
        final x2 = p2.dx * baseSize;
        final y2 = p2.dy * height;
        traveledDistance += (Offset(x2 - x1, y2 - y1)).distance;
        continue;
      }

      final p1 = navigationPath[i];
      final p2 = navigationPath[i + 1];
      final x1 = p1.dx * baseSize;
      final y1 = p1.dy * height;
      final x2 = p2.dx * baseSize;
      final y2 = p2.dy * height;
      final segmentLength = (Offset(x2 - x1, y2 - y1)).distance;
      if (segmentLength <= 0) continue;

      final stepsInSegment = (segmentLength / pixelSpacing).ceil().clamp(1, 500);
      for (int step = 0; step <= stepsInSegment; step++) {
        final t = step / stepsInSegment;
        final x = x1 + (x2 - x1) * t;
        final y = y1 + (y2 - y1) * t;
        final currentPixel = traveledDistance + t * segmentLength;
        if (currentPixel > progressDistance) break;

        final paint = Paint()
          ..color = const Color(0xFF0A7040)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }

      traveledDistance += segmentLength;
      if (traveledDistance >= progressDistance) break;
    }

    if (navigationPath.isNotEmpty) {
      final startPoint = navigationPath[0];
      final pathFloor0 = pathFloorIndices.isNotEmpty ? pathFloorIndices[0] : currentFloor;
      if (pathFloor0 == currentFloor) {
        final sx = startPoint.dx * baseSize;
        final sy = startPoint.dy * height;

        final startMarker = Paint()
          ..color = const Color(0xFF16A34A)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(sx, sy), 8.0 / scaleFactor, startMarker);

        final startTextPainter = TextPainter(
          text: TextSpan(
            text: 'S',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9 / scaleFactor,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        startTextPainter.layout();
        startTextPainter.paint(
          canvas,
          Offset(sx - startTextPainter.width / 2, sy - startTextPainter.height / 2),
        );
      }
    }

    if (pathProgress >= 0.95) {
      final lastPoint = navigationPath.last;
      final lastFloor = pathFloorIndices.isNotEmpty ? pathFloorIndices.last : currentFloor;
      if (lastFloor == currentFloor) {
        final ex = lastPoint.dx * baseSize;
        final ey = lastPoint.dy * height;

        final endMarker = Paint()
          ..color = const Color(0xFFDC2626)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(ex, ey), 8.0 / scaleFactor, endMarker);

        final endTextPainter = TextPainter(
          text: TextSpan(
            text: 'E',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9 / scaleFactor,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        endTextPainter.layout();
        endTextPainter.paint(
          canvas,
          Offset(ex - endTextPainter.width / 2, ey - endTextPainter.height / 2),
        );
      }
    }
  }

  double _calculatePixelPathLength(List<Offset> path, double baseSize, double height) {
    if (path.length < 2) return 0;
    double length = 0;
    for (int i = 0; i < path.length - 1; i++) {
      final dx = (path[i + 1].dx - path[i].dx) * baseSize;
      final dy = (path[i + 1].dy - path[i].dy) * height;
      length += sqrt(dx * dx + dy * dy);
    }
    return length > 0 ? length : 1;
  }

  @override
  bool shouldRepaint(FloorPlanPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.navigationPath != navigationPath ||
        oldDelegate.pathFloorIndices != pathFloorIndices ||
        oldDelegate.currentFloor != currentFloor ||
        oldDelegate.pathProgress != pathProgress ||
        oldDelegate.isNavigating != isNavigating ||
        oldDelegate.livePosition != livePosition;
  }
}