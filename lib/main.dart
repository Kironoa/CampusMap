import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as pm;
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/models/user_session.dart';
import 'package:mobile_app/screens/login_screen.dart';
import 'package:mobile_app/screens/dashboard_screen.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/notification_service.dart';
import 'package:mobile_app/services/ai_service.dart';
import 'package:mobile_app/providers/theme_provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AIService.initialize();

  tz_data.initializeTimeZones();
  try {
    tz.setLocalLocation(tz.getLocation('Asia/Manila'));
  } catch (e) {
    debugPrint("Timezone Error: $e");
  }

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

    final notificationService = NotificationService();
    await notificationService.init();
    await notificationService.requestPermissions();
  }

  final themeProvider = ThemeProvider();

  runApp(
    ProviderScope(
      child: pm.ChangeNotifierProvider<ThemeProvider>.value(
        value: themeProvider,
        child: const StudentPalApp(),
      ),
    ),
  );
}

class StudentPalApp extends StatefulWidget {
  const StudentPalApp({super.key});

  @override
  State<StudentPalApp> createState() => _StudentPalAppState();
}

class _StudentPalAppState extends State<StudentPalApp> {
  late Future<UserSession> _sessionFuture;

  @override
  void initState() {
    super.initState();
    final authService = AuthService();
    _sessionFuture = authService.loadSession();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = pm.Provider.of<ThemeProvider>(context);
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
        future: _sessionFuture,
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