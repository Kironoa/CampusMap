import 'package:flutter/material.dart';
import 'package:mobile_app/models/app_user.dart';
import 'package:mobile_app/screens/dashboard_screen.dart';
import 'package:mobile_app/screens/signup_screen.dart';
import 'package:mobile_app/glass_modal.dart';
import 'package:mobile_app/services/auth_service.dart';

class StudentPalLogin extends StatefulWidget {
  const StudentPalLogin({super.key});

  @override
  State<StudentPalLogin> createState() => _StudentPalLoginState();
}

class _StudentPalLoginState extends State<StudentPalLogin> {
  bool isPressed = false;
  final AuthService _authService = AuthService();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  Widget buildGlassIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
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

  void _handleLogin() async {
    final username = _userController.text.trim();
    final password = _passController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showErrorModal("Fields cannot be empty.");
      return;
    }

    try {
      final user = await _authService.login(username, password);

      if (user != null) {
        _showSuccessModal(user);
      } else {
        _showErrorModal("Invalid username or password.");
      }
    } catch (e) {
      debugPrint("Login Error: $e");
      _showErrorModal("Database error occurred.");
    }
  }

  void _showSuccessModal(AppUser user) {
    GlassModal.show(
      context,
      title: "Sumakses!",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildGlassIcon(Icons.check_rounded, const Color(0xFF00FF75)),
          const SizedBox(height: 20),
          Text(
            "Welcome, @${user.username} enjoy and study well.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
      onNavigate: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => StudentDashboard(userId: user.id),
              ),
            );
          }
        });
      },
    );
  }

  void _showErrorModal(String message) {
    GlassModal.show(
      context,
      title: "Nah!",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildGlassIcon(Icons.close_rounded, Colors.redAccent),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double cardWidth = 350;
    const double cardHeight = 450;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                height: 80,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.school_rounded,
                  color: Color(0xFF00FF75),
                  size: 80,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "STUDENT PAL",
                style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 4,
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTapDown: (_) => setState(() => isPressed = true),
                onTapUp: (_) => setState(() => isPressed = false),
                onTapCancel: () => setState(() => isPressed = false),
                child: AnimatedScale(
                  scale: isPressed ? 0.96 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: cardWidth,
                    height: cardHeight,
                    padding: const EdgeInsets.all(2),
                    decoration: _buildOuterDecoration(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF171717),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Login",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 25),
                            _buildField(
                              Icons.alternate_email,
                              "Username",
                              controller: _userController,
                            ),
                            const SizedBox(height: 15),
                            _buildField(
                              Icons.lock,
                              "Password",
                              isPassword: true,
                              controller: _passController,
                            ),
                            const SizedBox(height: 30),
                            Row(
                              children: [
                                Expanded(child: _buildButton("Login")),
                                const SizedBox(width: 10),
                                Expanded(child: _buildButton("Sign Up")),
                              ],
                            ),
                            const SizedBox(height: 15),
                            _buildButton("Forgot Password", isFullWidth: true),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildOuterDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(
        colors: [Color(0xFF00FF75), Color(0xFF3700FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color:
              const Color(0xFF00FF75).withValues(alpha: isPressed ? 0.5 : 0.2),
          blurRadius: isPressed ? 35 : 20,
          spreadRadius: 1,
        ),
      ],
    );
  }

  Widget _buildField(
    IconData icon,
    String hint, {
    bool isPassword = false,
    TextEditingController? controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF050505),
            offset: Offset(2, 5),
            blurRadius: 10,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Color(0xFFD3D3D3)),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white, size: 18),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildButton(String text, {bool isFullWidth = false}) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextButton(
        onPressed: () {
          if (text == "Login") {
            _handleLogin();
          } else if (text == "Sign Up") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SignUpScreen()),
            );
          }
        },
        child: Text(
          text,
          style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
