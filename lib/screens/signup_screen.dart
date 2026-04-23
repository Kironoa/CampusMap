import 'package:flutter/material.dart';
import 'package:mobile_app/glass_modal.dart';
import 'package:mobile_app/services/auth_service.dart';

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

  void _handleSignUp() async {
    final username = _userController.text.trim();
    final password = _passController.text.trim();
    final confirmPass = _confirmPassController.text.trim();

    if (username.isEmpty || password.isEmpty || confirmPass.isEmpty) {
      _showModal("Nah!", "Fields cannot be empty.", isError: true);
      return;
    }

    if (password != confirmPass) {
      _showModal("Error", "Passwords do not match!", isError: true);
      return;
    }

    try {
      if (await _authService.usernameExists(username)) {
        _showModal("Nah!", "Username taken.", isError: true);
        return;
      }

      await _authService.register(username, password);
      if (!mounted) return;

      GlassModal.show(
        context,
        title: "Success!",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildGlassIcon(Icons.check_rounded, const Color(0xFF00FF75)),
            const SizedBox(height: 20),
            const Text(
              "Account Created Successfully!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
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
    GlassModal.show(
      context,
      title: title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildGlassIcon(
            isError ? Icons.close_rounded : Icons.info_outline,
            isError ? Colors.redAccent : const Color(0xFF00FF75),
          ),
          const SizedBox(height: 20),
          Text(msg, style: const TextStyle(color: Colors.white70)),
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
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
                width: 350,
                padding: const EdgeInsets.all(2),
                decoration: _buildOuterDecoration(),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF171717),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25.0,
                      vertical: 30,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Register",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 25),
                        _buildField(
                          Icons.person,
                          "Username",
                          controller: _userController,
                        ),
                        const SizedBox(height: 10),
                        _buildField(
                          Icons.lock,
                          "Password",
                          isPassword: true,
                          controller: _passController,
                        ),
                        const SizedBox(height: 10),
                        _buildField(
                          Icons.lock_reset,
                          "Confirm",
                          isPassword: true,
                          controller: _confirmPassController,
                        ),
                        const SizedBox(height: 30),
                        _buildButton("Register"),
                        const SizedBox(height: 15),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            "Back to Login",
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
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

  Widget _buildButton(String text) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(5),
      ),
      child: TextButton(
        onPressed: _handleSignUp,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
