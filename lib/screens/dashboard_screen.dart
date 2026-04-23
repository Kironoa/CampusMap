import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/models/schedule_model.dart';
import 'package:mobile_app/helper/db_helper.dart';
import 'package:mobile_app/screens/resource_screen.dart';
import 'package:mobile_app/screens/schedule_screen.dart';
import 'package:mobile_app/screens/settings_screen.dart';
import 'package:mobile_app/services/theme_provider.dart';
import 'package:mobile_app/services/notification_service.dart';
import 'package:mobile_app/screens/notes_screen.dart';
import 'package:mobile_app/screens/assignments_screen.dart';
import 'package:mobile_app/screens/login_screen.dart';
import 'package:mobile_app/screens/chat_screen.dart';
import 'package:mobile_app/screens/quizzes_screen.dart';
import 'package:mobile_app/screens/flashcards_screen.dart';
import 'package:mobile_app/screens/summaries_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const StudentPalApp(),
    ),
  );
}

double res(BuildContext context, double value) {
  return value * Provider.of<ThemeProvider>(context, listen: false).uiScale;
}

class StudentPalApp extends StatelessWidget {
  const StudentPalApp({super.key});

  Future<Map<String, dynamic>> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final int? userId = prefs.getInt('userId');
    return {'isLoggedIn': isLoggedIn, 'userId': userId};
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Pal',
      theme: themeProvider.currentTheme,
      home: FutureBuilder<Map<String, dynamic>>(
        future: _checkAuthStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }

          final bool isLoggedIn = snapshot.data?['isLoggedIn'] ?? false;
          final int? userId = snapshot.data?['userId'];

