import 'package:flutter/material.dart';
import 'package:naviapp/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePass = true;
  String? _emailError;
  String? _passError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    VoidCallback? onToggle,
    String? errorText,
    TextInputType keyboard = TextInputType.text,
    TextCapitalization cap = TextCapitalization.none,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(
          fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500,
          color: isDark ? const Color(0xFFFED7AA) : const Color(0xFF78350F),
        )),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboard,
          textCapitalization: cap,
          style: TextStyle(fontFamily: 'Poppins', fontSize: 14,
            color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13,
              color: isDark ? Colors.white30 : Colors.black38),
            filled: true,
            fillColor: isDark ? const Color(0xFF3D2A10) : Colors.grey.shade50,
            prefixIcon: Icon(icon, size: 20,
              color: isDark ? const Color(0xFFFED7AA) : const Color(0xFF78350F)),
            suffixIcon: onToggle != null
                ? IconButton(
                    icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20, color: isDark ? const Color(0xFFFED7AA) : const Color(0xFF78350F)),
                    onPressed: onToggle,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(errorText, style: const TextStyle(
            color: Colors.red, fontSize: 11, fontFamily: 'Poppins')),
        ],
      ],
    );
  }

  void _showForgotDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Password', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('This app works offline. Passwords cannot be reset automatically.\nPlease contact your administrator.', style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFFF97316), fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _emailError = 'Enter a valid email address');
      return;
    }
    if (password.isEmpty) {
      setState(() => _passError = 'Password is required');
      return;
    }
    setState(() { _isLoading = true; _emailError = null; _passError = null; });
    try {
      await AuthService.login(email, password);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', ''), style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: const Color(0xFFF97316),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: isDark ? const Color(0xFF1A1208) : const Color(0xFFFFFBF5),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 240,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF97316),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.school_rounded, size: 56, color: Colors.white),
                        const SizedBox(height: 10),
                        const Text('NaviApp', style: TextStyle(
                          fontFamily: 'Poppins', fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('TCGC Campus Guide', style: TextStyle(
                          fontFamily: 'Poppins', fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Welcome Back', style: TextStyle(
                      fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Sign in to your account', style: TextStyle(
                      fontFamily: 'Poppins', fontSize: 13,
                      color: isDark ? const Color(0xFFFED7AA) : const Color(0xFF78350F))),
                    const SizedBox(height: 28),
                    _buildField(
                      controller: _emailCtrl,
                      label: 'Email',
                      hint: 'you@tcgc.edu.ph',
                      icon: Icons.email_outlined,
                      keyboard: TextInputType.emailAddress,
                      errorText: _emailError,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _passCtrl,
                      label: 'Password',
                      hint: '',
                      icon: Icons.lock_outlined,
                      obscure: _obscurePass,
                      onToggle: () => setState(() => _obscurePass = !_obscurePass),
                      errorText: _passError,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _showForgotDialog(context),
                        child: const Text('Forgot Password?', style: TextStyle(
                          fontFamily: 'Poppins', color: Color(0xFFF97316), fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(
                                strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                            : const Text('Login', style: TextStyle(
                                fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Don't have an account? ", style: TextStyle(
                            fontFamily: 'Poppins', fontSize: 13,
                            color: isDark ? const Color(0xFFFED7AA) : const Color(0xFF78350F))),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/signup'),
                            child: const Text('Sign Up', style: TextStyle(
                              fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFF97316))),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}