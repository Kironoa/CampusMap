import 'package:flutter/material.dart';
import 'package:mobile_app/glass_modal.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/providers/theme_provider.dart';
import 'package:provider/provider.dart';

double res(BuildContext context, double value) {
  final provider = Provider.of<ThemeProvider>(context, listen: false);
  return value * provider.uiScale;
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool isPressed = false;
  final AuthService _authService = AuthService();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  Widget buildGlassIcon(IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(res(context, 12)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 25),
    );
  }

  void _handleSignUp() async {
    final username = _userController.text.trim();
    final password = _passController.text.trim();
    final confirmPass = _confirmPassController.text.trim();

    if (username.isEmpty || password.isEmpty || confirmPass.isEmpty) {
      _showModal("Error", "Fields cannot be empty.", isError: true);
      return;
    }

    if (password != confirmPass) {
      _showModal("Error", "Passwords do not match!", isError: true);
      return;
    }

    try {
      if (await _authService.usernameExists(username)) {
        _showModal("Error", "Username taken.", isError: true);
        return;
      }

      await _authService.register(username, password);
      if (!mounted) return;

      final theme = Theme.of(context);
      GlassModal.show(
        context,
        title: "Success!",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildGlassIcon(Icons.check_rounded, theme.colorScheme.primary),
            SizedBox(height: res(context, 20)),
            Text(
              "Account Created Successfully!",
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ],
        ),
        onNavigate: () => Navigator.pop(context),
      );
    } catch (e) {
      _showModal("Error", "Registration failed.", isError: true);
    }
  }

  void _showModal(String title, String msg, {bool isError = false}) {
    final theme = Theme.of(context);
    GlassModal.show(
      context,
      title: title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildGlassIcon(
            isError ? Icons.close_rounded : Icons.info_outline,
            isError ? theme.colorScheme.error : theme.colorScheme.primary,
          ),
          SizedBox(height: res(context, 20)),
          Text(msg, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: GestureDetector(
              onTapDown: (_) => setState(() => isPressed = true),
              onTapUp: (_) => setState(() => isPressed = false),
              onTapCancel: () => setState(() => isPressed = false),
              child: AnimatedScale(
                scale: isPressed ? 0.96 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: MediaQuery.of(context).size.width * 0.88,
                  padding: EdgeInsets.all(res(context, 2)),
                  decoration: _buildOuterDecoration(theme),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(res(context, 20)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: res(context, 25.0),
                        vertical: res(context, 30),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Register",
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: res(context, 22),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: res(context, 25)),
                          _buildField(
                            context,
                            Icons.person,
                            "Username",
                            controller: _userController,
                          ),
                          SizedBox(height: res(context, 10)),
                          _buildField(
                            context,
                            Icons.lock,
                            "Password",
                            isPassword: true,
                            controller: _passController,
                          ),
                          SizedBox(height: res(context, 10)),
                          _buildField(
                            context,
                            Icons.lock_reset,
                            "Confirm",
                            isPassword: true,
                            controller: _confirmPassController,
                          ),
                          SizedBox(height: res(context, 30)),
                          _buildButton(context, "Register"),
                          SizedBox(height: res(context, 15)),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              "Back to Login",
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                                fontSize: res(context, 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildOuterDecoration(ThemeData theme) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(res(context, 22)),
      gradient: LinearGradient(
        colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color:
              theme.colorScheme.primary.withValues(alpha: isPressed ? 0.5 : 0.2),
          blurRadius: isPressed ? res(context, 35) : res(context, 20),
          spreadRadius: 1,
        ),
      ],
    );
  }

  Widget _buildField(
    BuildContext context,
    IconData icon,
    String hint, {
    bool isPassword = false,
    TextEditingController? controller,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(res(context, 25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: Offset(res(context, 2), res(context, 5)),
            blurRadius: res(context, 10),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: theme.colorScheme.onSurface, size: 18),
          hintText: hint,
          hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.24), fontSize: res(context, 14)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: res(context, 15)),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(res(context, 5)),
      ),
      child: TextButton(
        onPressed: _handleSignUp,
        child: Text(
          text,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: res(context, 14),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}