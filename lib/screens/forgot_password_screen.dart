import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/config.dart';
import 'package:flutter_application_1/feat/auth/forgot_password_service.dart';
import 'package:flutter_application_1/screens/login_screen.dart';

// Satu halaman, dua varian: reset password & reset PIN.
// Bedanya hanya endpoint dan teks; alur form sama persis.
class ForgotPasswordScreen extends StatefulWidget {
  final String title;
  final String description;
  final String endpoint;
  final String sentMessage;

  const ForgotPasswordScreen({super.key})
    : title = 'Forgot Password?',
      description = 'Enter your username or email, we will send a reset link.',
      endpoint = ApiRouteConfig.resetPasswordSend,
      sentMessage =
          'We sent a password reset link. Open it to set a new password. '
          'The link expires in 15 minutes.';

  const ForgotPasswordScreen.pin({super.key})
    : title = 'Forgot PIN?',
      description =
          'Enter your username or email, we will send a recovery link.',
      endpoint = ApiRouteConfig.pinResetSend,
      sentMessage =
          'If your account has a PIN, a recovery link has been sent to '
          'your registered email. The link expires in 15 minutes.';

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _forgotPasswordService = ForgotPasswordService();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleSend() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      _showSnack('Username or email is required');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _forgotPasswordService.sendResetLink(
        username: username,
        endpoint: widget.endpoint,
      );
      if (!mounted) return;
      setState(() => _sent = true);
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
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: _sent
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.mark_email_read_outlined,
                      size: 56,
                      color: Color(0xFF3B62FF),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Check your email',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Color(0xFF1C1C1C),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.sentMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1C1C1C),
                      ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      height: 49,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B62FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Back to Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                        color: Color(0xFF1C1C1C),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1C1C1C),
                      ),
                    ),
                    const SizedBox(height: 26),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username or Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      height: 49,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSend,
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
                                'Send Reset Link',
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
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF87879D),
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
