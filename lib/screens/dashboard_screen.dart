<<<<<<< HEAD
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const String _favoritesKey = 'favorites';
  final List<Map<String, dynamic>> allRooms = [
    {'name': 'Moot Court', 'x': 0.15, 'y': 0.55, 'category': 'Offices', 'floor': '2nd'},
    {'name': 'Computer Lab', 'x': 0.25, 'y': 0.42, 'category': 'Labs', 'floor': '2nd'},
    {'name': 'Deans Office', 'x': 0.42, 'y': 0.65, 'category': 'Offices', 'floor': '2nd'},
    {'name': 'Registrar', 'x': 0.35, 'y': 0.30, 'category': 'Offices', 'floor': '1st'},
    {'name': 'Library', 'x': 0.60, 'y': 0.45, 'category': 'Academic', 'floor': '2nd'},
    {'name': 'Science Lab', 'x': 0.50, 'y': 0.25, 'category': 'Labs', 'floor': '1st'},
    {'name': 'Guidance Office', 'x': 0.20, 'y': 0.70, 'category': 'Offices', 'floor': '2nd'},
    {'name': 'Canteen', 'x': 0.75, 'y': 0.60, 'category': 'Services', 'floor': '1st'},
  ];

  List<Map<String, dynamic>> filteredRooms = [];
  Set<String> _favorites = {};
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  bool _showFavoritesOnly = false;
=======
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/models/schedule_model.dart';
import 'package:mobile_app/helper/db_helper.dart';
import 'package:mobile_app/screens/resource_screen.dart' hide res;
import 'package:mobile_app/screens/schedule_screen.dart' hide res;
import 'package:mobile_app/screens/settings_screen.dart';
import 'package:mobile_app/providers/theme_provider.dart';
import 'package:mobile_app/services/notification_service.dart';
import 'package:mobile_app/screens/notes_screen.dart' hide res;
import 'package:mobile_app/screens/assignments_screen.dart' hide res;
import 'package:mobile_app/screens/chat_screen.dart' hide res;
import 'package:mobile_app/screens/quizzes_screen.dart' hide res;
import 'package:mobile_app/screens/flashcards_screen.dart' hide res;
import 'package:mobile_app/screens/summaries_screen.dart' hide res;
import 'package:mobile_app/screens/login_screen.dart';

class LiveClockWidget extends StatefulWidget {
  final double Function(double) r;
  final Color accent;

  const LiveClockWidget({super.key, required this.r, required this.accent});

  @override
  State<LiveClockWidget> createState() => _LiveClockWidgetState();
}

class _LiveClockWidgetState extends State<LiveClockWidget> {
  late Timer _clockTimer;
  String _timeString = DateFormat('hh:mm:ss a').format(DateTime.now());
  String _dateString = DateFormat('EEE, MMM dd, yyyy').format(DateTime.now());
>>>>>>> 8a35f843624a455ebaf6c1defb4b1077f73e75bc

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    filteredRooms = allRooms;
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favList = prefs.getStringList(_favoritesKey) ?? [];
    setState(() => _favorites = favList.toSet());
  }

  Future<void> _toggleFavorite(String roomName) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favorites.contains(roomName)) {
        _favorites.remove(roomName);
      } else {
        _favorites.add(roomName);
      }
    });
    await prefs.setStringList(_favoritesKey, _favorites.toList());
  }

  void _filterSearch(String query) {
    setState(() {
      filteredRooms = allRooms.where((room) {
        final matchesQuery = query.isEmpty ||
            room['name'].toLowerCase().contains(query.toLowerCase());
        final matchesCategory = _selectedCategory == 'All' ||
            room['category'] == _selectedCategory;
        final matchesFavorite = !_showFavoritesOnly ||
            _favorites.contains(room['name']);
        return matchesQuery && matchesCategory && matchesFavorite;
      }).toList();
    });
=======
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _timeString = DateFormat('hh:mm:ss a').format(DateTime.now());
          _dateString = DateFormat('EEE, MMM dd, yyyy').format(DateTime.now());
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
>>>>>>> 8a35f843624a455ebaf6c1defb4b1077f73e75bc
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
<<<<<<< HEAD
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(theme, colorScheme)),
            SliverToBoxAdapter(child: _buildSearchBar(colorScheme)),
            SliverToBoxAdapter(child: _buildCategoryChips()),
            SliverToBoxAdapter(child: _buildQuickActions(theme, colorScheme)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Locations',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${filteredRooms.length} places',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            filteredRooms.isEmpty
                ? SliverFillRemaining(child: _buildEmptyState())
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildRoomCard(
                          filteredRooms[index],
                          theme,
                          colorScheme,
                        ),
                        childCount: filteredRooms.length,
                      ),
                    ),
                  ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TCGC Guide',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Find your way around campus',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (_favorites.isNotEmpty)
                Badge(
                  label: Text('${_favorites.length}'),
                  child: IconButton(
                    icon: Icon(
                      _showFavoritesOnly
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: _showFavoritesOnly
                          ? Colors.red
                          : colorScheme.onSurface,
                    ),
                    onPressed: () {
                      setState(() => _showFavoritesOnly = !_showFavoritesOnly);
                      _filterSearch(_searchController.text);
                    },
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () => _showQRScanner(),
              ),
            ],
