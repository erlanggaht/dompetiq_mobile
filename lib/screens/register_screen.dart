import 'package:flutter/material.dart';

import 'package:flutter_application_1/feat/auth/register_service.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/widgets/app_password_field.dart';
import 'package:flutter_application_1/widgets/app_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _registerService = RegisterService();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleRegister() async {
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || username.isEmpty || password.isEmpty) {
      _showSnack('All fields are required');
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email)) {
      _showSnack('Invalid email format');
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9_]{3,15}$').hasMatch(username)) {
      _showSnack(
        'Username must be 3-15 characters (letters, numbers, underscore)',
      );
      return;
    }
    if (password.length < 6) {
      _showSnack('Password must be at least 6 characters');
      return;
    }
    if (password != confirmPassword) {
      _showSnack('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _registerService.register(
        email: email,
        username: username,
        password: password,
      );

      if (!mounted) return;
      _showSnack('Account created, please sign in');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              const Text(
                'Create Account',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                  color: Color(0xFF1C1C1C),
                ),
              ),
              const SizedBox(height: 26),
              AppTextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                label: 'Email',
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _usernameController,
                label: 'Username',
                prefixIcon: Icons.person_outline,
              ),

              const SizedBox(height: 16),
              AppPasswordField(
                controller: _passwordController,
                label: 'Password',
              ),
              const SizedBox(height: 16),
              AppPasswordField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 49,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B62FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                ),
                child: const Text(
                  'Already have an account? Sign In',
                  style: TextStyle(fontSize: 14, color: Color(0xFF87879D)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
