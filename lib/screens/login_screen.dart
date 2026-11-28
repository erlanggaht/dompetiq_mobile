import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/device_id.dart';
import 'package:flutter_application_1/feat/auth/login_service.dart';
import 'package:flutter_application_1/core/app_theme.dart';
import 'package:flutter_application_1/screens/device_limit_screen.dart';
import 'package:flutter_application_1/screens/pin_verification_screen.dart';
import 'package:flutter_application_1/widgets/app_submit_button.dart';
import 'package:flutter_application_1/widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showSnack('Username and password are required');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.login(
        username: username,
        password: password,
        deviceId: await DeviceId.get(),
      );

      final data = response['data'];
      if (data == null) throw Exception('Login gagal');

      if (!mounted) return;

      if (data['requiresPin'] != true) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PinVerificationScreen(
            challengeToken: data['challengeToken'],
            expiresAt: DateTime.parse(data['expiresAt']),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (e is MaxDeviceException) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DeviceLimitScreen()),
        );
        return;
      }
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                  color: colors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign In to continue',
                style: TextStyle(fontSize: 18, color: colors.ink),
              ),
              const SizedBox(height: 26),
              AppTextField(
                controller: _usernameController,
                label: 'Username',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _passwordController,
                label: 'Password',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 26),
              AppSubmitButton(
                label: 'Login',
                loading: _isLoading,
                onPressed: _handleLogin,
              ),
              const SizedBox(height: 26),
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, '/auth/forgot-password'),
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/auth/register'),
                child: Text(
                  "Don't have an account? Sign Up",
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