          if (isLoggedIn && userId != null) {
            return StudentDashboard(userId: userId);
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(res(context, 20)),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: theme.colorScheme.primary,
                  size: res(context, 64),
                ),
              ),
              SizedBox(height: res(context, 24)),
              Text(
                "Logged Out Successfully",
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: res(context, 16),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: res(context, 48)),
              Text(
                "Student Pal",
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: res(context, 36),
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: res(context, 40)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: res(context, 60),
                    vertical: res(context, 18),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StudentPalLogin(),
                  ),
                ),
                child: Text(
                  "LOGIN",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: res(context, 14),
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudentDashboard extends StatefulWidget {
  final int userId;
  const StudentDashboard({super.key, required this.userId});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with TickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _bgAnimationController;
  String? _profileImagePath;

  final ImagePicker _picker = ImagePicker();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final NotificationService _notifService = NotificationService();

  List<Schedule> _todaySchedules = [];
  List<Map<String, dynamic>> _recentAssignments = [];
  Schedule? _currentClass;
  Schedule? _nextClass;

  String _timeString = DateFormat('hh:mm:ss a').format(DateTime.now());
  String _dateString = DateFormat('EEE, MMM dd, yyyy').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadDashboardData();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  Future<void> _fetchUserData() async {
    final user = await _dbHelper.getUser(widget.userId);
    if (user != null && user['profilePath'] != null) {
      setState(() => _profileImagePath = user['profilePath']);
    }
  }

  DateTime _parseTime(String timeStr) {
    try {
      final now = DateTime.now();
      final parts = timeStr.trim().split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      final period = parts[1].toUpperCase();
      if (period == "PM" && hour < 12) hour += 12;
      if (period == "AM" && hour == 12) hour = 0;
      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (e) {
      return DateTime.now();
    }
  }

  Future<void> _loadDashboardData() async {
    final allSchedules = await _dbHelper.getAllSchedules(widget.userId);
    DateTime now = DateTime.now();
    String currentDayName = DateFormat('EEEE').format(now);
    final allAssignments = await _dbHelper.getAssignments(widget.userId);

    if (mounted) {
      setState(() {
        _todaySchedules = allSchedules.where((s) {
          String scheduleDays = s.days.toUpperCase();
          return scheduleDays.contains(currentDayName.toUpperCase()) ||
              scheduleDays.contains(currentDayName[0].toUpperCase());
        }).toList();
        _todaySchedules.sort(
          (a, b) => _parseTime(a.startTime).compareTo(_parseTime(b.startTime)),
        );
        _recentAssignments = allAssignments.take(3).toList();
      });
      _updateCurrentAndNextClass();
    }

    for (var schedule in _todaySchedules) {
      try {
        final DateTime scheduledTime = _parseTime(schedule.startTime);
        await _notifService.scheduleClassAlerts(
          id: schedule.id ?? 0,
          subject: schedule.subject,
          startTime: scheduledTime,
        );
      } catch (e) {
        debugPrint("Failed to schedule ${schedule.subject}: $e");
      }
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeString = DateFormat('hh:mm:ss a').format(DateTime.now());
          _dateString = DateFormat('EEE, MMM dd, yyyy').format(DateTime.now());
        });
        _updateCurrentAndNextClass();
      }
    });
  }

  void _updateCurrentAndNextClass() {
    if (_todaySchedules.isEmpty) {
      setState(() {
        _currentClass = null;
        _nextClass = null;
      });
      return;
    }
    final now = DateTime.now();
    Schedule? foundCurrent;
    Schedule? foundNext;
    Duration minNextGap = const Duration(days: 1);

    for (var schedule in _todaySchedules) {
      final start = _parseTime(schedule.startTime);
      final end = _parseTime(schedule.endTime);
      if (now.isAfter(start) && now.isBefore(end)) foundCurrent = schedule;
      if (start.isAfter(now)) {
        final gap = start.difference(now);
        if (gap < minNextGap) {
          minNextGap = gap;
          foundNext = schedule;
        }
      }
    }
    setState(() {
      _currentClass = foundCurrent;
      _nextClass = foundNext;
    });
  }

  String _formatCountdown(Schedule? schedule, {bool isNext = false}) {
    if (schedule == null) {
      return isNext ? "No upcoming classes" : "No class active";
    }
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    
    if (isNext) {
      final target = _parseTime(schedule.startTime);
      final duration = target.difference(now);
      if (duration.isNegative) return "Completed";
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      String h = duration.inHours > 0 ? "${twoDigits(duration.inHours)}h " : "";
      return "In $h${twoDigits(duration.inMinutes.remainder(60))}m";
    } else {
      int endMinutes = schedule.endMinutes;
      final startMinutes = schedule.startMinutes;
      if (endMinutes < startMinutes) {
        if (currentMinutes >= startMinutes) {
          endMinutes += 1440;
        }
      }
      int targetHour = endMinutes ~/ 60;
      int targetMinute = endMinutes % 60;
      var targetTime = DateTime(now.year, now.month, now.day, targetHour, targetMinute);
      if (targetTime.isBefore(now)) {
        targetTime = targetTime.add(const Duration(days: 1));
      }
      final duration = targetTime.difference(now);
      if (duration.isNegative) return "Completed";
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      String h = duration.inHours > 0 ? "${twoDigits(duration.inHours)}h " : "";
      return "$h${twoDigits(duration.inMinutes.remainder(60))}m left";
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _bgAnimationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      await _dbHelper.updateUserProfilePhoto(widget.userId, pickedFile.path);
      setState(() => _profileImagePath = pickedFile.path);
    }
  }

  void _showSingleScheduleDetail(
      BuildContext context, Schedule schedule, Color accent) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            schedule.subject,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPopupDetailRow(Icons.access_time_filled_rounded, "Time",
                  "${schedule.startTime} - ${schedule.endTime}", accent),
              SizedBox(height: res(context, 12)),
              _buildPopupDetailRow(
                  Icons.location_on_rounded, "Room", schedule.room, accent),
              SizedBox(height: res(context, 12)),
              _buildPopupDetailRow(
                  Icons.calendar_today_rounded, "Days", schedule.days, accent),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Close",
                  style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // POPUP DIALOG FOR ASSIGNMENTS
  void _showAssignmentDetail(
      BuildContext context, Map<String, dynamic> assignment, Color accent) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            assignment['title'] ?? "Assignment",
            style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPopupDetailRow(Icons.event_note_rounded, "Deadline",
                  assignment['deadline'] ?? "No deadline set", accent),
              if (assignment['description'] != null) ...[
                SizedBox(height: res(context, 12)),
                Text("Description",
                    style: TextStyle(
                        fontSize: res(context, 10),
                        color: Colors.grey,
                        fontWeight: FontWeight.bold)),
                Text(assignment['description'],
                    style: TextStyle(fontSize: res(context, 14))),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Close",
                  style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPopupDetailRow(
      IconData icon, String label, String value, Color accent) {
    return Row(
      children: [
        Icon(icon, color: accent, size: res(context, 20)),
        SizedBox(width: res(context, 10)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: res(context, 10),
                    color: Colors.grey,
                    fontWeight: FontWeight.bold)),
            Text(value,
                style: TextStyle(
                    fontSize: res(context, 14), fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color dynamicAccent = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          _buildBackground(dynamicAccent),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor:
                      theme.scaffoldBackgroundColor.withValues(alpha: 0.4),
                  elevation: 0,
                  expandedHeight: res(context, 90),
                  collapsedHeight: res(context, 75),
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: EdgeInsets.zero,
                    centerTitle: true,
                    title: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: res(context, 20),
                          vertical: res(context, 10)),
                      child: _buildFloatingHeader(
                          dynamicAccent, context.read<ThemeProvider>()),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: res(context, 20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: res(context, 10)),
                        _buildSectionTitle("Class Progress", dynamicAccent),
                        SizedBox(height: res(context, 15)),
                        _buildProgressRow(dynamicAccent),
                        SizedBox(height: res(context, 30)),
                        _buildSectionTitle(
                          "Today's Schedule",
                          dynamicAccent,
                          trailing: "Manage",
                          onTrailingTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SchedulePage(userId: widget.userId),
                            ),
                          ).then((_) => _loadDashboardData()),
                        ),
                        SizedBox(height: res(context, 15)),
                        _buildHorizontalSchedule(dynamicAccent),
                        SizedBox(height: res(context, 30)),
                        _buildSectionTitle(
                          "Assignments",
                          dynamicAccent,
                          trailing: "View All",
                          onTrailingTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AssignmentsScreen(userId: widget.userId),
                            ),
                          ).then((_) => _loadDashboardData()),
                        ),
                        SizedBox(height: res(context, 15)),
                        if (_recentAssignments.isEmpty)
                          _buildAssignmentCard({
                            "title": "No Assignments",
                            "deadline": "Free day!"
                          }, dynamicAccent)
                        else
                          ..._recentAssignments.map(
                              (a) => _buildAssignmentCard(a, dynamicAccent)),
                        SizedBox(height: res(context, 30)),
                        _buildSectionTitle("Resources", dynamicAccent),
                        SizedBox(height: res(context, 15)),
                        _buildResourceTile(
                          "Study Notes",
                          Icons.note_alt_rounded,
                          "Manage your quick notes",
                          dynamicAccent,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    NotesScreen(userId: widget.userId)),
                          ).then((_) => _loadDashboardData()),
                        ),
                        _buildResourceTile(
                          "Flashcards",
                          Icons.style_rounded,
                          "Review your active decks",
                          dynamicAccent,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    FlashcardsScreen(userId: widget.userId)),
                          ),
                        ),
                        _buildResourceTile(
                          "Sample Quizzes",
                          Icons.psychology_alt_rounded,
                          "Test your knowledge",
                          dynamicAccent,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    QuizzesScreen(userId: widget.userId)),
                          ),
                        ),
                        _buildResourceTile(
                          "Summaries",
                          Icons.article_outlined,
                          "Quick review of key points",
                          dynamicAccent,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    SummariesScreen(userId: widget.userId)),
                          ),
                        ),
                        _buildResourceTile(
                          "Library Access",
                          Icons.local_library_rounded,
                          "Digital archives available",
                          dynamicAccent,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    ResourcesScreen(userId: widget.userId)),
                          ),
                        ),
                        SizedBox(height: res(context, 40)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          AIFloatingChatHead(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                useSafeArea: true,
                builder: (context) => const ChatScreen(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingHeader(Color accent, ThemeProvider themeProvider) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Hello!",
                  style: TextStyle(
                      color: accent,
                      fontSize: res(context, 9),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
              Text(themeProvider.username,
                  style: TextStyle(
                      color: onSurface,
                      fontSize: res(context, 15),
                      fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        _buildCompactClock(accent),
        SizedBox(width: res(context, 8)),
        _buildProfileAvatar(onSurface, accent),
      ],
    );
  }

  Widget _buildProfileAvatar(Color onSurface, Color accent) {
    final theme = Theme.of(context);
    return PopupMenuButton<int>(
      offset: Offset(0, res(context, 45)),
      color: theme.cardColor,
      elevation: 8,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: onSurface.withValues(alpha: 0.05))),
      onSelected: (value) {
        if (value == 1) _pickImage();
        if (value == 2)
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()));
        if (value == 3) _handleLogout();
      },
      itemBuilder: (context) => [
        _buildPopupItem(1, Icons.image_outlined, "Change Photo", accent),
        _buildPopupItem(2, Icons.settings_rounded, "Settings", accent),
        const PopupMenuDivider(height: 1),
        _buildPopupItem(3, Icons.logout_rounded, "Logout", accent,
            isDestructive: true),
      ],
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            border:
                Border.all(color: accent.withValues(alpha: 0.2), width: 1.5)),
        child: CircleAvatar(
          radius: res(context, 14),
          backgroundColor: accent.withValues(alpha: 0.1),
          backgroundImage: (_profileImagePath != null &&
                  File(_profileImagePath!).existsSync())
              ? FileImage(File(_profileImagePath!))
              : null,
          child: (_profileImagePath == null ||
                  !File(_profileImagePath!).existsSync())
              ? Icon(Icons.person_rounded,
                  color: accent, size: res(context, 16))
              : null,
        ),
      ),
    );
  }

  PopupMenuItem<int> _buildPopupItem(
      int value, IconData icon, String title, Color accent,
      {bool isDestructive = false}) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon,
              color: isDestructive ? Colors.redAccent : accent,
              size: res(context, 18)),
          SizedBox(width: res(context, 12)),
          Text(title,
              style: TextStyle(
                  fontSize: res(context, 13),
                  fontWeight: FontWeight.w600,
                  color: isDestructive ? Colors.redAccent : null)),
        ],
      ),
    );
  }

  Widget _buildCompactClock(Color accent) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return _buildGlassContainer(
      borderRadius: 12,
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: res(context, 10), vertical: res(context, 6)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_timeString.split(' ')[0],
                    style: TextStyle(
                        color: onSurface,
                        fontSize: res(context, 11),
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace')),
                SizedBox(width: res(context, 3)),
                Text(_timeString.split(' ')[1],
                    style: TextStyle(
                        color: accent,
                        fontSize: res(context, 8),
                        fontWeight: FontWeight.w900)),
              ],
            ),
            Text(_dateString.toUpperCase(),
                style: TextStyle(
                    color: onSurface.withValues(alpha: 0.6),
                    fontSize: res(context, 7),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(Color accent) {
    return AnimatedBuilder(
      animation: _bgAnimationController,
      builder: (context, child) {
        return Stack(
          children: [
            _buildAnimatedBlob(
                Alignment(0.7 + 0.1 * (_bgAnimationController.value), -0.8),
                accent,
                res(context, 350)),
            _buildAnimatedBlob(
                Alignment(-0.8, 0.6 + 0.1 * (_bgAnimationController.value)),
                accent,
                res(context, 450)),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedBlob(Alignment align, Color color, double size) {
    return Align(
      alignment: align,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              color.withValues(alpha: 0.12),
              color.withValues(alpha: 0)
            ])),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color accent,
      {String? trailing, VoidCallback? onTrailingTap}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(title,
            style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: res(context, 20),
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5)),
        if (trailing != null)
          InkWell(
            onTap: onTrailingTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(trailing,
                    style: TextStyle(
                        color: accent,
                        fontSize: res(context, 13),
                        fontWeight: FontWeight.w800))),
          ),
      ],
    );
  }

  Widget _buildProgressRow(Color accent) {
    return Row(
      children: [
        Expanded(
            child: _buildCountdownCard(
                "CURRENT",
                _currentClass?.subject ?? "Free Time",
                _formatCountdown(_currentClass),
                accent.withValues(alpha: 0.4),
                isActive: _currentClass != null)),
        SizedBox(width: res(context, 14)),
        Expanded(
            child: _buildCountdownCard(
                "UPCOMING",
                _nextClass?.subject ?? "None Scheduled",
                _formatCountdown(_nextClass, isNext: true),
                accent,
                isActive: true)),
      ],
    );
  }

  Widget _buildCountdownCard(
      String label, String className, String time, Color accent,
      {bool isActive = false}) {
    final theme = Theme.of(context);
    return _buildGlassContainer(
      borderColor: isActive ? accent.withValues(alpha: 0.4) : null,
      child: Padding(
        padding: EdgeInsets.all(res(context, 18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: accent,
                    fontSize: res(context, 10),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5)),
            SizedBox(height: res(context, 10)),
            Text(className,
                style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: res(context, 15),
                    fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            SizedBox(height: res(context, 4)),
            Text(time,
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: res(context, 11),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalSchedule(Color accent) {
    final theme = Theme.of(context);
    if (_todaySchedules.isEmpty) {
      return _buildGlassContainer(
        child: Center(
            child: Padding(
                padding: EdgeInsets.all(res(context, 20)),
                child: Text("No classes scheduled.",
                    style: TextStyle(
                        fontSize: res(context, 14),
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface)))),
      );
    }
    return SizedBox(
      height: res(context, 120),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _todaySchedules.length,
        itemBuilder: (context, index) {
          final item = _todaySchedules[index];
          final onSurface = theme.colorScheme.onSurface;
          return Padding(
            padding: EdgeInsets.only(right: res(context, 12)),
            child: GestureDetector(
              onTap: () => _showSingleScheduleDetail(context, item, accent),
              child: _buildGlassContainer(
                width: res(context, 140),
                child: Padding(
                  padding: EdgeInsets.all(res(context, 12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.subject,
                          style: TextStyle(
                              color: onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: res(context, 13)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      SizedBox(height: res(context, 4)),
                      Text("${item.displayStartTime} - ${item.displayEndTime}",
                          style: TextStyle(
                              color: onSurface.withValues(alpha: 0.6),
                              fontSize: res(context, 10))),
                      SizedBox(height: res(context, 8)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(item.room,
                            style: TextStyle(
                                color: accent,
                                fontSize: res(context, 9),
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // MODIFIED METHOD: ASSIGNMENTS ARE NOW CLICKABLE
  Widget _buildAssignmentCard(Map<String, dynamic> assignment, Color accent) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: res(context, 10)),
      child: _buildGlassContainer(
        child: ListTile(
          onTap: () => _showAssignmentDetail(
              context, assignment, accent), // ACTION ON TAP
          contentPadding: EdgeInsets.symmetric(horizontal: res(context, 15)),
          title: Text(
            assignment['title'] ?? "Untitled",
            style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: res(context, 14)),
          ),
          subtitle: Text(
            "Due: ${assignment['deadline'] ?? 'No date'}",
            style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: res(context, 12)),
          ),
          trailing: Icon(Icons.chevron_right, color: accent),
        ),
      ),
    );
  }

  Widget _buildResourceTile(
      String title, IconData icon, String sub, Color accent,
      {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: res(context, 10)),
      child: _buildGlassContainer(
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: accent),
          title: Text(title,
              style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: res(context, 14))),
          subtitle: Text(sub,
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: res(context, 11))),
        ),
      ),
    );
  }

  Widget _buildGlassContainer(
      {Widget? child,
      double? width,
      double borderRadius = 16,
      Color? borderColor}) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
            color: borderColor ??
                theme.colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: RepaintBoundary(
          child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: child ?? const SizedBox()),
        ),
      ),
    );
  }
}

class AIFloatingChatHead extends StatelessWidget {
  final VoidCallback onPressed;
  const AIFloatingChatHead({super.key, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: FloatingActionButton(
          heroTag: "ai_chat_btn",
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 6,
          onPressed: onPressed,
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 30)),
    );
  }
}
