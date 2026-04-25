import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:naviapp/providers/theme_provider.dart';
import 'package:naviapp/data/campus_landmarks.dart';

class MapSettings {
  static const String _mapTypeKey = 'map_type';
  static const String _followLocationKey = 'follow_location';
  static const String _showMarkersKey = 'show_markers';

  static int mapType = 3;
  static bool followLocation = true;
  static bool showMarkers = true;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    mapType = prefs.getInt(_mapTypeKey) ?? 3;
    followLocation = prefs.getBool(_followLocationKey) ?? true;
    showMarkers = prefs.getBool(_showMarkersKey) ?? true;
  }

  static Future<void> setMapType(int value) async {
    mapType = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_mapTypeKey, value);
  }

  static Future<void> setFollowLocation(bool value) async {
    followLocation = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_followLocationKey, value);
  }

  static Future<void> setShowMarkers(bool value) async {
    showMarkers = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showMarkersKey, value);
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _mapType = 3;
  bool _followLocation = true;
  bool _showMarkers = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await MapSettings.load();
    if (mounted) {
      setState(() {
        _mapType = MapSettings.mapType;
        _followLocation = MapSettings.followLocation;
        _showMarkers = MapSettings.showMarkers;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Map Preferences',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Customize your navigation experience',
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 24),
                _buildMapTypeSelector(theme, colorScheme),
                const SizedBox(height: 16),
                _buildToggleTile(
                  theme: theme,
                  colorScheme: colorScheme,
                  icon: Icons.my_location,
                  title: 'Follow Location',
                  subtitle: 'Auto-center map on your position',
                  value: _followLocation,
                  onChanged: (value) async {
                    await MapSettings.setFollowLocation(value);
                    setState(() => _followLocation = value);
                  },
                ),
                const SizedBox(height: 8),
                _buildToggleTile(
                  theme: theme,
                  colorScheme: colorScheme,
                  icon: Icons.place,
                  title: 'Show Markers',
                  subtitle: 'Display landmark markers on map',
                  value: _showMarkers,
                  onChanged: (value) async {
                    await MapSettings.setShowMarkers(value);
                    setState(() => _showMarkers = value);
                  },
                ),
                const SizedBox(height: 32),
                Text(
                  'Appearance',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Customize app appearance',
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 16),
                _buildToggleTile(
                  theme: theme,
                  colorScheme: colorScheme,
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark Mode',
                  subtitle: 'Switch to dark theme',
                  value: themeProvider.isDarkMode,
                  onChanged: (value) async {
                    await themeProvider.setDarkMode(value);
                  },
                ),
                const SizedBox(height: 32),
                Text(
                  'Campus Info',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoRow('College', 'Tangub City Global College', Icons.school),
                      const Divider(height: 24),
                      _buildInfoRow('Location', 'Tangub City, Misamis Occidental', Icons.location_on_outlined),
                      const Divider(height: 24),
                      _buildInfoRow('Total Landmarks', '${tcgcLandmarks.length} locations', Icons.place_outlined),
                      const Divider(height: 24),
                      _buildInfoRow('App Version', '1.0.0', Icons.info_outline),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionTitle(theme, 'Support'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildTile(
                        icon: Icons.help_outline,
                        title: 'Help & FAQ',
                        onTap: () => _showHelpFAQ(context),
                      ),
                      _buildTile(
                        icon: Icons.feedback_outlined,
                        title: 'Send Feedback',
                        onTap: () => _sendFeedback(context),
                      ),
                      _buildTile(
                        icon: Icons.info_outline,
                        title: 'About',
                        subtitle: 'Version 1.0.0',
                        onTap: () => _showAbout(context),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapTypeSelector(ThemeData theme, ColorScheme colorScheme) {
    final mapTypes = [
      ('Normal', 0, Icons.map),
      ('Satellite', 1, Icons.satellite),
      ('Terrain', 2, Icons.terrain),
      ('Hybrid', 3, Icons.layers),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.map, color: colorScheme.onPrimaryContainer, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Map Type', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: mapTypes.map((type) {
              final isSelected = _mapType == type.$2;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () async {
                      await MapSettings.setMapType(type.$2);
                      setState(() => _mapType = type.$2);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            type.$3,
                            color: isSelected ? Colors.white : colorScheme.onSurface,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type.$1,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? Colors.white : colorScheme.onSurface,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: colorScheme.onPrimaryContainer, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: colorScheme.onPrimaryContainer, size: 20),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.4)),
      onTap: onTap,
    );
  }

  void _showHelpFAQ(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Help & FAQ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  ExpansionTile(
                    title: const Text('How do I navigate the campus?'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Use the Map tab to view the campus. Tap on any landmark marker to see details and get walking directions. The blue route line will guide you to your destination.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: const Text('Can I use this offline?'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'The app requires an internet connection to load the map tiles and calculate routes. However, landmark information will still be visible when offline.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: const Text('How do I record a new landmark?'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Tap "Record Spot" from the home screen or the quick actions panel on the map. Walk to the location you want to save, then tap the record button to save your current GPS coordinates.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: const Text('What do the marker colors mean?'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Blue markers indicate buildings, orange markers show offices, violet markers are for labs, and cyan markers represent facilities. This color coding helps you quickly identify different types of campus locations.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: const Text('How do I change the map style?'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Go to Settings > Map Preferences > Map Type. You can choose between Normal, Satellite, Terrain, or Hybrid map views. Your preference will be saved and applied automatically.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendFeedback(BuildContext context) async {
    final emailUri = Uri(scheme: 'mailto', path: 'feedback@tcgc.edu.ph', query: 'subject=TCGC Guide App Feedback');
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email client not available'), behavior: SnackBarBehavior.floating));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open email: $e'), behavior: SnackBarBehavior.floating));
      }
    }
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('TCGC Guide'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0'),
            SizedBox(height: 8),
            Text('A specialized campus navigation app for Tangub City Global College.'),
            SizedBox(height: 16),
            Text('Navigate your way around TCGC campus with ease.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }
}