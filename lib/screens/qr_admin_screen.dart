// lib/screens/qr_admin_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../config/starting_locations.dart';
import '../models/starting_location.dart';

/// Developer / admin screen that renders the QR code for every configured
/// starting location across all floors.
///
/// Print these and place each printed code at its physical spot. Every code
/// embeds a unique structured payload (see [StartingLocation.qrData]).
class QrAdminScreen extends StatelessWidget {
  const QrAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Starting Point QR Codes',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0A7040),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QrCodeSection(
            title: 'Ground Floor',
            locations: StartingLocations.groundFloorLocations,
            isDark: isDark,
          ),
          _QrCodeSection(
            title: '2nd Floor',
            locations: StartingLocations.secondFloorLocations,
            isDark: isDark,
          ),
          _QrCodeSection(
            title: '3rd Floor',
            locations: StartingLocations.thirdFloorLocations,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _QrCodeSection extends StatelessWidget {
  final String title;
  final List<StartingLocation> locations;
  final bool isDark;

  const _QrCodeSection({
    required this.title,
    required this.locations,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: isDark
                    ? const Color(0xFFE7F4EA)
                    : const Color(0xFF0E2B1C),
              ),
            ),
            const SizedBox(height: 8),
            ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: locations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final location = locations[index];
                return _QrCodeCard(
                  location: location,
                  isDark: isDark,
                  floorDisplay: _floorName(location.floor),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _floorName(int floor) {
    switch (floor) {
      case 0:
        return 'Ground Floor';
      case 1:
        return '2nd Floor';
      case 2:
        return '3rd Floor';
      default:
        return 'Floor $floor';
    }
  }
}

class _QrCodeCard extends StatelessWidget {
  final StartingLocation location;
  final bool isDark;
  final String floorDisplay;

  const _QrCodeCard({
    required this.location,
    required this.isDark,
    required this.floorDisplay,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? const Color(0xFF1B2E20) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF2B4A36) : const Color(0xFFB8DCC8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A7040).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.place_outlined,
                    color: Color(0xFF0A7040),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                          color: isDark
                              ? const Color(0xFFE7F4EA)
                              : const Color(0xFF0E2B1C),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${location.id} · $floorDisplay',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          color: isDark
                              ? const Color(0xFFA8C8B0)
                              : const Color(0xFF1E4934),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: location.qrData,
                version: QrVersions.auto,
                size: 180,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: location.qrData));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$location payload copied to clipboard'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.copy,
                      size: 14,
                      color: isDark
                          ? const Color(0xFFA8C8B0)
                          : const Color(0xFF1E4934),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        location.qrData,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: isDark
                              ? const Color(0xFFA8C8B0)
                              : const Color(0xFF1E4934),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
