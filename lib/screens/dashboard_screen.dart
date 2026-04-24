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

  @override
  void initState() {
    super.initState();
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          ),
        ],
      ),
    );
  }

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
              : null,
        ),
      ),
    );
  }

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
              ),
            ),
          );
        },
      ),
    );
  }

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
        ),
      ),
    );
  }

  void _showFullMap() {
    Navigator.pushNamed(context, '/navigation');
  }

  void _showQRScanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR Scanner coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDirections(Map<String, dynamic> room) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Finding route to ${room['name']}...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}