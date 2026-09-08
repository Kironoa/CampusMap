// lib/screens/qr_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../config/starting_locations.dart';
import '../models/starting_location.dart';

/// Full-screen camera QR scanner for Campus Guide starting points.
///
/// Pops with a [StartingLocation] when a valid Campus Guide QR code is
/// scanned. Invalid codes show an error and never change the user's
/// current location.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  late final AnimationController _pulseController;
  bool _handling = false;

  static const String _invalidTitle = 'Invalid Campus Guide QR Code';
  static const String _invalidMessage =
      'Please scan a Campus Guide starting-point QR code.';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handling || !mounted) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) continue;

      final location = StartingLocations.fromQrData(raw);
      if (location != null) {
        setState(() => _handling = true);
        Navigator.of(context).pop(location);
        return;
      }

      // Unrelated / unknown code: report it but keep the current location
      // untouched and keep scanning after the dialog is dismissed.
      setState(() => _handling = true);
      _showInvalidDialog();
      return;
    }
  }

  Future<void> _showInvalidDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          size: 40,
          color: Color(0xFFDC2626),
        ),
        title: const Text(
          _invalidTitle,
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          _invalidMessage,
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Try Again',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
    if (mounted) {
      setState(() => _handling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final side = screenWidth * 0.72;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Scan Starting Point',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return _ScannerErrorView(message: error.errorCode.name);
            },
          ),
          // Scan-window frame.
          SizedBox(
            width: side,
            height: side,
            child: FadeTransition(
              opacity: Tween<double>(
                begin: 0.45,
                end: 1.0,
              ).animate(_pulseController),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF16A34A),
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          Positioned(
            left: 32,
            right: 32,
            bottom: 48,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Point the camera at a Campus Guide starting-point '
                'QR code near you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerErrorView extends StatelessWidget {
  final String message;
  const _ScannerErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              size: 56,
              color: Colors.white54,
            ),
            const SizedBox(height: 16),
            const Text(
              'Camera unavailable',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please allow camera access to scan starting-point QR codes.\n'
              '($message)',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
