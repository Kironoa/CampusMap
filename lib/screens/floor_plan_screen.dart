import 'dart:async';
import 'package:flutter/material.dart';
import 'package:naviapp/data/second_floor.dart';
import 'package:naviapp/widgets/ai_nav_sheet.dart';

class FloorPlanScreen extends StatefulWidget {
  final bool initialFloor;
  const FloorPlanScreen({super.key, this.initialFloor = true});

  @override
  State<FloorPlanScreen> createState() => _FloorPlanScreenState();
}

class _FloorPlanScreenState extends State<FloorPlanScreen>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  FloorRoom? _selectedRoom;
  double _scale = 1.0;
  bool _isSecondFloor = true;

  String? _highlightedRoomId;

  @override
  void initState() {
    super.initState();
    _isSecondFloor = widget.initialFloor;
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(String category, double opacity) {
    final baseColor = switch (category) {
      'academic' => const Color(0xFF2563EB),
      'office' => const Color(0xFFEA580C),
      'facility' => const Color(0xFF16A34A),
      'amenity' => const Color(0xFF7C3AED),
      _ => const Color(0xFFF97316),
    };
    return baseColor.withValues(alpha: opacity);
  }

  Color _getCategoryBorderColor(String category) {
    return switch (category) {
      'academic' => const Color(0xFF2563EB),
      'office' => const Color(0xFFEA580C),
      'facility' => const Color(0xFF16A34A),
      'amenity' => const Color(0xFF7C3AED),
      _ => const Color(0xFFF97316),
    };
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
      normalizedPos,
      secondFloor: _isSecondFloor,
    );

    setState(() {
      _selectedRoom = room;
    });

    if (room != null) {
      _showRoomDetails(room);
    }
  }

  void _showRoomDetails(FloorRoom room) {
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
                    room.category.toUpperCase(),
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
                  'Floor: ${_isSecondFloor ? '2nd Floor' : 'Ground Floor'}',
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
                    currentFloor: _isSecondFloor ? 'second' : 'ground',
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
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSecondFloor ? '2nd Floor' : 'Ground Floor',
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
                _isSecondFloor = !_isSecondFloor;
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
                _isSecondFloor ? 'Ground ↓' : '2nd Floor ↑',
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
                          rooms: _isSecondFloor
                              ? FloorPlanData.secondFloorRooms
                              : FloorPlanData.groundFloorRooms,
                          selectedRoom: _selectedRoom,
                          highlightedRoomId: _highlightedRoomId,
                          isDark: isDark,
                          scale: _scale,
                          getCategoryColor: _getCategoryColor,
                          getCategoryBorderColor: _getCategoryBorderColor,
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
                  currentFloor: _isSecondFloor ? 'second' : 'ground',
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
  final List<FloorRoom> rooms;
  final FloorRoom? selectedRoom;
  final String? highlightedRoomId;
  final bool isDark;
  final double scale;
  final Color Function(String, double) getCategoryColor;
  final Color Function(String) getCategoryBorderColor;

  FloorPlanPainter({
    required this.rooms,
    required this.selectedRoom,
    this.highlightedRoomId,
    required this.isDark,
    required this.scale,
    required this.getCategoryColor,
    required this.getCategoryBorderColor,
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
      final rect = Rect.fromLTRB(
        room.bounds.left * baseSize,
        room.bounds.top * height,
        room.bounds.right * baseSize,
        room.bounds.bottom * height,
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

      if (room.category == 'amenity' && room.id == 'safe_area') {
        final safeCenter = Offset(
          (room.bounds.left + room.bounds.width / 2) * baseSize,
          (room.bounds.top + room.bounds.height / 2) * height,
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

      if (room.category == 'amenity' && room.id.contains('restroom')) {
        final center = Offset(
          (room.bounds.left + room.bounds.width / 2) * baseSize,
          (room.bounds.top + room.bounds.height / 2) * height,
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
