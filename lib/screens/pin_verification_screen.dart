import 'dart:async';
import 'dart:math';

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

// Satu TextField tersembunyi menampung seluruh PIN; 4 kotak hanya display.
// Pendekatan ini membuat backspace bekerja alami, termasuk saat kotak
// berikutnya masih kosong (4 TextField terpisah tidak bisa melakukan itu).
class _PinVerificationScreenState extends State<PinVerificationScreen>
    with SingleTickerProviderStateMixin {
  final _pinService = PinService();
  final _pinController = TextEditingController();
  final _pinFocus = FocusNode();
  bool _isLoading = false;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _shakeController.dispose();
    _pinController.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
      _pinController.clear();
      _pinFocus.requestFocus();
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
      body: GestureDetector(
        // ketuk di mana pun tetap membuka keyboard
        onTap: () => _pinFocus.requestFocus(),
        behavior: HitTestBehavior.opaque,
        child: Center(
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
                    final offset =
                        sin(_shakeController.value * 2 * pi * 3) * 10;
                    return Transform.translate(
                      offset: Offset(offset, 0),
                      child: child,
                    );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // kotak display; index == panjang PIN = posisi input
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (i) {
                          final hasDigit = i < _pin.length;
                          final isFocused =
                              i == _pin.length && _pinFocus.hasFocus;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 58,
                            height: 64,
                            margin: const EdgeInsets.symmetric(horizontal: 7),
                            decoration: BoxDecoration(
                              color: isFocused || hasDigit
                                  ? Colors.white
                                  : const Color(0xFFF2F4F9),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                width: 2,
                                color: isFocused
                                    ? const Color(0xFF3B62FF)
                                    : hasDigit
                                    ? const Color(0xFF3B62FF)
                                          .withValues(alpha: 0.35)
                                    : const Color(0xFFE4E7F0),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              hasDigit ? _pin[i] : '',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1C1C1C),
                              ),
                            ),
                          );
                        }),
                      ),
                      // field input yang sebenarnya, dibuat transparan
                      Opacity(
                        opacity: 0,
                        child: SizedBox(
                          width: 70,
                          height: 64,
                          child: TextField(
                            controller: _pinController,
                            focusNode: _pinFocus,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            maxLength: 4,
                            decoration: const InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  remaining.isNegative
                      ? 'Session expired'
                      : 'Session expires in $minutes:${seconds.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF87879D),
                  ),
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
      ),
    );
  }
}
