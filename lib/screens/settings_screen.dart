import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:naviapp/providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
        ),
      ),
    );
  }

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
          ),
        ],
      ),
    );
  }

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