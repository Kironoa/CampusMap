import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:naviapp/data/campus_landmarks.dart';
import 'package:naviapp/screens/navigation_screen.dart';
import 'package:naviapp/screens/settings_screen.dart';

enum GpsStatus { searching, active, unavailable }

class HomeScreen extends StatefulWidget {
  final ValueNotifier<String> categoryFilter;
  final ValueNotifier<bool> searchOpen;

  const HomeScreen({
    super.key,
    required this.categoryFilter,
    required this.searchOpen,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(
            categoryFilter: widget.categoryFilter,
            searchOpen: widget.searchOpen,
            onMapTap: () => setState(() {
              _currentIndex = 1;
            }),
          ),
          NavigationScreen(
            categoryFilter: widget.categoryFilter,
            searchOpen: widget.searchOpen,
          ),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) =>
              setState(() => _currentIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Map',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  final ValueNotifier<String> categoryFilter;
  final ValueNotifier<bool> searchOpen;
  final VoidCallback onMapTap;

  const _HomeTab({
    required this.categoryFilter,
    required this.searchOpen,
    required this.onMapTap,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab>
    with SingleTickerProviderStateMixin {
  GpsStatus _gpsStatus = GpsStatus.searching;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
    _initGps();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initGps() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _gpsStatus = GpsStatus.unavailable);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _gpsStatus = GpsStatus.unavailable);
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() => _gpsStatus = GpsStatus.unavailable);
      return;
    }

    try {
      await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
      if (mounted) {
        setState(() => _gpsStatus = GpsStatus.active);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _gpsStatus = GpsStatus.unavailable);
      }
    }
  }

  int _getLandmarkCount(String filter) {
    if (filter == 'All' || filter.isEmpty) return tcgcLandmarks.length;
    return filterByCategory(filter).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(theme, colorScheme)),
          SliverToBoxAdapter(child: _buildSearchBar(theme, colorScheme)),
          SliverToBoxAdapter(child: _buildCategoryGrid(theme, colorScheme)),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    Color statusColor;
    String statusText;
    switch (_gpsStatus) {
      case GpsStatus.active:
        statusColor = Colors.green;
        statusText = 'GPS Active';
        break;
      case GpsStatus.searching:
        statusColor = Colors.orange;
        statusText = 'Locating...';
        break;
      case GpsStatus.unavailable:
        statusColor = Colors.red;
        statusText = 'GPS Unavailable';
        break;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tangub City Global College',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Campus Navigator',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor.withValues(
                              alpha: _pulseAnim.value,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const Positioned(
            right: -10,
            top: -10,
            child: Opacity(
              opacity: 0.1,
              child: Icon(Icons.map, size: 120, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                widget.onMapTap();
                widget.searchOpen.value = true;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Search campus locations...',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.place,
                  color: colorScheme.onPrimaryContainer,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${tcgcLandmarks.length}',
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(ThemeData theme, ColorScheme colorScheme) {
    final categories = [
      {
        'name': 'Buildings',
        'filter': 'Buildings',
        'icon': Icons.business_outlined,
        'color': const Color(0xFF2563EB),
      },
      {
        'name': 'Offices',
        'filter': 'Offices',
        'icon': Icons.meeting_room_outlined,
        'color': const Color(0xFFEA580C),
      },
      {
        'name': 'Labs',
        'filter': 'Labs',
        'icon': Icons.computer_outlined,
        'color': const Color(0xFF7C3AED),
      },
      {
        'name': 'Facilities',
        'filter': 'Facilities',
        'icon': Icons.sports_basketball_outlined,
        'color': const Color(0xFF059669),
      },
      {
        'name': 'All Locations',
        'filter': 'All',
        'icon': Icons.place_outlined,
        'color': const Color(0xFF0891B2),
      },
      {
        'name': 'Record Spot',
        'filter': '',
        'icon': Icons.add_location_alt_outlined,
        'color': const Color(0xFFDC2626),
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Browse Categories',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final count = category['filter'] == ''
                  ? ''
                  : _getLandmarkCount(category['filter'] as String).toString();

              return _CategoryTile(
                name: category['name'] as String,
                icon: category['icon'] as IconData,
                color: category['color'] as Color,
                count: count,
                isRecordSpot: (category['filter'] as String).isEmpty,
                onTap: () {
                  if (category['filter'] == '') {
                    Navigator.pushNamed(context, '/record');
                  } else {
                    widget.categoryFilter.value = category['filter'] as String;
                    widget.onMapTap();
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final String count;
  final bool isRecordSpot;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.name,
    required this.icon,
    required this.color,
    required this.count,
    required this.isRecordSpot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                count.isEmpty
                    ? 'Save a spot'
                    : '$count ${count == "1" ? "location" : "locations"}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
