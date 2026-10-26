// lib/widgets/app_ui.dart
//
// Shared premium UI tokens + building blocks for the whole app.
//
// Palette is the established identity — deep campus green, warm neutrals,
// Poppins (via ThemeData) — used consistently here so every screen feels
// like one product. All helpers are light/dark aware.
import 'package:flutter/material.dart';

/// Brand + neutral palette (single source; screens must not hardcode
/// one-off greens/greys for chrome — use these).
class AppPalette {
  AppPalette._();

  /// Primary campus green.
  static const Color brand = Color(0xFF0A7040);

  /// Bright end of hero gradients.
  static const Color brandBright = Color(0xFF0E9F6E);

  /// Deep green for dark surfaces.
  static const Color pine = Color(0xFF1B2E20);

  /// Pine border in dark mode.
  static const Color pineBorder = Color(0xFF2B4A36);

  /// Headline ink (light mode).
  static const Color ink = Color(0xFF0E2B1C);

  /// Secondary text (light mode).
  static const Color inkSoft = Color(0xFF1E4934);

  /// Headline ink (dark mode).
  static const Color mist = Color(0xFFE7F4EA);

  /// Secondary text (dark mode).
  static const Color mistSoft = Color(0xFFA8C8B0);

  /// App scaffold tint (matches ThemeData).
  static Color scaffold(bool isDark) =>
      isDark ? const Color(0xFF0D1711) : const Color(0xFFF0F6EF);

  /// Card surface.
  static Color card(bool isDark) => isDark ? pine : Colors.white;

  /// Hairline border for cards.
  static Color cardBorder(bool isDark, [Color? accent]) => accent != null
      ? accent.withValues(alpha: 0.22)
      : (isDark ? pineBorder : const Color(0xFFB8DCC8));

  /// Icon tile tint behind a glyph.
  static Color tint(Color base, bool isDark) =>
      base.withValues(alpha: isDark ? 0.22 : 0.12);
}

/// Layered, soft shadows — cards float, overlays float higher.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get overlay => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.14),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
  ];
}

/// Corner radii used app-wide.
class AppRadius {
  AppRadius._();

  static const double card = 20;
  static const double tile = 16;
  static const double sheet = 28;
  static const double pill = 999;
}

/// Small caps section eyebrow, e.g. "NAVIGATE".
class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: isDark ? AppPalette.mistSoft : AppPalette.inkSoft,
      ),
    );
  }
}

/// Rounded tinted tile behind an icon glyph.
class TintIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  const TintIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 52,
    this.iconSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppPalette.tint(color, isDark),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}

/// Premium surface card: soft shadow + hairline border, theme aware.
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderAccent;
  final VoidCallback? onTap;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderAccent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = Container(
      decoration: BoxDecoration(
        color: AppPalette.card(isDark),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppPalette.cardBorder(isDark, borderAccent)),
        boxShadow: AppShadows.card,
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: card,
      ),
    );
  }
}

/// Floating overlay surface for map HUD (destination bar, banners).
class HudCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const HudCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.overlay,
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Bottom-sheet drag handle.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 5,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade600
            : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
  }
}

/// Green gradient hero header used on Home / Get Started.
class HeroHeader extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const HeroHeader({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppPalette.brand, AppPalette.brandBright],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Frosted-glass icon tile for use on green gradients.
class GlassIcon extends StatelessWidget {
  final IconData icon;
  final double size;

  const GlassIcon({super.key, required this.icon, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Icon(icon, size: size * 0.5, color: Colors.white),
    );
  }
}
