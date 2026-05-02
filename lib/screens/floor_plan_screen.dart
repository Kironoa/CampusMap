import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naviapp/models/room.dart';
import 'package:naviapp/data/floor_plan_data.dart';
import 'package:naviapp/widgets/ai_nav_sheet.dart';

class FloorPlanScreen extends StatefulWidget {
  final int initialFloor;
  const FloorPlanScreen({super.key, this.initialFloor = 0});

  @override
  State<FloorPlanScreen> createState() => _FloorPlanScreenState();
}

class _FloorPlanScreenState extends State<FloorPlanScreen> with TickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  Room? _selectedRoom;
  double _scale = 1.0;
  late int _currentFloor;
  late AnimationController _pathAnimationController;
  late Animation<double> _pathAnimation;

  String? _highlightedRoomId;
  List<Offset> _navigationPath = [];
  bool _isNavigating = false;
  List<int> _pathFloorIndices = [];

  @override
  void initState() {
    super.initState();
    _currentFloor = widget.initialFloor;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
    ]);
    _pathAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pathAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pathAnimationController, curve: Curves.easeOut),
    );
    _pathAnimationController.addListener(() {
      setState(() {});
    });
  }

  void updateNavigationPath(List<Offset> path, List<int> floorIndices) {
    setState(() {
      _navigationPath = path;
      _pathFloorIndices = floorIndices;
      _isNavigating = path.isNotEmpty;
    });
    if (path.isNotEmpty) {
      _pathAnimationController.forward(from: 0);
    }
  }

  void clearNavigationPath() {
    setState(() {
      _navigationPath = [];
      _pathFloorIndices = [];
      _isNavigating = false;
    });
    _pathAnimationController.reset();
  }

  void navigateTo(String destination) {
    final normalizedDestination = destination.toLowerCase().trim();
    
    final Room? targetRoom = _findRoomByKeyword(normalizedDestination);
    if (targetRoom == null) return;

    final targetFloor = _getRoomFloor(targetRoom.id);
    final pathPoints = _generatePathFromEntrance(targetRoom);

    final List<int> floorIndices = List.filled(pathPoints.length, targetFloor);

    setState(() {
      _currentFloor = targetFloor;
      _selectedRoom = targetRoom;
      _highlightedRoomId = targetRoom.id;
      _navigationPath = pathPoints;
      _pathFloorIndices = floorIndices;
      _isNavigating = pathPoints.isNotEmpty;
    });

    if (pathPoints.isNotEmpty) {
      _pathAnimationController.forward(from: 0);
    }

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _highlightedRoomId = null;
        });
      }
    });
  }

  Room? _findRoomByKeyword(String keyword) {
    final allRooms = [
      ...FloorPlanData.groundFloorRooms,
      ...FloorPlanData.secondFloorRooms,
      ...FloorPlanData.thirdFloorRooms,
    ];

    for (final room in allRooms) {
      if (room.id.toLowerCase().contains(keyword) ||
          room.name.toLowerCase().contains(keyword)) {
        return room;
      }
    }
    return null;
  }

  int _getRoomFloor(String roomId) {
    if (roomId.startsWith('gf_')) return 0;
    if (roomId.startsWith('sf_')) return 1;
    if (roomId.startsWith('tf_')) return 2;
    return _currentFloor;
  }

  List<Offset> _generatePathFromEntrance(Room targetRoom) {
    const entrance = Offset(0.5, 0.9);
    
    if (targetRoom.bounds == null) {
      return [entrance];
    }

    final bounds = targetRoom.bounds!;
    final centerX = (bounds.left + bounds.right) / 2;
    final centerY = bounds.top;
    final targetPos = Offset(centerX, centerY);

    final List<Offset> path = [];
    path.add(entrance);
    
    final corridors = [
      const Offset(0.5, 0.7),
      const Offset(0.5, 0.5),
      Offset(centerX, 0.5),
    ];

    for (final corridor in corridors) {
      if ((corridor - targetPos).distance > 0.05) {
        path.add(corridor);
      }
    }
    
    path.add(targetPos);

    return path;
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _transformationController.dispose();
    _pathAnimationController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(RoomCategory category, double opacity) {
    return Room.categoryColor(category).withValues(alpha: opacity);
  }

  Color _getCategoryBorderColor(RoomCategory category) {
    return Room.categoryColor(category);
  }

  void _handleTap(TapUpDetails details, Size viewportSize) {
    if (!mounted) return;

    final localPos = details.localPosition;

    final scale = _scale;
    final scaledWidth = viewportSize.width * scale;
    final scaledHeight = viewportSize.height * scale;
    final offsetX = (viewportSize.width - scaledWidth) / 2;
    final offsetY = (viewportSize.height - scaledHeight) / 2;

    final normalizedX = (localPos.dx - offsetX) / scaledWidth;
    final normalizedY = (localPos.dy - offsetY) / scaledHeight;

    if (normalizedX < 0 ||
        normalizedX > 1 ||
        normalizedY < 0 ||
        normalizedY > 1) {
      return;
    }

    final normalizedPos = Offset(
      normalizedX.clamp(0.0, 1.0),
      normalizedY.clamp(0.0, 1.0),
    );
    final room = FloorPlanData.getRoomAtPosition(
      _currentFloor,
      normalizedPos.dx,
      normalizedPos.dy,
    );

    setState(() {
      _selectedRoom = room;
    });

    if (room != null) {
      _showRoomDetails(room);
    }
  }

  void _showRoomDetails(Room room) {
    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C1F0E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(room.category, 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    room.category.name.toUpperCase(),
                    style: TextStyle(
                      color: _getCategoryBorderColor(room.category),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              room.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFFFFF7ED)
                    : const Color(0xFF1C0A00),
              ),
            ),
            if (room.description != null) ...[
              const SizedBox(height: 8),
              Text(
                room.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFFFED7AA)
                      : const Color(0xFF78350F),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: const Color(0xFFF97316),
                ),
                const SizedBox(width: 4),
                Text(
                  'Floor: ${FloorPlanData.getFloorName(_currentFloor)}',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFFED7AA)
                        : const Color(0xFF78350F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.psychology_outlined),
              label: const Text('Navigate with AI'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
builder: (_) => AINavSheet(
                    currentFloor: FloorPlanData.getFloorName(_currentFloor).toLowerCase(),
                    currentRoomId: room.id,
                    onNavigationResult: (pathPoints, targetFloor, targetRoomId) {
                      if (pathPoints.isNotEmpty || targetRoomId != null) {
                        setState(() {
                          if (targetFloor != null && targetFloor != _currentFloor) {
                            _currentFloor = targetFloor;
                          }
                          if (targetRoomId != null) {
                            final room = FloorPlanData.getRoomById(targetRoomId);
                            if (room != null) {
                              _selectedRoom = room;
                              _highlightedRoomId = targetRoomId;
                            }
                          }
                          if (pathPoints.isNotEmpty) {
                            _navigationPath = pathPoints;
                            _pathFloorIndices = List.filled(pathPoints.length, targetFloor ?? _currentFloor);
                            _isNavigating = true;
                            _pathAnimationController.forward(from: 0);
                          }
                        });
                      }
                    },
                    onNavigateRequest: (destination) => navigateTo(destination),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void highlightRoom(String roomId) {
    setState(() {
      _highlightedRoomId = roomId;
    });
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _highlightedRoomId = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final floorNames = ['Ground', '2nd Floor', '3rd Floor'];
    final nextFloor = (_currentFloor + 1) % 3;
    final toggleLabel = '${floorNames[nextFloor]} ${nextFloor > _currentFloor ? '↑' : '↓'}';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          FloorPlanData.getFloorName(_currentFloor),
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
        actions: [
          GestureDetector(
            onTap: () {
              int targetFloor = (_currentFloor + 1) % 3;
              setState(() {
                _currentFloor = targetFloor;
                _selectedRoom = null;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 12),
              child: Text(
                toggleLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.5,
        maxScale: 4.0,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewportSize = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            final minDimension = constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth
                : constraints.maxHeight;

            _scale = minDimension / 400;
            final scaledSize = Size(400 * _scale * 2.8, 400 * _scale);

            return Center(
              child: SizedBox(
                width: scaledSize.width,
                height: scaledSize.height,
                child: GestureDetector(
                  onTapUp: (details) => _handleTap(details, viewportSize),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          _currentFloor == 0
                              ? 'assets/images/ground_floor.png'
                              : _currentFloor == 1
                                  ? 'assets/images/second_floor.png'
                                  : 'assets/images/third_floor.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      CustomPaint(
                        size: scaledSize,
                        painter: FloorPlanPainter(
                          rooms: FloorPlanData.getRoomsForFloor(_currentFloor),
                          selectedRoom: _selectedRoom,
                          highlightedRoomId: _highlightedRoomId,
                          isDark: isDark,
                          scale: _scale,
                          getCategoryColor: _getCategoryColor,
                          getCategoryBorderColor: _getCategoryBorderColor,
                          navigationPath: _navigationPath,
                          pathFloorIndices: _pathFloorIndices,
                          currentFloor: _currentFloor,
                          pathProgress: _pathAnimation.value,
                          isNavigating: _isNavigating,
                          imageOriginalSize: const Size(1120, 400),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'fab_ai',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AINavSheet(
                  currentFloor: FloorPlanData.getFloorName(_currentFloor).toLowerCase(),
                  currentRoomId: _selectedRoom?.id,
                  onNavigationResult: (pathPoints, targetFloor, targetRoomId) {
                    if (pathPoints.isNotEmpty || targetRoomId != null) {
                      setState(() {
                        if (targetFloor != null && targetFloor != _currentFloor) {
                          _currentFloor = targetFloor;
                        }
                        if (targetRoomId != null) {
                          final room = FloorPlanData.getRoomById(targetRoomId);
                          if (room != null) {
                            _selectedRoom = room;
                            _highlightedRoomId = targetRoomId;
                          }
                        }
                        if (pathPoints.isNotEmpty) {
                          _navigationPath = pathPoints;
                          _pathFloorIndices = List.filled(pathPoints.length, targetFloor ?? _currentFloor);
                          _isNavigating = true;
                          _pathAnimationController.forward(from: 0);
                        }
                      });
                    }
                  },
                  onNavigateRequest: (destination) => navigateTo(destination),
                ),
              );
            },
            backgroundColor: const Color(0xFF16A34A),
            foregroundColor: Colors.white,
            child: const Icon(Icons.psychology_outlined),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'fab_floor_switch',
            onPressed: () {
              _transformationController.value = Matrix4.identity();
            },
            backgroundColor: const Color(0xFFF97316),
            foregroundColor: Colors.white,
            child: const Icon(Icons.center_focus_strong),
          ),
        ],
      ),
    );
  }
}

class FloorPlanPainter extends CustomPainter {
  final List<Room> rooms;
  final Room? selectedRoom;
  final String? highlightedRoomId;
  final bool isDark;
  final double scale;
  final Color Function(RoomCategory, double) getCategoryColor;
  final Color Function(RoomCategory) getCategoryBorderColor;
  final List<Offset> navigationPath;
  final List<int> pathFloorIndices;
  final int currentFloor;
  final double pathProgress;
  final bool isNavigating;
  final Size imageOriginalSize;
  ui.Image? _dogPawImage;

  FloorPlanPainter({
    required this.rooms,
    required this.selectedRoom,
    this.highlightedRoomId,
    required this.isDark,
    required this.scale,
    required this.getCategoryColor,
    required this.getCategoryBorderColor,
    this.navigationPath = const [],
    this.pathFloorIndices = const [],
    this.currentFloor = 0,
    this.pathProgress = 0,
    this.isNavigating = false,
    this.imageOriginalSize = const Size(1120, 400),
  });

  @override
  void paint(Canvas canvas, Size size) {
    _loadDogPawImage();
    
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

    final borderColor = isDark ? Colors.grey.shade500 : Colors.grey.shade400;
    final textColor = isDark ? Colors.white : Colors.black87;

    for (final room in rooms) {
      if (room.bounds == null) continue;
      final bounds = room.bounds!;
      final rect = Rect.fromLTRB(
        bounds.left * baseSize,
        bounds.top * height,
        bounds.right * baseSize,
        bounds.bottom * height,
      );

      final isSelected = selectedRoom?.id == room.id;
      final isHighlighted = highlightedRoomId == room.id;
      final fillOpacity = isSelected
          ? 0.35
          : isHighlighted
          ? 0.3
          : (isDark ? 0.25 : 0.15);
      final borderWidth = isSelected
          ? 2.5 / scaleFactor
          : isHighlighted
          ? 3.0 / scaleFactor
          : 1.0 / scaleFactor;

      final fillPaint = Paint()
        ..color = getCategoryColor(room.category, fillOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, fillPaint);

      final outlinePaint = Paint()
        ..color = isSelected
            ? getCategoryBorderColor(room.category)
            : isHighlighted
            ? const Color(0xFFF97316)
            : borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth;
      canvas.drawRect(rect, outlinePaint);

      if (isHighlighted) {
        final highlightPaint = Paint()
          ..color = const Color(0xFFF97316).withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0 / scaleFactor;
        canvas.drawRect(rect, highlightPaint);
      }

      if (room.category == RoomCategory.utility && room.id == 'sf_safe_area') {
        final safeCenter = Offset(
          (bounds.left + bounds.width / 2) * baseSize,
          (bounds.top + bounds.height / 2) * height,
        );

        const safeRadius = 18.0;
        final safeFillPaint = Paint()
          ..color = const Color(0xFFDC2626)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(safeCenter, safeRadius, safeFillPaint);

        final safeOutlinePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 / scaleFactor;
        canvas.drawCircle(safeCenter, safeRadius, safeOutlinePaint);

        final textStyle = TextStyle(
          color: Colors.white,
          fontSize: 9 / scaleFactor,
          fontWeight: FontWeight.bold,
        );

        final shieldPainter = TextPainter(
          text: TextSpan(text: 'SAFE', style: textStyle),
          textDirection: TextDirection.ltr,
        );
        shieldPainter.layout();
        shieldPainter.paint(
          canvas,
          Offset(
            safeCenter.dx - shieldPainter.width / 2,
            safeCenter.dy - shieldPainter.height / 2,
          ),
        );
        continue;
      }

      if (room.category == RoomCategory.utility && room.id.contains('restroom')) {
        final center = Offset(
          (bounds.left + bounds.width / 2) * baseSize,
          (bounds.top + bounds.height / 2) * height,
        );

        final iconPaint = Paint()
          ..color = isDark ? Colors.grey.shade400 : Colors.grey.shade600
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, 6, iconPaint);
        continue;
      }

      final fontSize = (rect.width * 0.12 / scaleFactor).clamp(7.0, 11.0);
      if (rect.width > 35 && rect.height > 18) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: room.name,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        textPainter.layout(maxWidth: rect.width - 4);

        if (textPainter.width <= rect.width - 4 &&
            textPainter.height <= rect.height - 4) {
          textPainter.paint(
            canvas,
            Offset(
              rect.left + (rect.width - textPainter.width) / 2,
              rect.top + (rect.height - textPainter.height) / 2,
            ),
          );
        }
      }
    }

    if (isNavigating && navigationPath.isNotEmpty) {
      _drawNavigationPath(canvas, baseSize, height, offsetX, offsetY, scaleFactor);
    }

    canvas.restore();
  }

  void _loadDogPawImage() async {
    if (_dogPawImage == null) {
      try {
        final byteData = await rootBundle.load('assets/images/dog_paw.png');
        final codec = await ui.instantiateImageCodec(byteData.buffer.asUint8List());
        final frameInfo = await codec.getNextFrame();
        _dogPawImage = frameInfo.image;
      } catch (e) {
        _dogPawImage = null;
      }
    }
  }

  void _drawNavigationPath(Canvas canvas, double baseSize, double height, double offsetX, double offsetY, double scaleFactor) {
    if (navigationPath.isEmpty) return;

    final maxVisibleIndex = (navigationPath.length * pathProgress).floor();
    if (maxVisibleIndex <= 0) return;

    final visiblePath = navigationPath.sublist(0, maxVisibleIndex.clamp(0, navigationPath.length));

    final pathPaint = Paint()
      ..color = const Color(0xFFF97316).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0 / scaleFactor
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (int i = 0; i < visiblePath.length; i++) {
      final point = visiblePath[i];
      final pathFloor = pathFloorIndices.length > i ? pathFloorIndices[i] : currentFloor;
      if (pathFloor != currentFloor) continue;
      
      final x = offsetX + point.dx * baseSize;
      final y = offsetY + point.dy * height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, pathPaint);

    final pawSize = 18.0 / scaleFactor;
    final dotPaint = Paint()
      ..color = const Color(0xFFF97316)
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 / scaleFactor;

    for (int i = 0; i < maxVisibleIndex; i++) {
      final point = navigationPath[i];
      final pathFloor = pathFloorIndices.length > i ? pathFloorIndices[i] : currentFloor;
      if (pathFloor != currentFloor) continue;
      
      final x = offsetX + point.dx * baseSize;
      final y = offsetY + point.dy * height;

      if (_dogPawImage != null) {
        final srcRect = Rect.fromLTWH(0, 0, _dogPawImage!.width.toDouble(), _dogPawImage!.height.toDouble());
        final dstRect = Rect.fromCenter(center: Offset(x, y), width: pawSize, height: pawSize);
        canvas.drawImageRect(_dogPawImage!, srcRect, dstRect, dotPaint);
        canvas.drawRect(dstRect, dotBorderPaint);
      } else {
        canvas.drawCircle(Offset(x, y), pawSize / 2, dotPaint);
        canvas.drawCircle(Offset(x, y), pawSize / 2, dotBorderPaint);
      }

      if (i == 0) {
        final startMarker = Paint()
          ..color = const Color(0xFF16A34A)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 8.0 / scaleFactor, startMarker);
        
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
          Offset(x - startTextPainter.width / 2, y - startTextPainter.height / 2),
        );
      }
    }

    final lastVisibleOnCurrentFloor = visiblePath.lastWhere(
      (p) => pathFloorIndices.isEmpty || pathFloorIndices.length != navigationPath.length || pathFloorIndices[visiblePath.indexOf(p)] == currentFloor,
      orElse: () => visiblePath.last,
    );
    final lastIndex = navigationPath.indexOf(lastVisibleOnCurrentFloor);
    if (lastIndex >= 0 && lastIndex == navigationPath.length - 1 && (pathFloorIndices.length <= lastIndex || pathFloorIndices[lastIndex] == currentFloor)) {
      final point = navigationPath[lastIndex];
      final x = offsetX + point.dx * baseSize;
      final y = offsetY + point.dy * height;

      final endMarker = Paint()
        ..color = const Color(0xFFDC2626)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 8.0 / scaleFactor, endMarker);

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
        Offset(x - endTextPainter.width / 2, y - endTextPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    final old = oldDelegate as FloorPlanPainter;
    return old.selectedRoom != selectedRoom ||
        old.highlightedRoomId != highlightedRoomId ||
        old.isDark != isDark ||
        old.scale != scale ||
        old.navigationPath != navigationPath ||
        old.pathFloorIndices != pathFloorIndices ||
        old.currentFloor != currentFloor ||
        old.pathProgress != pathProgress ||
        old.isNavigating != isNavigating;
  }
}
