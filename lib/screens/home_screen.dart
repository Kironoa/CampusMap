import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:naviapp/providers/theme_provider.dart';
import 'package:naviapp/screens/floor_plan_screen.dart';
import 'package:naviapp/widgets/ai_nav_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                  Icon(
                    Icons.school,
                    size: 48,
                    color: const Color(0xFFF97316),
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
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FloorPlanScreen(initialFloor: 0),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF3D2A10) : const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFED7AA),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.stairs,
                          size: 28,
                          color: Color(0xFFF97316),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ground Floor',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFFFFF7ED) : const Color(0xFF1C0A00),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '12 rooms',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFFFED7AA) : const Color(0xFF78350F),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Color(0xFFF97316)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FloorPlanScreen(initialFloor: 1),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF3E2000) : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFCC80),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.school_outlined,
                          size: 28,
                          color: Color(0xFFFF8C00),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '1st Floor',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFFFFF7ED) : const Color(0xFF1C0A00),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '22 rooms',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFFFED7AA) : const Color(0xFF78350F),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Color(0xFFFF8C00)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FloorPlanScreen(initialFloor: 2),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF14532D) : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFBBF7D0),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.business,
                          size: 28,
                          color: Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '2nd Floor',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFFFFF7ED) : const Color(0xFF1C0A00),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '34 rooms',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFFFED7AA) : const Color(0xFF78350F),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Color(0xFF16A34A)),
                      ],
                    ),
                  ),
                ),
              ],
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
