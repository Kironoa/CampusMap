import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_app/screens/login_screen.dart';
import 'package:mobile_app/screens/dashboard_screen.dart';
import 'package:mobile_app/services/notification_service.dart';
import 'package:mobile_app/services/theme_provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

// 1. Global Supabase Client Access
final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://yqwqjslktgeuajfzfhlt.supabase.co',
    anonKey: 'sb_publishable_EIOOJ-Knxp06CBWPUcI6Zw_T-r902ir',
  );

  // 3. Timezone Setup
  tz_data.initializeTimeZones();
  try {
    tz.setLocalLocation(tz.getLocation('Asia/Manila'));
  } catch (e) {
    debugPrint("Timezone Error: $e");
  }

  // 4. Load Theme & UI Scaling Settings
  final themeProvider = ThemeProvider();
  await themeProvider.loadSettings();

  // 5. Platform Specific Config (System UI & Notifications)
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } catch (e) {
      SystemChannels.platform
          .invokeMethod('SystemChrome.setEnabledSystemUIOverlays', []);
    }

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Initialize Local Notifications (Kept for your scheduling/reminders)
    final notificationService = NotificationService();
    await notificationService.init();
    await notificationService.requestPermissions();
  }

  runApp(
    ChangeNotifierProvider.value(
      value: themeProvider,
      child: const StudentPalApp(),
    ),
  );
}

class StudentPalApp extends StatelessWidget {
  const StudentPalApp({super.key});

  // Check Auth Status (Now updated for Supabase style or kept as Prefs)
  Future<Map<String, dynamic>> _checkAuth() async {
    // Option A: Keep using SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final int? userId = prefs.getInt('userId');

    // Option B: You can eventually use supabase.auth.currentSession != null
    return {'isLoggedIn': isLoggedIn, 'userId': userId};
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final baseTheme = themeProvider.currentTheme;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Pal',
      theme: baseTheme.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme),
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(themeProvider.uiScale),
          ),
          child: child!,
        );
      },
      home: FutureBuilder<Map<String, dynamic>>(
        future: _checkAuth(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF00FF75)),
              ),
            );
          }

          final bool isLoggedIn = snapshot.data?['isLoggedIn'] ?? false;
          final int? userId = snapshot.data?['userId'];

          if (isLoggedIn && userId != null) {
            return StudentDashboard(userId: userId);
          } else {
            return const Scaffold(
              resizeToAvoidBottomInset: false,
              body: StudentPalLogin(),
            );
          }
        },
      ),
    );
  }
}
