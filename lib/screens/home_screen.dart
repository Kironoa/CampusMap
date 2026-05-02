import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:naviapp/providers/theme_provider.dart';
import 'package:naviapp/screens/floor_plan_screen.dart';
import 'package:naviapp/widgets/ai_nav_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _floorData = [
    (index: 0, label: 'Ground / First Floor', rooms: '25 rooms', icon: Icons.stairs, color: Color(0xFFF97316), bgDark: Color(0xFF3D2A10), bgLight: Color(0xFFFFF7ED), border: Color(0xFFFED7AA)),
    (index: 1, label: 'Second Floor', rooms: '27 rooms', icon: Icons.business, color: Color(0xFF16A34A), bgDark: Color(0xFF14532D), bgLight: Color(0xFFF0FDF4), border: Color(0xFFBBF7D0)),
    (index: 2, label: 'Third Floor', rooms: '16 rooms', icon: Icons.apartment, color: Color(0xFF2563EB), bgDark: Color(0xFF1E3A5F), bgLight: Color(0xFFEFF6FF), border: Color(0xFF93C5FD)),
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
        backgroundColor: const Color(0xFFF97316),
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
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C1F0E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF3D2A10) : const Color(0xFFFED7AA),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.school,
                    size: 48,
                    color: Color(0xFFF97316),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tangub City Global College',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFFFF7ED) : const Color(0xFF1C0A00),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'AI-Powered Campus Navigation',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFFFED7AA) : const Color(0xFF78350F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'NAVIGATE',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFFED7AA) : const Color(0xFF78350F),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FloorPlanScreen(),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C1F0E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFF97316).withValues(alpha: 0.2),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.map_outlined,
                        size: 28,
                        color: Color(0xFFF97316),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Floor Plan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFFFF7ED) : const Color(0xFF1C0A00),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap rooms • Zoom • Explore floors',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? const Color(0xFFFED7AA) : const Color(0xFF78350F),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFFF97316),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const AINavSheet(),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C1F0E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.2),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.psychology_outlined,
                        size: 28,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Navigator',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFFFF7ED) : const Color(0xFF1C0A00),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ask in English or Filipino',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? const Color(0xFFFED7AA) : const Color(0xFF78350F),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF16A34A),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'FLOORS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFFED7AA) : const Color(0xFF78350F),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: _floorData.map((data) {
                return Column(
                  children: [
                    FloorCard(
                      floorIndex: data.index,
                      label: data.label,
                      rooms: data.rooms,
                      icon: data.icon,
                      color: data.color,
                      bgDark: data.bgDark,
                      bgLight: data.bgLight,
                      borderColor: data.border,
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }).toList()
                ..removeLast(),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C1F0E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF3D2A10) : const Color(0xFFFED7AA),
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
                      color: isDark ? const Color(0xFFFFF7ED) : const Color(0xFF1C0A00),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _legendRow(const Color(0xFF2563EB), 'Academic / Labs'),
                  const SizedBox(height: 8),
                  _legendRow(const Color(0xFFF97316), 'Offices'),
                  const SizedBox(height: 8),
                  _legendRow(const Color(0xFF16A34A), 'Facilities'),
                  const SizedBox(height: 8),
                  _legendRow(const Color(0xFF7C3AED), 'Amenities'),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
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
          color: Theme.of(context).brightness == Brightness.dark ? bgDark : bgLight,
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
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFFFF7ED)
                          : const Color(0xFF1C0A00),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rooms,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFFED7AA)
                          : const Color(0xFF78350F),
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
