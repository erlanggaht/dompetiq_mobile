import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:flutter_application_1/feat/auth/pin_service.dart';
import 'package:flutter_application_1/screens/forgot_password_screen.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/widgets/pin_input.dart';

class PinVerificationScreen extends StatefulWidget {
  final String challengeToken;
  final DateTime expiresAt;

  const PinVerificationScreen({
    super.key,
    required this.challengeToken,
    required this.expiresAt,
  });

  @override
  State<PinVerificationScreen> createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen>
    with SingleTickerProviderStateMixin {
  final _pinService = PinService();
  final _pinController = TextEditingController();
  bool _isLoading = false;
  // 429: backend mengunci percobaan PIN selama 15 menit
  String? _lockMessage;
  Timer? _countdownTimer;

  // PIN salah: goyang 3x
  late final AnimationController _shakeController = AnimationController(
    duration: const Duration(milliseconds: 400),
    vsync: this,
  );

  String get _pin => _pinController.text;

  @override
  void initState() {
    super.initState();
    // countdown butuh detak 1x/detik, bukan cuma saat user mengetik
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _pinController.addListener(() {
      if (!mounted) return;
      setState(() {});
      // langsung verifikasi begitu 4 digit terkumpul
      if (_pin.length == 4 && !_isLoading) _handleSubmit();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _shakeController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleSubmit() async {
    if (_lockMessage != null) return;
    if (_pin.length != 4) {
      _showSnack('PIN must be 4 digits');
      return;
    }
    if (DateTime.now().isAfter(widget.expiresAt)) {
      _showSnack('PIN session has expired, please sign in again');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _pinService.verifyLoginPin(
        challengeToken: widget.challengeToken,
        pin: _pin,
      );

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      _showSnack(message);
      // 429: kunci verifikasi sampai masa tunggu backend selesai
      if (message.contains('15 menit')) {
        _lockMessage = message;
      }
      _pinController.clear();
      _shakeController.forward(from: 0);
      setState(() {});
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.expiresAt.difference(DateTime.now());
    final minutes = remaining.inMinutes.clamp(0, 5);
    final seconds = remaining.inSeconds.clamp(0, 5 * 60) % 60;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Verify PIN',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                  color: Color(0xFF1C1C1C),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter your 4-digit PIN to continue',
                style: TextStyle(fontSize: 16, color: Color(0xFF1C1C1C)),
              ),
              const SizedBox(height: 26),
              AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  final offset = sin(_shakeController.value * 2 * pi * 3) * 10;
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: child,
                  );
                },
                child: PinInputField(
                  controller: _pinController,
                  autoFocus: true,
                ),
              ),
              const SizedBox(height: 10),
              if (_lockMessage != null) ...[
                Text(
                  _lockMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                remaining.isNegative
                    ? 'Session expired'
                    : 'Session expires in $minutes:${seconds.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF87879D)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ForgotPasswordScreen.pin(),
                  ),
                ),
                child: const Text(
                  'Forgot PIN?',
                  style: TextStyle(color: Color(0xFF3B62FF)),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 49,
                child: ElevatedButton(
                  onPressed: (_isLoading || _lockMessage != null)
                      ? null
                      : _handleSubmit,
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
                          'Verify',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
}
