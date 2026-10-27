// lib/screens/get_started_screen.dart
import 'package:flutter/material.dart';
import 'package:naviapp/models/user_role.dart';
import 'package:naviapp/providers/user_role_provider.dart';
import 'package:naviapp/screens/home_screen.dart';
import 'package:naviapp/widgets/app_ui.dart';
import 'package:provider/provider.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedRole = context.watch<UserRoleProvider>().role;

    return Scaffold(
      backgroundColor: const Color(0xFF0A7040),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                        boxShadow: AppShadows.card,
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Image.asset(
                        'assets/images/logo and icon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'NaviApp',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your Campus Navigator',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 15,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'What is your role?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'We use this to route you through the correct campus gate.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildRoleGrid(context, selectedRole),
                    const SizedBox(height: 28),
                    _buildFeatureRow(
                      icon: Icons.map_outlined,
                      iconColor: const Color(0xFF7DE3A8),
                      title: 'Interactive Floor Plans',
                      subtitle:
                          'Zoom, explore, and tap any room across all three floors.',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureRow(
                      icon: Icons.psychology_outlined,
                      iconColor: const Color(0xFFFFDAB9),
                      title: 'In-App Help Chat',
                      subtitle:
                          'Ask how to scan, navigate, and use every feature.',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureRow(
                      icon: Icons.navigation_outlined,
                      iconColor: const Color(0xFFBCD8FF),
                      title: 'Live GPS Navigation',
                      subtitle:
                          'Outdoor turn-by-turn that hands off to indoor maps.',
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selectedRole == null) ...[
                    Text(
                      'Select your role to continue',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0A7040),
                        disabledBackgroundColor: Colors.white.withValues(
                          alpha: 0.38,
                        ),
                        disabledForegroundColor: Colors.white.withValues(
                          alpha: 0.7,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: selectedRole == null
                          ? null
                          : () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const HomeScreen(),
                              ),
                            ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Get Started'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleGrid(BuildContext context, UserRole? selectedRole) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildRoleCard(
                context,
                UserRole.student,
                selectedRole == UserRole.student,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildRoleCard(
                context,
                UserRole.faculty,
                selectedRole == UserRole.faculty,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildRoleCard(
                context,
                UserRole.ojt,
                selectedRole == UserRole.ojt,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildRoleCard(
                context,
                UserRole.visitor,
                selectedRole == UserRole.visitor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleCard(BuildContext context, UserRole role, bool selected) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${role.label}. ${role.description}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.read<UserRoleProvider>().setRole(role),
          borderRadius: BorderRadius.circular(AppRadius.tile),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.tile),
              border: Border.all(
                color: selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.18),
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _roleIcon(role),
                  size: 21,
                  color: selected ? const Color(0xFF0A7040) : Colors.white,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.label,
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFF0A7040)
                              : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        role.gateHint,
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFF0A7040).withValues(alpha: 0.7)
                              : Colors.white.withValues(alpha: 0.65),
                          fontSize: 10.5,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle,
                    size: 17,
                    color: Color(0xFF0A7040),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _roleIcon(UserRole role) {
    switch (role) {
      case UserRole.student:
        return Icons.school_outlined;
      case UserRole.faculty:
        return Icons.badge_outlined;
      case UserRole.ojt:
        return Icons.work_outline;
      case UserRole.visitor:
        return Icons.person_outline;
    }
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 26, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
