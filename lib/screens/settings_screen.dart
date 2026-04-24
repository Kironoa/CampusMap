import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:provider/provider.dart';
import 'package:naviapp/providers/theme_provider.dart';
=======
import 'package:mobile_app/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/themes/app_themes.dart';
import 'package:mobile_app/widgets/about.dart';
>>>>>>> 8a35f843624a455ebaf6c1defb4b1077f73e75bc

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

<<<<<<< HEAD
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Customize your experience',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildSection(
                context,
                title: 'Appearance',
                children: [
                  _buildThemeToggle(context),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: _buildSection(
                context,
                title: 'Campus',
                children: [
                  _buildSettingsTile(
                    context,
                    icon: Icons.location_on_outlined,
                    title: 'Campus Location',
                    subtitle: 'Tangub City Global College',
                    onTap: () {},
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.layers_outlined,
                    title: 'Floor Plan',
                    subtitle: '2nd Floor',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: _buildSection(
                context,
                title: 'Support',
                children: [
                  _buildSettingsTile(
                    context,
                    icon: Icons.help_outline,
                    title: 'Help & FAQ',
                    subtitle: 'Get help with navigation',
                    onTap: () {},
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.feedback_outlined,
                    title: 'Send Feedback',
                    subtitle: 'Help us improve the app',
                    onTap: () {},
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: 'Version 1.0.0',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
=======
  double res(BuildContext context, double value) {
    final provider = Provider.of<ThemeProvider>(context, listen: false);
    return value * provider.uiScale;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final themeProvider = Provider.of<ThemeProvider>(context);

    final primaryColor = themeProvider.currentAccentColor;

    final double scale = themeProvider.uiScale;

    final bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "SETTINGS",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: res(context, 12),
            letterSpacing: 1.5,
          ),
        ),
        leading: IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.grid_view_rounded, color: primaryColor, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Appearance", primaryColor, context),
                  ListTile(
                    leading:
                        Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                    title: const Text("Brightness Mode"),
                    subtitle: Text(
                        isDark ? "Dark Mode Active" : "Light Mode Active"),
                    trailing: Switch(
                      value: isDark,
                      activeThumbColor: primaryColor,
                      onChanged: (value) {
                        themeProvider.setBrightness(
                            value ? Brightness.dark : Brightness.light);
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text("Theme Color"),
                    subtitle: const Text("Select your favorite accent"),
                    trailing: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    onTap: () => _showThemeDialog(context),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: res(context, 16.0),
                      vertical: res(context, 8.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Interface Scale",
                              style: TextStyle(fontSize: res(context, 16)),
                            ),
                            Text(
                              "${(scale * 100).round()}%",
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: scale,
                          min: 0.8,
                          max: 1.2,
                          divisions: 4,
                          label: "${(scale * 100).round()}%",
                          activeColor: primaryColor,
                          onChanged: (double value) {
                            themeProvider.setScale(value);
                          },
                        ),
                      ],
                    ),
                  ),
                  Divider(indent: res(context, 16), endIndent: res(context, 16)),
                  _buildSectionHeader("General", primaryColor, context),
                  _buildListTile(
                      Icons.notifications_none, "Notifications", () {}),
                  _buildListTile(
                      Icons.lock_outline, "Privacy & Security", () {}),
                  _buildListTile(
                    Icons.info_outline,
                    "About",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AboutScreen()),
                      );
                    },
                  ),
                  SizedBox(height: res(context, 40)),
                ],
              ),
            );
          },
>>>>>>> 8a35f843624a455ebaf6c1defb4b1077f73e75bc
        ),
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: children),
=======
  Widget _buildSectionHeader(String title, Color color, BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(res(context, 16.0), res(context, 16.0), res(context, 16.0), res(context, 8.0)),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }

  void _showThemeDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    final themeEntries = AppThemes.colors.entries.toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Accent Color"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: double.maxFinite,
          height: 320,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 0.8,
            ),
            itemCount: themeEntries.length,
            itemBuilder: (context, index) {
              final entry = themeEntries[index];

              final isSelected =
                  themeProvider.currentAccentColor == entry.value;

              return GestureDetector(
                onTap: () {
                  themeProvider.setColor(entry.value);

                  Navigator.pop(context);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      backgroundColor: entry.value,
                      radius: 25,
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                    SizedBox(height: res(context, 4)),
                    Text(
                      entry.key,
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE"),
>>>>>>> 8a35f843624a455ebaf6c1defb4b1077f73e75bc
          ),
        ],
      ),
    );
  }
<<<<<<< HEAD

  Widget _buildThemeToggle(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              themeProvider.isDarkMode
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
              color: colorScheme.onPrimaryContainer,
              size: 20,
            ),
          ),
          title: const Text('Dark Mode'),
          subtitle: Text(themeProvider.isDarkMode ? 'On' : 'Off'),
          trailing: Switch.adaptive(
            value: themeProvider.isDarkMode,
            onChanged: (value) => themeProvider.setDarkMode(value),
          ),
          onTap: () => themeProvider.toggleTheme(),
        );
      },
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: colorScheme.onPrimaryContainer,
          size: 20,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.chevron_right,
        color: colorScheme.onSurface.withOpacity(0.4),
      ),
      onTap: onTap,
    );
  }
}
=======
}
>>>>>>> 8a35f843624a455ebaf6c1defb4b1077f73e75bc
