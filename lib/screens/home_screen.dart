// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:naviapp/providers/theme_provider.dart';
import 'package:naviapp/screens/floor_plan_screen.dart';
import 'package:naviapp/widgets/ai_nav_sheet.dart';
import 'package:naviapp/ar/ar_mode_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _floorData = [
    (index: 0, label: 'Ground / First Floor', rooms: '25 rooms', icon: Icons.stairs, color: Color(0xFF0A7040), bgDark: Color(0xFF0F3A22), bgLight: Color(0xFFE7F4EA), border: Color(0xFFB8DCC8)),
    (index: 1, label: 'Second Floor', rooms: '27 rooms', icon: Icons.business, color: Color(0xFF16A34A), bgDark: Color(0xFF14532D), bgLight: Color(0xFFF0FDF4), border: Color(0xFFBBF7D0)),
    (index: 2, label: 'Third Floor', rooms: '16 rooms', icon: Icons.apartment, color: Color(0xFF0E9F6E), bgDark: Color(0xFF0E4A36), bgLight: Color(0xFFE4F4EC), border: Color(0xFFB3DCC9)),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
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
                color: isDark ? const Color(0xFFA8C8B0) : const Color(0xFF1E4934),
                letterSpacing: 1.2,
              ),
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
            const SizedBox(height: 12),
            _buildNavCard(
              context: context,
              isDark: isDark,
              icon: Icons.psychology_outlined,
              iconBgColor: const Color(0xFFF0FDF4),
              iconColor: const Color(0xFF16A34A),
              title: 'AI Navigator',
              subtitle: 'Ask in English or Filipino',
              borderColor: const Color(0xFF16A34A).withValues(alpha: 0.2),
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AINavSheet(
                  currentFloorIndex: 0,
                  onNavigationResult: (pathOffsets, floorIndex, roomId) {},
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildNavCard(
              context: context,
              isDark: isDark,
              icon: Icons.view_in_ar_outlined,
              iconBgColor: const Color(0xFFE4F4EC),
              iconColor: const Color(0xFF0E9F6E),
              title: 'AR Navigation',
              subtitle: '3D arrows • Camera view',
              borderColor: const Color(0xFF0E9F6E).withValues(alpha: 0.2),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ArModeScreen(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'FLOORS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFA8C8B0) : const Color(0xFF1E4934),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                for (int i = 0; i < _floorData.length; i++) ...[
                  FloorCard(
                    floorIndex: _floorData[i].index,
                    label: _floorData[i].label,
                    rooms: _floorData[i].rooms,
                    icon: _floorData[i].icon,
                    color: _floorData[i].color,
                    bgDark: _floorData[i].bgDark,
                    bgLight: _floorData[i].bgLight,
                    borderColor: _floorData[i].border,
                  ),
                  if (i < _floorData.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
            const SizedBox(height: 24),
            _buildLegend(isDark),
            const SizedBox(height: 24),
          ],
        ),
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
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1E4934),
                  ),
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
                      color: isDark ? const Color(0xFFE7F4EA) : const Color(0xFF0E2B1C),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFFA8C8B0) : const Color(0xFF1E4934),
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

  Widget _buildLegend(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2E20) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2B4A36) : const Color(0xFFB8DCC8),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Room Categories',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFE7F4EA) : const Color(0xFF0E2B1C),
            ),
          ),
          const SizedBox(height: 12),
          _legendRow(const Color(0xFF0F766E), 'Academic / Labs'),
          const SizedBox(height: 8),
          _legendRow(const Color(0xFF0A7040), 'Offices'),
          const SizedBox(height: 8),
          _legendRow(const Color(0xFF16A34A), 'Facilities'),
          const SizedBox(height: 8),
          _legendRow(const Color(0xFF65A30D), 'Amenities'),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}

class FloorCard extends StatelessWidget {
  final int floorIndex;
  final String label;
  final String rooms;
  final IconData icon;
  final Color color;
  final Color bgDark;
  final Color bgLight;
  final Color borderColor;

  const FloorCard({
    required this.floorIndex,
    required this.label,
    required this.rooms,
    required this.icon,
    required this.color,
    required this.bgDark,
    required this.bgLight,
    required this.borderColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FloorPlanScreen(initialFloor: floorIndex),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? bgDark : bgLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFE7F4EA)
                          : const Color(0xFF0E2B1C),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rooms,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFFA8C8B0)
                          : const Color(0xFF1E4934),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}