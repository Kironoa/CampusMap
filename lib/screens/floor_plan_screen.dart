// lib/screens/floor_plan_screen.dart
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naviapp/widgets/ai_nav_sheet.dart';
import 'package:naviapp/services/navigation_graph.dart';
import 'package:naviapp/services/pathfinder.dart';

class FloorPlanScreen extends StatefulWidget {
  final int initialFloor;
  const FloorPlanScreen({super.key, this.initialFloor = 0});

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
  ui.Image? _pawImage;
  bool _pawImageLoaded = false;

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
    _loadPawImage();
  }

  Future<void> _loadPawImage() async {
    try {
      final byteData = await rootBundle.load('assets/images/dog_paw.png');
      final bytes = byteData.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _pawImage = frameInfo.image;
          _pawImageLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to load paw image: $e');
    }
  }

  void navigateTo(String roomId) {
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
                        pawImage: _pawImage,
                        pawImageLoaded: _pawImageLoaded,
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
        onNavigationResult: (pathOffsets, floorIndex, roomId) {
          setState(() {
            _currentFloor = floorIndex;
            if (pathOffsets.isNotEmpty) {
              _navigationPath = pathOffsets;
              _pathFloorIndices = List.filled(pathOffsets.length, floorIndex);
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
  final ui.Image? pawImage;
  final bool pawImageLoaded;

  FloorPlanPainter({
    required this.isDark,
    this.navigationPath = const [],
    this.pathFloorIndices = const [],
    this.currentFloor = 0,
    this.pathProgress = 0,
    this.isNavigating = false,
    this.imageOriginalSize = const Size(1464, 720),
    this.pawImage,
    this.pawImageLoaded = false,
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

    canvas.restore();
  }

  void _drawNavigationPath(Canvas canvas, double baseSize, double height, double scaleFactor) {
    if (navigationPath.isEmpty) return;

    final totalPathLength = _calculatePixelPathLength(navigationPath, baseSize, height);
    final progressDistance = totalPathLength * pathProgress;
    if (progressDistance <= 0) return;

    double traveledDistance = 0;
    final useImage = pawImageLoaded && pawImage != null;
    final pawSize = 12.0 / scaleFactor;
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

        if (useImage && pawImage != null) {
          canvas.drawImageRect(
            pawImage!,
            Rect.fromLTWH(0, 0, pawImage!.width.toDouble(), pawImage!.height.toDouble()),
            Rect.fromCenter(center: Offset(x, y), width: pawSize, height: pawSize),
            Paint(),
          );
        } else {
          final pawFillPaint = Paint()
            ..color = const Color(0xFF0A7040)
            ..style = PaintingStyle.fill;
          final pawBorderPaint = Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5 / scaleFactor;
          canvas.drawCircle(Offset(x, y), pawSize / 2, pawFillPaint);
          canvas.drawCircle(Offset(x, y), pawSize / 2, pawBorderPaint);
        }
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
        oldDelegate.pawImageLoaded != pawImageLoaded;
  }
}