import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_application_1/feat/auth/pin_service.dart';
import 'package:flutter_application_1/screens/home_screen.dart';

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

class _PinVerificationScreenState extends State<PinVerificationScreen> {
  final _pinService = PinService();
  final _controllers = List.generate(4, (_) => TextEditingController());
  final _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isLoading = false;
  Timer? _countdownTimer;

  String get _pin => _controllers.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    // countdown butuh detak 1x/detik, bukan cuma saat user mengetik
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      // paste: sebar digit ke semua kotak
      final digits = value.replaceAll(RegExp(r'\D'), '').split('');
      for (var i = 0; i < 4 && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      _focusNodes[digits.length < 4 ? digits.length : 3].requestFocus();
    } else if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  Future<void> _handleSubmit() async {
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
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  return Container(
                    width: 56,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    child: TextField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 1,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) => _onDigitChanged(i, value),
                      onSubmitted: (_) => _handleSubmit(),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              Text(
                remaining.isNegative
                    ? 'Session expired'
                    : 'Session expires in $minutes:${seconds.toString().padLeft(2, '0')}',
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF87879D)),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 49,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
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