=======
    final onSurface = theme.colorScheme.onSurface;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: onSurface.withValues(alpha: 0.1)),
      ),
      padding:
          EdgeInsets.symmetric(horizontal: widget.r(10), vertical: widget.r(6)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_timeString.split(' ')[0],
                  style: TextStyle(
                      color: onSurface,
                      fontSize: widget.r(11),
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace')),
              SizedBox(width: widget.r(3)),
              Text(_timeString.split(' ')[1],
                  style: TextStyle(
                      color: widget.accent,
                      fontSize: widget.r(8),
                      fontWeight: FontWeight.w900)),
            ],
          ),
          Text(_dateString.toUpperCase(),
              style: TextStyle(
                  color: onSurface.withValues(alpha: 0.6),
                  fontSize: widget.r(7),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class StudentDashboard extends ConsumerStatefulWidget {
  final int userId;
  const StudentDashboard({super.key, required this.userId});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard>
    with TickerProviderStateMixin {
  late Timer _classTimer;
  late AnimationController _bgAnimationController;
  late ScrollController _scrollController;
  String? _profileImagePath;

  final ImagePicker _picker = ImagePicker();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final NotificationService _notifService = NotificationService();

  List<Schedule> _todaySchedules = [];
  List<Map<String, dynamic>> _recentAssignments = [];
  Schedule? _currentClass;
  Schedule? _nextClass;

  void initState() {
    super.initState();
    _fetchUserData();
    _loadDashboardData();
    _scrollController = ScrollController(keepScrollOffset: true);
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  double res(BuildContext context, double value) => value;

  Future<void> _fetchUserData() async {
    final user = await _dbHelper.getUser(widget.userId);
    if (user != null) {
      if (user['profilePath'] != null) {
        setState(() => _profileImagePath = user['profilePath']);
      }
      final username = user['username'] as String?;
      if (username != null && username.isNotEmpty) {
        ref.read(themeProviderProvider).updateUsername(username);
      }
    }
  }

  DateTime _parseTime(String timeStr) {
    final now = DateTime.now();
    final trimmed = timeStr.trim();

    try {
      return DateFormat("h:mm a").parse(trimmed).copyWith(
            year: now.year,
            month: now.month,
            day: now.day,
          );
    } catch (_) {}

    try {
      return DateFormat("HH:mm").parse(trimmed).copyWith(
            year: now.year,
            month: now.month,
            day: now.day,
          );
    } catch (_) {}

    try {
      return DateFormat("h:mm").parse(trimmed).copyWith(
            year: now.year,
            month: now.month,
            day: now.day,
          );
    } catch (_) {}

    return now;
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
    debugPrint("Current time: $now");
    Schedule? foundCurrent;
    Schedule? foundNext;
    Duration minNextGap = const Duration(days: 1);

    for (var schedule in _todaySchedules) {
      final start = _parseTime(schedule.startTime);
      final end = _parseTime(schedule.endTime);
      debugPrint("Schedule ${schedule.subject}: start=$start, end=$end");
      if (now.isAfter(start) && now.isBefore(end)) {
        debugPrint("  -> Matched as current");
        foundCurrent = schedule;
      }
      if (start.isAfter(now)) {
        final gap = start.difference(now);
        debugPrint("  -> Gap: $gap");
        if (gap < minNextGap) {
          debugPrint("  -> New next (gap: $gap)");
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

  Future<void> _loadDashboardData() async {
    final allSchedules = await _dbHelper.getAllSchedules(widget.userId);
    DateTime now = DateTime.now();
    String currentDayName = DateFormat('EEEE').format(now).toLowerCase();
    final allAssignments = await _dbHelper.getAssignments(widget.userId);

    final dayMap = {
      'monday': ['monday', 'mon', 'm'],
      'tuesday': ['tuesday', 'tue', 't'],
      'wednesday': ['wednesday', 'wed', 'w'],
      'thursday': ['thursday', 'thu', 'th'],
      'friday': ['friday', 'fri', 'f'],
      'saturday': ['saturday', 'sat', 's'],
      'sunday': ['sunday', 'sun', 'su'],
    };
    final currentDayAliases = dayMap[currentDayName] ?? [];

    if (mounted) {
      setState(() {
        _todaySchedules = allSchedules.where((s) {
          final scheduleDays = s.days.toLowerCase();
          return currentDayAliases.any((alias) => scheduleDays.contains(alias));
        }).toList();
        _todaySchedules.sort(
          (a, b) => _parseTime(a.startTime).compareTo(_parseTime(b.startTime)),
        );
        _recentAssignments = allAssignments.take(3).toList();
      });
      _updateCurrentAndNextClass();
    }

    Future.wait(_todaySchedules.map((schedule) async {
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
    }));

    _classTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) {
        _updateCurrentAndNextClass();
      }
    });
  }

  String formatDeadline(String? raw) {
    if (raw == null || raw.isEmpty) return 'No date';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('MMM dd, yyyy hh:mm a').format(dt);
    } catch (_) {
      return raw;
    }
  }

  Color _getDeadlineColor(String? deadlineRaw, Color defaultColor) {
    if (deadlineRaw == null || deadlineRaw.isEmpty) return defaultColor;
    try {
      final deadline = DateTime.parse(deadlineRaw);
      final now = DateTime.now();
      final diff = deadline.difference(now);
      if (diff.isNegative) return Colors.red;
      if (diff.inHours <= 5) return Colors.red;
      if (diff.inHours <= 15) return Colors.orange;
      return Colors.green;
    } catch (_) {
      return defaultColor;
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return '';
    return s[0].toUpperCase() + s.substring(1);
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
      if (duration.inSeconds < 60) return "Starting now";
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
      var targetTime =
          DateTime(now.year, now.month, now.day, targetHour, targetMinute);
      if (targetTime.isBefore(now)) {
        targetTime = targetTime.add(const Duration(days: 1));
      }
      final duration = targetTime.difference(now);
      if (duration.isNegative) return "Completed";
      if (duration.inSeconds < 60) return "Ending now";
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      String h = duration.inHours > 0 ? "${twoDigits(duration.inHours)}h " : "";
      return "$h${twoDigits(duration.inMinutes.remainder(60))}m left";
    }
  }

  @override
  void dispose() {
    _classTimer.cancel();
    _scrollController.dispose();
    _bgAnimationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const StudentPalLogin()),
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
                  formatDeadline(assignment['deadline']), accent),
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
    final themeProvider = ref.watch(themeProviderProvider);
    final double scale = themeProvider.uiScale;
    double r(double v) => v * scale;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          RepaintBoundary(
            child: _buildBackground(dynamicAccent, r),
          ),
          SafeArea(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              cacheExtent: 500,
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor:
                      theme.scaffoldBackgroundColor.withValues(alpha: 0.4),
                  elevation: 0,
                  expandedHeight: r(90),
                  collapsedHeight: r(75),
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: EdgeInsets.zero,
                    centerTitle: true,
                    title: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: r(20), vertical: r(10)),
                      child: _buildFloatingHeader(dynamicAccent, r),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: r(20)),
                    child: SizedBox(height: r(10)),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: r(20)),
                    child:
                        _buildSectionTitle("Class Progress", dynamicAccent, r),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        EdgeInsets.only(left: r(20), right: r(20), top: r(15)),
                    child: RepaintBoundary(
                      child: _buildProgressRow(dynamicAccent, r),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        EdgeInsets.only(left: r(20), right: r(20), top: r(30)),
                    child: _buildSectionTitle(
                      "Today's Schedule",
                      dynamicAccent,
                      r,
                      trailing: "Manage",
                      onTrailingTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SchedulePage(userId: widget.userId),
                        ),
                      ).then((_) => _loadDashboardData()),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        EdgeInsets.only(left: r(20), right: r(20), top: r(15)),
                    child: RepaintBoundary(
                      child: _buildHorizontalSchedule(dynamicAccent, r),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        EdgeInsets.only(left: r(20), right: r(20), top: r(30)),
                    child: _buildSectionTitle(
                      "Assignments",
                      dynamicAccent,
                      r,
                      trailing: "View All",
                      onTrailingTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AssignmentsScreen(userId: widget.userId),
                        ),
                      ).then((_) => _loadDashboardData()),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        EdgeInsets.only(left: r(20), right: r(20), top: r(15)),
                    child: _recentAssignments.isEmpty
                        ? RepaintBoundary(
                            child: _buildAssignmentCard({
                              "title": "No Assignments",
                              "deadline": "Free day!"
                            }, dynamicAccent, r),
                          )
                        : Column(
                            children: _recentAssignments
                                .map(
                                  (a) => RepaintBoundary(
                                      child: _buildAssignmentCard(
                                          a, dynamicAccent, r)),
                                )
                                .toList(),
                          ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        EdgeInsets.only(left: r(20), right: r(20), top: r(30)),
                    child: _buildSectionTitle("Resources", dynamicAccent, r),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        EdgeInsets.only(left: r(20), right: r(20), top: r(15)),
                    child: RepaintBoundary(
                      child: _buildResourceTile(
                        "Study Notes",
                        Icons.note_alt_rounded,
                        "Manage your quick notes",
                        dynamicAccent,
                        r,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  NotesScreen(userId: widget.userId)),
                        ).then((_) => _loadDashboardData()),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(left: r(20), right: r(20)),
                    child: RepaintBoundary(
                      child: _buildResourceTile(
                        "Flashcards",
                        Icons.style_rounded,
                        "Review your active decks",
                        dynamicAccent,
                        r,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  FlashcardsScreen(userId: widget.userId)),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(left: r(20), right: r(20)),
                    child: RepaintBoundary(
                      child: _buildResourceTile(
                        "Sample Quizzes",
                        Icons.psychology_alt_rounded,
                        "Test your knowledge",
                        dynamicAccent,
                        r,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  QuizzesScreen(userId: widget.userId)),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(left: r(20), right: r(20)),
                    child: RepaintBoundary(
                      child: _buildResourceTile(
                        "Summaries",
                        Icons.article_outlined,
                        "Quick review of key points",
                        dynamicAccent,
                        r,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  SummariesScreen(userId: widget.userId)),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(left: r(20), right: r(20)),
                    child: RepaintBoundary(
                      child: _buildResourceTile(
                        "Library Access",
                        Icons.local_library_rounded,
                        "Digital archives available",
                        dynamicAccent,
                        r,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  ResourcesScreen(userId: widget.userId)),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: r(40)),
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
>>>>>>> 8a35f843624a455ebaf6c1defb4b1077f73e75bc
          ),
        ],
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: _filterSearch,
        decoration: InputDecoration(
          hintText: 'Search rooms, offices, labs...',
          prefixIcon: Icon(Icons.search, color: colorScheme.primary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterSearch('');
                  },
                )
=======
  Widget _buildFloatingHeader(Color accent, double Function(double) r) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final themeProvider = ref.watch(themeProviderProvider);
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
                      fontSize: r(9),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
              Text(_capitalize(themeProvider.username),
                  style: TextStyle(
                      color: onSurface,
                      fontSize: r(15),
                      fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1),
            ],
          ),
        ),
        LiveClockWidget(r: r, accent: accent),
        SizedBox(width: r(8)),
        _buildProfileAvatar(onSurface, accent, r),
      ],
    );
  }

  Widget _buildProfileAvatar(
      Color onSurface, Color accent, double Function(double) r) {
    final theme = Theme.of(context);
    return PopupMenuButton<int>(
      offset: Offset(0, r(45)),
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
        _buildPopupItem(1, Icons.image_outlined, "Change Photo", accent, r),
        _buildPopupItem(2, Icons.settings_rounded, "Settings", accent, r),
        const PopupMenuDivider(height: 1),
        _buildPopupItem(3, Icons.logout_rounded, "Logout", accent, r,
            isDestructive: true),
      ],
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            border:
                Border.all(color: accent.withValues(alpha: 0.2), width: 1.5)),
        child: CircleAvatar(
          radius: r(14),
          backgroundColor: accent.withValues(alpha: 0.1),
          backgroundImage: (_profileImagePath != null &&
                  File(_profileImagePath!).existsSync())
              ? FileImage(File(_profileImagePath!))
              : null,
          child: (_profileImagePath == null ||
                  !File(_profileImagePath!).existsSync())
              ? Icon(Icons.person_rounded, color: accent, size: r(16))
>>>>>>> 8a35f843624a455ebaf6c1defb4b1077f73e75bc
              : null,
        ),
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildCategoryChips() {
    final categories = [
      'All',
      'Offices',
      'Labs',
      'Academic',
      'Services',
      'Comfort Rooms',
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? category : 'All';
                });
                _filterSearch(_searchController.text);
              },
              showCheckmark: false,
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
=======
  PopupMenuItem<int> _buildPopupItem(int value, IconData icon, String title,
      Color accent, double Function(double) r,
      {bool isDestructive = false}) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon,
              color: isDestructive ? Colors.redAccent : accent, size: r(18)),
          SizedBox(width: r(12)),
          Text(title,
              style: TextStyle(
                  fontSize: r(13),
                  fontWeight: FontWeight.w600,
                  color: isDestructive ? Colors.redAccent : null)),
        ],
      ),
    );
  }

  Widget _buildBackground(Color accent, double Function(double) r) {
    return AnimatedBuilder(
      animation: _bgAnimationController,
      builder: (context, child) {
        return Stack(
          children: [
            _buildAnimatedBlob(
                Alignment(0.7 + 0.1 * (_bgAnimationController.value), -0.8),
                accent,
                r(350)),
            _buildAnimatedBlob(
                Alignment(-0.8, 0.6 + 0.1 * (_bgAnimationController.value)),
                accent,
                r(450)),
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

  Widget _buildSectionTitle(
      String title, Color accent, double Function(double) r,
      {String? trailing, VoidCallback? onTrailingTap}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(title,
            style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: r(20),
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
                        fontSize: r(13),
                        fontWeight: FontWeight.w800))),
          ),
      ],
    );
  }

  Widget _buildProgressRow(Color accent, double Function(double) r) {
    return Row(
      children: [
        Expanded(
            child: GestureDetector(
                child: _buildCountdownCard(
                    "CURRENT",
                    _currentClass?.subject ?? "Free Time",
                    _formatCountdown(_currentClass),
                    accent.withValues(alpha: 0.4),
                    r,
                    isActive: _currentClass != null))),
        SizedBox(width: r(14)),
        Expanded(
            child: GestureDetector(
                child: _buildCountdownCard(
                    "UPCOMING",
                    _nextClass?.subject ?? "None Scheduled",
                    _formatCountdown(_nextClass, isNext: true),
                    accent,
                    r,
                    isActive: true))),
      ],
    );
  }

  Widget _buildCountdownCard(String label, String className, String time,
      Color accent, double Function(double) r,
      {bool isActive = false}) {
    final theme = Theme.of(context);
    return _buildGlassContainer(
      borderColor: isActive ? accent.withValues(alpha: 0.4) : null,
      r: r,
      child: Padding(
        padding: EdgeInsets.all(r(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: accent,
                    fontSize: r(10),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5)),
            SizedBox(height: r(10)),
            Text(className,
                style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: r(15),
                    fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            SizedBox(height: r(4)),
            Text(time,
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: r(11),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalSchedule(Color accent, double Function(double) r) {
    final theme = Theme.of(context);
    if (_todaySchedules.isEmpty) {
      return _buildGlassContainer(
        r: r,
        child: Center(
            child: Padding(
                padding: EdgeInsets.all(r(20)),
                child: Text("No classes scheduled.",
                    style: TextStyle(
                        fontSize: r(14),
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface)))),
      );
    }
    return SizedBox(
      height: r(120),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _todaySchedules.length,
        itemBuilder: (context, index) {
          final item = _todaySchedules[index];
          final onSurface = theme.colorScheme.onSurface;
          return Padding(
            padding: EdgeInsets.only(right: r(12)),
            child: InkWell(
              onTap: () => _showSingleScheduleDetail(context, item, accent),
              borderRadius: BorderRadius.circular(16),
              child: _buildGlassContainer(
                width: r(140),
                r: r,
                child: Padding(
                  padding: EdgeInsets.all(r(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.subject,
                          style: TextStyle(
                              color: onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: r(13)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      SizedBox(height: r(4)),
                      Text("${item.displayStartTime} - ${item.displayEndTime}",
                          style: TextStyle(
                              color: onSurface.withValues(alpha: 0.6),
                              fontSize: r(10))),
                      SizedBox(height: r(8)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(item.room,
                            style: TextStyle(
                                color: accent,
                                fontSize: r(9),
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
>>>>>>> 8a35f843624a455ebaf6c1defb4b1077f73e75bc
              ),
            ),
          );
        },
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildQuickActions(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _actionCard(
              'Navigate',
              Icons.navigation,
              colorScheme.primary,
              () => Navigator.pushNamed(context, '/navigation'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _actionCard(
              'Record',
              Icons.add_location_alt,
              Colors.orange,
              () => Navigator.pushNamed(context, '/record'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _actionCard(
              'Full Map',
              Icons.map,
              Colors.green,
              () => _showFullMap(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(
    Map<String, dynamic> room,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isFavorite = _favorites.contains(room['name']);
    final categoryColor = _getCategoryColor(room['category']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showRoomDetails(room),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(room['category']),
                  color: categoryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room['name'],
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildTag(room['category'], categoryColor),
                        const SizedBox(width: 8),
                        _buildTag('Floor ${room['floor']}', colorScheme.outline),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : colorScheme.outline,
                ),
                onPressed: () => _toggleFavorite(room['name']),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No locations found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Offices':
        return Colors.blue;
      case 'Labs':
        return Colors.purple;
      case 'Academic':
        return Colors.green;
      case 'Services':
        return Colors.orange;
      case 'Comfort Rooms':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Offices':
        return Icons.business;
      case 'Labs':
        return Icons.computer;
      case 'Academic':
        return Icons.school;
      case 'Services':
        return Icons.store;
      case 'Comfort Rooms':
        return Icons.wc;
      default:
        return Icons.location_on;
    }
  }

  void _showRoomDetails(Map<String, dynamic> room) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryColor = _getCategoryColor(room['category']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getCategoryIcon(room['category']),
                    color: categoryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room['name'],
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildTag(room['category'], categoryColor),
                          const SizedBox(width: 8),
                          _buildTag('Floor ${room['floor']}', colorScheme.outline),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _favorites.contains(room['name'])
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: _favorites.contains(room['name'])
                        ? Colors.red
                        : colorScheme.outline,
                    size: 28,
                  ),
                  onPressed: () {
                    _toggleFavorite(room['name']);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Quick Actions',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/navigation');
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('Navigate'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showDirections(room);
                    },
                    icon: const Icon(Icons.directions_walk),
                    label: const Text('Directions'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
=======
  Widget _buildAssignmentCard(Map<String, dynamic> assignment, Color accent,
      double Function(double) r) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: r(10)),
      child: _buildGlassContainer(
        r: r,
        child: ListTile(
          onTap: () => _showAssignmentDetail(context, assignment, accent),
          contentPadding: EdgeInsets.symmetric(horizontal: r(15)),
          title: Text(
            assignment['title'] ?? "Untitled",
            style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: r(14)),
          ),
          subtitle: Text(
            "Due: ${formatDeadline(assignment['deadline'])}",
            style: TextStyle(
                color: _getDeadlineColor(assignment['deadline'], theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                fontSize: r(12)),
          ),
          trailing: Icon(Icons.chevron_right, color: accent),
>>>>>>> 8a35f843624a455ebaf6c1defb4b1077f73e75bc
        ),
      ),
    );
  }

<<<<<<< HEAD
  void _showFullMap() {
    Navigator.pushNamed(context, '/navigation');
  }

  void _showQRScanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR Scanner coming soon!'),
        behavior: SnackBarBehavior.floating,
=======
  Widget _buildResourceTile(String title, IconData icon, String sub,
      Color accent, double Function(double) r,
      {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: r(10)),
      child: _buildGlassContainer(
        r: r,
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: accent),
          title: Text(title,
              style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: r(14))),
          subtitle: Text(sub,
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: r(11))),
        ),
>>>>>>> 8a35f843624a455ebaf6c1defb4b1077f73e75bc
      ),
    );
  }

<<<<<<< HEAD
  void _showDirections(Map<String, dynamic> room) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Finding route to ${room['name']}...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
=======
  Widget _buildGlassContainer(
      {Widget? child,
      double? width,
      double borderRadius = 16,
      Color? borderColor,
      required double Function(double) r}) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
            color: borderColor ??
                theme.colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child ?? const SizedBox(),
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
>>>>>>> 8a35f843624a455ebaf6c1defb4b1077f73e75bc
