import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:naviapp/models/room.dart';
import 'package:naviapp/data/floor_plan_data.dart';
import 'package:naviapp/widgets/ai_nav_sheet.dart';

class FloorPlanScreen extends StatefulWidget {
  final int initialFloor;
  const FloorPlanScreen({super.key, this.initialFloor = 0});

  @override
  State<FloorPlanScreen> createState() => _FloorPlanScreenState();
}

class _FloorPlanScreenState extends State<FloorPlanScreen> {
  final TransformationController _transformationController =
      TransformationController();
  Room? _selectedRoom;
  double _scale = 1.0;
  late int _currentFloor;

  String? _highlightedRoomId;
  List<Offset> _navigationPath = [];
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _currentFloor = widget.initialFloor;
  }

  void updateNavigationPath(List<Offset> path) {
    setState(() {
      _navigationPath = path;
      _isNavigating = path.isNotEmpty;
    });
  }

  void clearNavigationPath() {
    setState(() {
      _navigationPath = [];
      _isNavigating = false;
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
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
              setState(() {
                _currentFloor = (_currentFloor + 1) % 3;
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
                          isNavigating: _isNavigating,
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
                          _isNavigating = true;
                        }
                      });
                    }
                  },
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
  final bool isNavigating;

  FloorPlanPainter({
    required this.rooms,
    required this.selectedRoom,
    this.highlightedRoomId,
    required this.isDark,
    required this.scale,
    required this.getCategoryColor,
    required this.getCategoryBorderColor,
    this.navigationPath = const [],
    this.isNavigating = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final baseSize = 400 * 2.8;
    final height = 400.0;
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

  void _drawNavigationPath(Canvas canvas, double baseSize, double height, double offsetX, double offsetY, double scaleFactor) {
    if (navigationPath.isEmpty) return;

    final pathPaint = Paint()
      ..color = const Color(0xFF16A34A).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 / scaleFactor
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (int i = 0; i < navigationPath.length; i++) {
      final point = navigationPath[i];
      final x = offsetX + point.dx * baseSize;
      final y = offsetY + point.dy * height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, pathPaint);

    final footstepPaint = Paint()
      ..color = const Color(0xFF16A34A)
      ..style = PaintingStyle.fill;

    final footstepBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 / scaleFactor;

    for (int i = 0; i < navigationPath.length; i++) {
      final point = navigationPath[i];
      final x = offsetX + point.dx * baseSize;
      final y = offsetY + point.dy * height;

      canvas.drawCircle(Offset(x, y), 5.0 / scaleFactor, footstepPaint);
      canvas.drawCircle(Offset(x, y), 5.0 / scaleFactor, footstepBorderPaint);

      if (i == 0) {
        final startMarker = Paint()
          ..color = const Color(0xFF16A34A)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 7.0 / scaleFactor, startMarker);
        
        final startTextPainter = TextPainter(
          text: TextSpan(
            text: 'S',
            style: TextStyle(
              color: Colors.white,
              fontSize: 8 / scaleFactor,
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
      } else if (i == navigationPath.length - 1) {
        final endMarker = Paint()
          ..color = const Color(0xFFDC2626)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 7.0 / scaleFactor, endMarker);

        final endTextPainter = TextPainter(
          text: TextSpan(
            text: 'E',
            style: TextStyle(
              color: Colors.white,
              fontSize: 8 / scaleFactor,
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
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    final old = oldDelegate as FloorPlanPainter;
    return old.selectedRoom != selectedRoom ||
        old.highlightedRoomId != highlightedRoomId ||
        old.isDark != isDark ||
        old.scale != scale ||
        old.navigationPath != navigationPath ||
        old.isNavigating != isNavigating;
  }
}
