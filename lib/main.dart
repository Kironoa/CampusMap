import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_app/models/user_session.dart';
import 'package:mobile_app/screens/login_screen.dart';
import 'package:mobile_app/screens/dashboard_screen.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/notification_service.dart';
import 'package:mobile_app/services/theme_provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

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
    ProviderScope(
      child: ChangeNotifierProvider.value(
        value: themeProvider,
        child: StudentPalApp(),
      ),
    ),
  );
}

class StudentPalApp extends StatelessWidget {
  StudentPalApp({super.key});

  final AuthService _authService = AuthService();

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
      home: FutureBuilder<UserSession>(
        future: _authService.loadSession(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF00FF75)),
              ),
            );
          }

          final session = snapshot.data ?? UserSession.loggedOut;

          if (session.hasActiveUser) {
            return StudentDashboard(userId: session.userId!);
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
