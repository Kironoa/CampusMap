// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:naviapp/providers/theme_provider.dart';
import 'package:naviapp/providers/user_location_provider.dart';
import 'package:naviapp/screens/get_started_screen.dart';
import 'package:naviapp/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // .env is gitignored and may not exist on fresh clones/builds — a missing
  // file must not kill the app on first launch. Env.openrouterApiKey already
  // returns '' when dotenv was never loaded, and AI features fall back to
  // bundled text in that case.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // No .env (first clone, CI, keyless install) — continue without it.
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();
  runApp(
    NaviApp(
      themeProvider: themeProvider,
      userLocationProvider: UserLocationProvider(),
    ),
  );
}

class NaviApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  final UserLocationProvider userLocationProvider;

  const NaviApp({
    super.key,
    required this.themeProvider,
    required this.userLocationProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: userLocationProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'NaviApp',
            themeMode: themeProvider.themeMode,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            home: const GetStartedScreen(),
            routes: {'/home': (context) => const HomeScreen()},
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    const seed = Color(0xFF0A7040);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    // Apply Poppins once via the text theme for both light and dark.
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
    );
    final poppinsTextTheme = GoogleFonts.poppinsTextTheme(base.textTheme);
    return base.copyWith(
      colorScheme: colorScheme,
      textTheme: poppinsTextTheme,
      primaryTextTheme: poppinsTextTheme,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0D1711)
          : const Color(0xFFF0F6EF),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isDark ? const Color(0xFF1B2E20) : Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 64,
        backgroundColor: isDark ? const Color(0xFF1B2E20) : Colors.white,
        indicatorColor: const Color(
          0xFF0A7040,
        ).withValues(alpha: isDark ? 0.25 : 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          // Font family comes from ThemeData.textTheme (Poppins) — no hardcode.
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? const Color(0xFF0A7040)
                : (isDark ? const Color(0xFFA8C8B0) : const Color(0xFF1E4934)),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected
                ? const Color(0xFF0A7040)
                : (isDark ? const Color(0xFFA8C8B0) : const Color(0xFF1E4934)),
          );
        }),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 2000), () async {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: const Color(0xFF0A7040),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo and icon.png',
                    width: 52,
                    height: 52,
                    fit: BoxFit.contain,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'NaviApp',
                  style: textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your Campus Navigator',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 48),
                // Premium shimmer skeleton instead of a spinner.
                Shimmer.fromColors(
                  baseColor: Colors.white.withValues(alpha: 0.25),
                  highlightColor: Colors.white.withValues(alpha: 0.55),
                  child: Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
