import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/auth_service.dart';
import '/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final auth = Provider.of<AuthService>(context, listen: false);
    final result = await auth.register(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      confirmPassword: _confirmPassword.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      Fluttertoast.showToast(
        msg: result['message'] ?? '✅ Account created successfully! Please login.',
        backgroundColor: AppTheme.income,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      Fluttertoast.showToast(
        msg: result['message'] ?? '❌ Registration failed. Please try again.',
        backgroundColor: AppTheme.expense,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.deepIndigo,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
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
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryIndigo.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_add_alt_1_rounded, size: 40, color: AppTheme.deepIndigo),
                      ),
                      const SizedBox(height: 16),
                      const Text('Create Account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.deepIndigo)),
                      const SizedBox(height: 4),
                      const Text('Please fill in the details below', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _firstName,
                        decoration: _decoration('First Name', Icons.person_outline_rounded),
                        validator: (v) => (v == null || v.isEmpty) ? 'First name is required' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _lastName,
                        decoration: _decoration('Last Name', Icons.person_outline_rounded),
                        validator: (v) => (v == null || v.isEmpty) ? 'Last name is required' : null,
                      ),
                      const SizedBox(height: 16),

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
                              color: AppTheme.textGrey,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _confirmPassword,
                        obscureText: _obscureConfirmPassword,
                        decoration: _decoration('Confirm Password', Icons.lock_outline_rounded).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: AppTheme.textGrey,
                            ),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please confirm your password';
                          if (v != _password.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryIndigo.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: AppTheme.primaryIndigo, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'After registration, you will be redirected to the login page',
                                style: TextStyle(color: AppTheme.deepIndigo, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryIndigo,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                              : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account?', style: TextStyle(color: AppTheme.textGrey)),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Login', style: TextStyle(color: AppTheme.primaryIndigo, fontWeight: FontWeight.bold)),
                          ),
                        ],
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
      prefixIcon: Icon(icon, color: AppTheme.primaryIndigo),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.primaryIndigo, width: 1.5),
      ),
      filled: true,
      fillColor: AppTheme.backgroundGrey,
    );
  }


  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }
}