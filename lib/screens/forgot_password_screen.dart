import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:flutter_application_1/core/config.dart';
import 'package:flutter_application_1/core/app_theme.dart';
import 'package:flutter_application_1/feat/auth/forgot_password_service.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/widgets/app_submit_button.dart';
import 'package:flutter_application_1/widgets/app_text_field.dart';

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
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: _sent
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      PhosphorIconsRegular.envelopeSimple,
                      size: 56,
                      color: colors.accent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Check your email',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.sentMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: colors.ink),
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
                          backgroundColor: colors.accent,
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: colors.ink),
                    ),
                    const SizedBox(height: 26),
                    AppTextField(
                      controller: _usernameController,
                      label: 'Username or Email',
                      prefixIcon: Icons.person_outline,
                    ),
                    const SizedBox(height: 26),
                    AppSubmitButton(
                      label: 'Send Reset Link',
                      loading: _isLoading,
                      onPressed: _handleSend,
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Back',
                        style: TextStyle(fontSize: 14, color: colors.grey),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
