import 'package:flutter/material.dart';
import 'package:naviapp/data/floor_plan_data.dart';
import 'package:naviapp/models/room.dart';
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
  late int _currentFloor = widget.initialFloor;

  String? _highlightedRoomId;

  @override
  void initState() {
    super.initState();
    _currentFloor = widget.initialFloor;
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(RoomCategory category, double opacity) {
    final baseColor = Room.categoryColor(category);
    return baseColor.withValues(alpha: opacity);
  }

  Color categoryColor(RoomCategory category) {
    return Room.categoryColor(category);
  }

  List<Room> _getRoomsForFloor(int floorIndex) {
    return FloorPlanData.getRoomsForFloor(floorIndex);
  }

  String _getImageAssetForFloor(int floorIndex) {
    return FloorPlanData.getImageAssetForFloor(floorIndex);
  }

  String _getFloorName(int floorIndex) {
    return FloorPlanData.getFloorName(floorIndex);
  }

  String _getNextFloorLabel(int currentFloor) {
    final next = (currentFloor + 1) % 3;
    return '${_getFloorName(next)} ↑';
  }

  void _handleTap(TapUpDetails details, Size viewportSize) {
    if (!mounted) return;

    final rooms = _getRoomsForFloor(_currentFloor);
    if (rooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tap to select rooms coming soon for this floor. Use AI Navigator instead.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

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

    Room? room;
    for (final r in rooms) {
      if (r.bounds?.contains(normalizedPos) == true) {
        room = r;
        break;
      }
    }

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
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.white,
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
                      color: categoryColor(room.category),
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
                color: isDark ? colorScheme.onSurface : const Color(0xFF1C0A00),
              ),
            ),
            if (room.description != null) ...[
              const SizedBox(height: 8),
              Text(
                room.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? colorScheme.onSurface.withValues(alpha: 0.7)
                      : const Color(0xFF78350F),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.location_on,
                    size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  'Floor: ${_getFloorName(_currentFloor)}',
                  style: TextStyle(
                    color: isDark
                        ? colorScheme.onSurface.withValues(alpha: 0.7)
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
                    currentFloor: _getFloorName(_currentFloor).toLowerCase(),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getFloorName(_currentFloor),
          style: const TextStyle(
              fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
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
                color: colorScheme.onPrimary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 12),
              child: Text(
                _getNextFloorLabel(_currentFloor),
                style: TextStyle(
                  color: colorScheme.onPrimary,
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

            final rooms = _getRoomsForFloor(_currentFloor);

            return Center(
              child: SizedBox(
                width: scaledSize.width,
                height: scaledSize.height,
                child: GestureDetector(
                  onTapUp: (details) => _handleTap(details, viewportSize),
                  child: Stack(
                    children: [
                      Image.asset(
                        _getImageAssetForFloor(_currentFloor),
                        width: scaledSize.width,
                        height: scaledSize.height,
                        fit: BoxFit.fill,
                      ),
                      CustomPaint(
                        size: scaledSize,
                        painter: FloorPlanPainter(
                          rooms: rooms,
                          selectedRoom: _selectedRoom,
                          highlightedRoomId: _highlightedRoomId,
                          isDark: isDark,
                          scale: _scale,
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
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AINavSheet(
                  currentFloor: _getFloorName(_currentFloor).toLowerCase(),
                  currentRoomId: _selectedRoom?.id,
                ),
              );
            },
            backgroundColor: const Color(0xFF16A34A),
            foregroundColor: Colors.white,
            child: const Icon(Icons.psychology_outlined),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            onPressed: () {
              _transformationController.value = Matrix4.identity();
            },
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
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

  FloorPlanPainter({
    required this.rooms,
    required this.selectedRoom,
    this.highlightedRoomId,
    required this.isDark,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const baseWidth = 400 * 2.8;
    const baseHeight = 400.0;
    final scaleX = size.width / baseWidth;
    final scaleY = size.height / baseHeight;
    final scaleFactor = scaleX < scaleY ? scaleX : scaleY;
    final scaledWidth = baseWidth * scaleFactor;
    final scaledHeight = baseHeight * scaleFactor;
    final offsetX = (size.width - scaledWidth) / 2;
    final offsetY = (size.height - scaledHeight) / 2;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scaleFactor);

    final borderColor = isDark ? Colors.grey.shade500 : Colors.grey.shade400;
    final textColor = isDark ? Colors.white : Colors.black87;

    for (final room in rooms) {
      if (room.bounds == null) continue;

      final rect = Rect.fromLTRB(
        room.bounds!.left * baseWidth,
        room.bounds!.top * baseHeight,
        room.bounds!.right * baseWidth,
        room.bounds!.bottom * baseHeight,
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
        ..color = Room.categoryColor(room.category).withValues(alpha: fillOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, fillPaint);

      final outlinePaint = Paint()
        ..color = isSelected
            ? Room.categoryColor(room.category)
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

      if (room.category == RoomCategory.utility && room.id.contains('safe')) {
        final safeCenter = Offset(
          (room.bounds!.left + room.bounds!.width / 2) * baseWidth,
          (room.bounds!.top + room.bounds!.height / 2) * baseHeight,
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

      if (room.category == RoomCategory.utility && room.id.contains('rest')) {
        final center = Offset(
          (room.bounds!.left + room.bounds!.width / 2) * baseWidth,
          (room.bounds!.top + room.bounds!.height / 2) * baseHeight,
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

    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    final old = oldDelegate as FloorPlanPainter;
    return old.selectedRoom != selectedRoom ||
        old.highlightedRoomId != highlightedRoomId ||
        old.isDark != isDark ||
        old.scale != scale;
  }
}
