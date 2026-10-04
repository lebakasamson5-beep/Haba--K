import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;

  // Theme Colors
  static const Color deepIndigo = Color(0xFF1A237E);
  static const Color primaryIndigo = Color(0xFF3949AB);
  static const Color backgroundGrey = Color(0xFFF5F7FA);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color income = Color(0xFF22C55E);
  static const Color expense = Color(0xFFEF4444);

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthService>(context, listen: false);
    final success = await auth.login(_email.text.trim(), _password.text.trim());

    if (!mounted) return;

    if (success) {
      // Login was successful - AuthWrapper will handle routing
      Fluttertoast.showToast(
        msg: '✅ Welcome back!',
        backgroundColor: income,
        textColor: Colors.white,
      );
      // No need to navigate - AuthWrapper will handle it
    } else {
      // Check if there's an access denied reason
      final authState = Provider.of<AuthService>(context, listen: false);
      if (authState.accessDeniedReason != null) {
        Fluttertoast.showToast(
          msg: '⚠️ ${authState.accessDeniedReason}',
          backgroundColor: Colors.orange,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
      } else {
        Fluttertoast.showToast(
          msg: '❌ Invalid email or password',
          backgroundColor: expense,
          textColor: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: backgroundGrey,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [deepIndigo, primaryIndigo],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: primaryIndigo.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.storefront_rounded, size: 48, color: deepIndigo),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Haba-K',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: deepIndigo,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Sign in to continue',
                        style: TextStyle(color: textGrey, fontSize: 14),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _email,
                        decoration: _decoration('Email Address', Icons.email_outlined),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Email is required';
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscurePassword,
                        decoration: _decoration('Password', Icons.lock_outline_rounded).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: textGrey,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) =>
                        (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                            );
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(color: primaryIndigo, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryIndigo,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                              : const Text(
                            'Login',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account?",
                            style: TextStyle(color: textGrey),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                            },
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(color: primaryIndigo, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      // Manager Login Info
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.admin_panel_settings, size: 18, color: Colors.orange),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '👔 Manager: Habak@gmail.com / 42Hill',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
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
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryIndigo),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryIndigo, width: 1.5),
      ),
      filled: true,
      fillColor: backgroundGrey,
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }
}