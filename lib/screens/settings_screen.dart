import 'package:flutter/material.dart';
import 'package:mobile_app/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/themes/app_themes.dart';
import 'package:mobile_app/widgets/about.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  double res(BuildContext context, double size) {
    return size * (MediaQuery.of(context).size.width / 375);
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
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.topCenter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("Appearance", primaryColor),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Interface Scale",
                                style: TextStyle(fontSize: 16),
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
                    const Divider(indent: 16, endIndent: 16),
                    _buildSectionHeader("General", primaryColor),
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
                    SizedBox(height: 40 * scale),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
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
                    const SizedBox(height: 4),
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
          ),
        ],
      ),
    );
  }
}
