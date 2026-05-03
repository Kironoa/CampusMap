// lib/screens/floor_plan_screen.dart
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naviapp/widgets/ai_nav_sheet.dart';

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

  static const Map<String, Offset> _groundFloorPositions = {
    'gf_main_lobby': Offset(0.72, 0.72),
    'gf_drive_way': Offset(0.44, 0.92),
    'gf_scholarship_welfare': Offset(0.44, 0.55),
    'gf_ojt_placement': Offset(0.44, 0.65),
    'gf_accreditation': Offset(0.60, 0.72),
    'gf_record_registrar': Offset(0.44, 0.42),
    'gf_registrar': Offset(0.38, 0.42),
    'gf_vp_admin': Offset(0.30, 0.42),
    'gf_crim_lab': Offset(0.17, 0.42),
    'gf_icje': Offset(0.10, 0.42),
    'gf_sldo': Offset(0.03, 0.32),
    'gf_ciso': Offset(0.60, 0.42),
    'gf_avr': Offset(0.68, 0.42),
    'gf_dressing': Offset(0.76, 0.42),
    'gf_music': Offset(0.82, 0.42),
    'gf_dance': Offset(0.89, 0.42),
    'gf_barracks': Offset(0.96, 0.42),
    'gf_medical': Offset(0.64, 0.20),
    'gf_restroom_left': Offset(0.09, 0.20),
    'gf_restroom_center': Offset(0.40, 0.20),
    'gf_restroom_right': Offset(0.86, 0.20),
    'gf_mb105': Offset(0.72, 0.20),
    'gf_mb103': Offset(0.78, 0.20),
    'gf_mpr': Offset(0.84, 0.20),
    'gf_midwifery': Offset(0.90, 0.20),
    'gf_pfom': Offset(0.96, 0.20),
    'gf_ias': Offset(0.48, 0.20),
    'gf_ite': Offset(0.36, 0.20),
    'gf_ibfs': Offset(0.29, 0.20),
    'gf_ihs': Offset(0.24, 0.20),
    'gf_training': Offset(0.18, 0.20),
    'gf_ics': Offset(0.13, 0.20),
    'gf_cr_left1': Offset(0.17, 0.07),
    'gf_cr_left2': Offset(0.19, 0.07),
    'gf_cr_right1': Offset(0.89, 0.07),
    'gf_cr_right2': Offset(0.91, 0.07),
    'gf_elevator': Offset(0.50, 0.42),
  };

  static const Map<String, Offset> _secondFloorPositions = {
    'sf_main_stage': Offset(0.50, 0.12),
    'sf_guidance_testing': Offset(0.04, 0.32),
    'sf_sub_lobby': Offset(0.08, 0.32),
    'sf_computer_lab': Offset(0.18, 0.32),
    'sf_computer_room_1': Offset(0.30, 0.32),
    'sf_computer_room_2': Offset(0.37, 0.32),
    'sf_computer_room_3': Offset(0.43, 0.32),
    'sf_restroom_left': Offset(0.47, 0.32),
    'sf_restroom_center_left': Offset(0.50, 0.32),
    'sf_restroom_center_right': Offset(0.53, 0.32),
    'sf_restroom_right': Offset(0.56, 0.32),
    'sf_vip_lounge': Offset(0.60, 0.32),
    'sf_faculty_lounge': Offset(0.75, 0.32),
    'sf_speech_lab': Offset(0.87, 0.32),
    'sf_bseed_left': Offset(0.97, 0.32),
    'sf_bseed_right': Offset(0.97, 0.55),
    'sf_guidance_counseling': Offset(0.04, 0.55),
    'sf_moot_court': Offset(0.17, 0.55),
    'sf_business_center': Offset(0.30, 0.55),
    'sf_classroom_left': Offset(0.40, 0.55),
    'sf_classroom_center': Offset(0.45, 0.55),
    'sf_classroom_right': Offset(0.50, 0.55),
    'sf_board_room': Offset(0.60, 0.55),
    'sf_hrmo': Offset(0.67, 0.55),
    'sf_faculty_room': Offset(0.75, 0.55),
    'sf_supply': Offset(0.82, 0.55),
    'sf_vp_planning': Offset(0.87, 0.55),
    'sf_evp': Offset(0.92, 0.55),
    'sf_deans': Offset(0.44, 0.70),
    'sf_vpaa': Offset(0.44, 0.80),
    'sf_president': Offset(0.60, 0.75),
    'sf_deck_canopy': Offset(0.50, 0.95),
    'sf_bleacher_left': Offset(0.25, 0.18),
    'sf_bleacher_right': Offset(0.75, 0.18),
  };

  static const Map<String, Offset> _thirdFloorPositions = {
    'tf_prayer': Offset(0.37, 0.15),
    'tf_activity': Offset(0.50, 0.12),
    'tf_research': Offset(0.60, 0.15),
    'tf_library': Offset(0.25, 0.35),
    'tf_lrc1': Offset(0.07, 0.35),
    'tf_lrc2': Offset(0.43, 0.35),
    'tf_elevator': Offset(0.50, 0.35),
    'tf_restroom_left': Offset(0.54, 0.35),
    'tf_restroom_right': Offset(0.57, 0.35),
    'tf_classroom_1': Offset(0.63, 0.35),
    'tf_classroom_2': Offset(0.70, 0.35),
    'tf_classroom_3': Offset(0.76, 0.35),
    'tf_classroom_4': Offset(0.82, 0.35),
    'tf_classroom_5': Offset(0.88, 0.35),
    'tf_science_lab': Offset(0.93, 0.35),
    'tf_classroom_6': Offset(0.98, 0.35),
    'tf_bleacher_left': Offset(0.25, 0.65),
    'tf_bleacher_right': Offset(0.75, 0.65),
    'tf_main_stage': Offset(0.50, 0.75),
  };

  Map<String, Offset> _getFloorPositionMap(int floor) {
    switch (floor) {
      case 0:
        return _groundFloorPositions;
      case 1:
        return _secondFloorPositions;
      case 2:
        return _thirdFloorPositions;
      default:
        return _groundFloorPositions;
    }
  }

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
    final positions = _getFloorPositionMap(_currentFloor);
    final targetPos = positions[roomId];

    if (targetPos == null) {
      for (int floor = 0; floor < 3; floor++) {
        final floorPositions = _getFloorPositionMap(floor);
        if (floorPositions.containsKey(roomId)) {
          _currentFloor = floor;
          _navigationPath.clear();
          _generatePathFromEntrance(floorPositions[roomId]!);
          return;
        }
      }
      return;
    }

    _generatePathFromEntrance(targetPos);
  }

  void _generatePathFromEntrance(Offset targetPos) {
    const entrance = Offset(0.50, 0.95);
    final path = <Offset>[entrance];

    if (targetPos.dx < 0.30) {
      path.add(const Offset(0.30, 0.95));
      path.add(const Offset(0.30, 0.45));
    } else if (targetPos.dx > 0.70) {
      path.add(const Offset(0.70, 0.95));
      path.add(const Offset(0.70, 0.45));
    }

    path.add(Offset(targetPos.dx, 0.45));
    path.add(targetPos);

    final floorIndices = List<int>.filled(path.length, _currentFloor);
    setState(() {
      _navigationPath = path;
      _pathFloorIndices = floorIndices;
      _isNavigating = path.isNotEmpty;
    });
    if (path.isNotEmpty) {
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
        backgroundColor: const Color(0xFFF97316),
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
        onNavigationResult: (result) {
          final targetFloor = int.tryParse(result.floor) ?? _currentFloor;
          setState(() {
            _currentFloor = targetFloor;
            if (result.pathPoints.isNotEmpty) {
              _navigationPath = result.pathPoints;
              _pathFloorIndices = List.filled(result.pathPoints.length, targetFloor);
              _isNavigating = true;
              _pathAnimationController.forward(from: 0);
            }
          });
        },
        initialFloor: _floorNames[_currentFloor],
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
            ..color = const Color(0xFFF97316)
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