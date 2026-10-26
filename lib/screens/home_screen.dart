// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:naviapp/models/starting_location.dart';
import 'package:provider/provider.dart';
import 'package:naviapp/providers/theme_provider.dart';
import 'package:naviapp/providers/user_location_provider.dart';
import 'package:naviapp/screens/floor_plan_screen.dart';
import 'package:naviapp/screens/qr_scanner_screen.dart';
import 'package:naviapp/features/live_navigation/live_navigation.dart'
    show LiveNavFeatureFlag;
import 'package:naviapp/features/live_navigation/ui/navigation_screen.dart'
    show LiveNavigationScreen;
import 'package:naviapp/widgets/app_ui.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 168,
            collapsedHeight: 64,
            leading: Padding(
              padding: const EdgeInsets.all(12),
              child: Image.asset(
                'assets/images/logo and icon.png',
                width: 24,
                height: 24,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  themeProvider.isDarkMode
                      ? Icons.light_mode
                      : Icons.dark_mode,
                  color: Colors.white,
                ),
                onPressed: () => themeProvider.toggleTheme(),
                tooltip: 'Toggle dark mode',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 64,
                bottom: 14,
              ),
              title: Text(
                'TCGC Guide',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A7040), Color(0xFF0E9F6E)],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, isDark)
                      .animate()
                      .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                      .slideY(
                        begin: 0.15,
                        end: 0,
                        duration: 400.ms,
                        curve: Curves.easeOut,
                      ),
                  const SizedBox(height: 24),
                  const SectionLabel(
                    'NAVIGATE',
                  ).animate().fadeIn(delay: 100.ms, duration: 350.ms),
                  const SizedBox(height: 12),
                  _buildNavCard(
                        context: context,
                        isDark: isDark,
                        icon: Icons.qr_code_scanner,
                        iconBgColor: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                        title: 'Scan Starting Point',
                        subtitle: 'Scan a QR code where you are standing',
                        borderColor: const Color(
                          0xFF2563EB,
                        ).withValues(alpha: 0.2),
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
                        borderColor: const Color(
                          0xFF0A7040,
                        ).withValues(alpha: 0.2),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FloorPlanScreen(),
                          ),
                        ),
                      ),
                  // Isolated entry point for Live Navigation.
                  // Hidden when the feature flag is off; nothing else on
                  // this screen depends on the feature.
                  if (LiveNavFeatureFlag.enabled) ...[
                    const SizedBox(height: 12),
                    _buildNavCard(
                          context: context,
                          isDark: isDark,
                          icon: Icons.navigation,
                          iconBgColor: const Color(0xFFE8F0FE),
                          iconColor: const Color(0xFF1A73E8),
                          title: 'Live Navigation',
                          subtitle: 'Live GPS • Routes • Turn-by-turn',
                          borderColor: const Color(
                            0xFF1A73E8,
                          ).withValues(alpha: 0.2),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LiveNavigationScreen(),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 400.ms)
                        .slideY(
                          begin: 0.2,
                          end: 0,
                          delay: 300.ms,
                          duration: 400.ms,
                          curve: Curves.easeOut,
                        ),
                  ],
                  const SizedBox(height: 12),
                  PremiumCard(
                    child: Row(
                      children: [
                        const TintIcon(
                          icon: Icons.lightbulb_outline,
                          color: Color(0xFF0A7040),
                          size: 44,
                          iconSize: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Walking into a peach building on the outdoor map? Accept the prompt to jump straight to its indoor floor plan.',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppPalette.mistSoft
                                      : AppPalette.inkSoft,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 450.ms, duration: 400.ms),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildHeader(BuildContext context, bool isDark) {
    final textTheme = Theme.of(context).textTheme;
    return HeroHeader(
      child: Row(
        children: [
          const GlassIcon(icon: Icons.school),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tangub City Global College',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI-Powered Campus Navigation',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 10),
                const Wrap(
                  spacing: 8,
                  children: [
                    _HeroChip(icon: Icons.domain, label: '3 buildings'),
                    _HeroChip(icon: Icons.layers_outlined, label: '3 floors'),
                  ],
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
    final textTheme = Theme.of(context).textTheme;
    // iconBgColor is kept for API compatibility; the tile tint derives from
    // the accent color so light/dark stay balanced automatically.
    return PremiumCard(
      borderAccent: borderColor,
      onTap: onTap,
      child: Row(
        children: [
          TintIcon(icon: icon, color: iconColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppPalette.mist : AppPalette.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: isDark ? AppPalette.mistSoft : AppPalette.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppPalette.tint(iconColor, isDark),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chevron_right, color: iconColor, size: 20),
          ),
        ],
      ),
    );
  }
}

/// Small frosted chip shown inside the hero header.
class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
