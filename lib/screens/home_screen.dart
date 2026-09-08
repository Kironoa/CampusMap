// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:naviapp/models/starting_location.dart';
import 'package:provider/provider.dart';
import 'package:naviapp/providers/theme_provider.dart';
import 'package:naviapp/providers/user_location_provider.dart';
import 'package:naviapp/screens/floor_plan_screen.dart';
import 'package:naviapp/screens/qr_admin_screen.dart';
import 'package:naviapp/screens/qr_scanner_screen.dart';
import 'package:naviapp/screens/ai_navigation_chat.dart';
import 'package:naviapp/ar/ar_mode_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: Image.asset(
          'assets/images/logo and icon.png',
          width: 24,
          height: 24,
        ),
        title: const Text(
          'TCGC Guide',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0A7040),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: 'Toggle dark mode',
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_2, color: Colors.white),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const QrAdminScreen())),
            tooltip: 'Starting point QR codes',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDark),
            const SizedBox(height: 24),
            Text(
              'NAVIGATE',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFFA8C8B0)
                    : const Color(0xFF1E4934),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            _buildNavCard(
              context: context,
              isDark: isDark,
              icon: Icons.qr_code_scanner,
              iconBgColor: const Color(0xFFEFF6FF),
              iconColor: const Color(0xFF2563EB),
              title: 'Scan Starting Point',
              subtitle: 'Scan a QR code where you are standing',
              borderColor: const Color(0xFF2563EB).withValues(alpha: 0.2),
              onTap: () => _scanStartingPoint(context),
            ),
            const SizedBox(height: 12),
            _buildNavCard(
              context: context,
              isDark: isDark,
              icon: Icons.map_outlined,
              iconBgColor: const Color(0xFFE7F4EA),
              iconColor: const Color(0xFF0A7040),
              title: 'Floor Plan',
              subtitle: 'Tap rooms • Zoom • Explore floors',
              borderColor: const Color(0xFF0A7040).withValues(alpha: 0.2),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FloorPlanScreen()),
              ),
            ),
            const SizedBox(height: 8),
            _buildNavCard(
              context: context,
              isDark: isDark,
              icon: Icons.chat,
              iconBgColor: const Color(0xFF0A7040),
              iconColor: Colors.white,
              title: 'AI Chat Navigator',
              subtitle: 'Talk to NaviApp • Natural language directions',
              borderColor: const Color(0xFF0A7040).withValues(alpha: 0.2),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AINavChatScreen()),
              ),
            ),
            const SizedBox(height: 24),
            IconButton(
              icon: const Icon(
                Icons.view_in_ar_outlined,
                color: Color(0xFF0E9F6E),
              ),
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ArModeScreen())),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Opens the QR scanner; on a valid Campus Guide code, pins the user's
  /// location and opens the Ground Floor plan with the marker placed.
  Future<void> _scanStartingPoint(BuildContext context) async {
    final location = await Navigator.of(context).push<StartingLocation>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (location == null || !context.mounted) return;

    context.read<UserLocationProvider>().setFromStartingLocation(location);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FloorPlanScreen(initialFloor: location.floor),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2E20) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2B4A36) : const Color(0xFFB8DCC8),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: const Row(
        children: [
          Icon(Icons.school, size: 48, color: Color(0xFF0A7040)),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tangub City Global College',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0E2B1C),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'AI-Powered Campus Navigation',
                  style: TextStyle(fontSize: 13, color: Color(0xFF1E4934)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavCard({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B2E20) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFE7F4EA)
                          : const Color(0xFF0E2B1C),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? const Color(0xFFA8C8B0)
                          : const Color(0xFF1E4934),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: iconColor),
          ],
        ),
      ),
    );
  }
}
