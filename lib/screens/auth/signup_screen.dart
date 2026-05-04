import 'package:flutter/material.dart';
import 'package:naviapp/services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _selectedRole = 'Student';
  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _nameError, _idError, _emailError, _passError, _confirmError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
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

  Future<void> _handleRegister() async {
    setState(() {
      _nameError = _nameCtrl.text.trim().isEmpty ? 'Full name is required' : null;
      _idError = _idCtrl.text.trim().isEmpty ? 'ID number is required' : null;
      _emailError = (!_emailCtrl.text.contains('@') || _emailCtrl.text.trim().isEmpty)
          ? 'Enter a valid email address' : null;
      _passError = _passCtrl.text.length < 8
          ? 'Password must be at least 8 characters' : null;
      _confirmError = _confirmCtrl.text != _passCtrl.text
          ? 'Passwords do not match' : null;
    });

    if ([_nameError, _idError, _emailError, _passError, _confirmError].any((e) => e != null)) return;

    setState(() => _isLoading = true);
    try {
      await AuthService.register(
        fullName: _nameCtrl.text,
        idNumber: _idCtrl.text,
        email: _emailCtrl.text,
        password: _passCtrl.text,
        role: _selectedRole,
      );
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
              height: 200,
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
                        const Icon(Icons.school_rounded, size: 48, color: Colors.white),
                        const SizedBox(height: 12),
                        const Text('NaviApp', style: TextStyle(
                          fontFamily: 'Poppins', fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('Create your account', style: TextStyle(
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
                    const Text('Join NaviApp', style: TextStyle(
                      fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Register with your student or faculty ID', style: TextStyle(
                      fontFamily: 'Poppins', fontSize: 13,
                      color: isDark ? const Color(0xFFFED7AA) : const Color(0xFF78350F))),
                    const SizedBox(height: 24),
                    Text('Select Role', style: TextStyle(
                      fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFFFED7AA) : const Color(0xFF78350F))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFF97316), width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedRole = 'Student'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedRole == 'Student'
                                      ? const Color(0xFFF97316) : Colors.transparent,
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                                ),
                                child: Center(
                                  child: Text('Student', style: TextStyle(
                                    fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500,
                                    color: _selectedRole == 'Student'
                                        ? Colors.white : const Color(0xFFF97316))),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedRole = 'Faculty'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedRole == 'Faculty'
                                      ? const Color(0xFFF97316) : Colors.transparent,
                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(11)),
                                ),
                                child: Center(
                                  child: Text('Faculty', style: TextStyle(
                                    fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500,
                                    color: _selectedRole == 'Faculty'
                                        ? Colors.white : const Color(0xFFF97316))),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildField(
                      controller: _nameCtrl,
                      label: 'Full Name',
                      hint: 'Juan Dela Cruz',
                      icon: Icons.person_outlined,
                      cap: TextCapitalization.words,
                      errorText: _nameError,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _idCtrl,
                      label: 'ID Number',
                      hint: 'e.g. 2021-00001',
                      icon: Icons.badge_outlined,
                      errorText: _idError,
                    ),
                    const SizedBox(height: 16),
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
                      hint: 'Min. 8 characters',
                      icon: Icons.lock_outlined,
                      obscure: _obscurePass,
                      onToggle: () => setState(() => _obscurePass = !_obscurePass),
                      errorText: _passError,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _confirmCtrl,
                      label: 'Confirm Password',
                      hint: '',
                      icon: Icons.lock_outlined,
                      obscure: _obscureConfirm,
                      onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      errorText: _confirmError,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(
                                strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                            : const Text('Create Account', style: TextStyle(
                                fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Already have an account? ', style: TextStyle(
                            fontFamily: 'Poppins', fontSize: 13,
                            color: isDark ? const Color(0xFFFED7AA) : const Color(0xFF78350F))),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text('Login', style: TextStyle(
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