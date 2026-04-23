import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mobile_app/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    _showGlassAlert(context, message, Colors.greenAccent);
  }

  void showError(BuildContext context, String message) {
    if (!context.mounted) return;
    _showGlassAlert(context, message, Colors.redAccent);
  }

  void showWarning(BuildContext context, String message) {
    if (!context.mounted) return;
    _showGlassAlert(context, message, Colors.orangeAccent);
  }

  void showInfo(BuildContext context, String message) {
    if (!context.mounted) return;
    final accent = Provider.of<ThemeProvider>(context, listen: false).currentAccentColor;
    _showGlassAlert(context, message, accent);
  }

  void showGlassAlert(BuildContext context, String message, {Color? color}) {
    if (!context.mounted) return;
    final accent = Provider.of<ThemeProvider>(context, listen: false).currentAccentColor;
    _showGlassAlert(context, message, color ?? accent);
  }

  void _showGlassAlert(BuildContext context, String message, Color color) {
    if (!context.mounted) return;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _GlassAlertAnimated(
        message: message,
        themeColor: color,
        onDismiss: () {
          entry.remove();
        },
      ),
    );
    final overlay = Overlay.of(context);
    overlay.insert(entry);
  }

  Future<bool> confirmDelete(BuildContext context, String itemName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteConfirmDialog(itemName: itemName),
    );
    return result ?? false;
  }

  Future<void> showDeleteDialog(BuildContext context, String itemName, VoidCallback onConfirm) async {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Delete $itemName?",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          content: Text(
            "This action cannot be undone.",
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                "CANCEL",
                style: TextStyle(color: theme.hintColor, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context, true);
                onConfirm();
              },
              child: const Text(
                "DELETE",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassAlertAnimated extends StatefulWidget {
  final String message;
  final Color themeColor;
  final VoidCallback onDismiss;

  const _GlassAlertAnimated({
    required this.message,
    required this.themeColor,
    required this.onDismiss,
  });

  @override
  State<_GlassAlertAnimated> createState() => _GlassAlertAnimatedState();
}

class _GlassAlertAnimatedState extends State<_GlassAlertAnimated>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 2000), () async {
      if (mounted) {
        await _controller.reverse();
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 50),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
            decoration: BoxDecoration(
              color: widget.themeColor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: widget.themeColor.withValues(alpha: 0.4), blurRadius: 20)
              ],
            ),
            child: Text(
              widget.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteConfirmDialog extends StatelessWidget {
  final String itemName;

  const _DeleteConfirmDialog({required this.itemName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        "Delete $itemName?",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
      content: Text(
        "This action cannot be undone.",
        style: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            "CANCEL",
            style: TextStyle(color: theme.hintColor, fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            "DELETE",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}