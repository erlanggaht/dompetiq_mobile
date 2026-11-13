import 'package:flutter/material.dart';

import 'package:flutter_application_1/feat/settings/security_service.dart';
import 'package:flutter_application_1/widgets/pin_input.dart';

// Satu halaman dua fungsi: mengganti PIN (wajib isi password lama)
// atau mengaktifkan PIN pertama kali (tanpa password).
class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final _securityService = SecurityService();
  final _passwordController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _loadingStatus = true;
  bool _hasPin = false;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _loadingStatus = true;
      _loadError = null;
    });
    try {
      final hasPin = await _securityService.getPinStatus();
      if (!mounted) return;
      setState(() {
        _hasPin = hasPin;
        _loadingStatus = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString().replaceFirst('Exception: ', '');
        _loadingStatus = false;
      });
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleSave() async {
    final password = _passwordController.text;
    final newPin = _newPinController.text;
    final confirmPin = _confirmPinController.text;

    if (_hasPin && password.isEmpty) {
      _showSnack('Account password is required');
      return;
    }
    if (newPin.length != 4) {
      _showSnack('New PIN must be 4 digits');
      return;
    }
    if (newPin != confirmPin) {
      _showSnack('PINs do not match');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _securityService.savePin(
        pin: newPin,
        confirmPin: confirmPin,
        password: _hasPin ? password : null,
      );
      if (!mounted) return;
      _showSnack(_hasPin ? 'PIN updated' : 'PIN activated');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _loadingStatus
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_loadError!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadStatus,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _hasPin ? 'Change PIN' : 'Activate PIN',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                        color: Color(0xFF1C1C1C),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _hasPin
                          ? 'Confirm your account password, then set a new PIN.'
                          : 'Set a 4-digit PIN for extra security at login.',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF87879D),
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (_hasPin) ...[
                      const Text(
                        'Account Password',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1C1C),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: 'Your account password',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    const Text(
                      'New PIN',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1C1C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    PinInputField(controller: _newPinController),
                    const SizedBox(height: 20),
                    const Text(
                      'Confirm New PIN',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1C1C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    PinInputField(controller: _confirmPinController),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 49,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B62FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _hasPin ? 'Save New PIN' : 'Activate PIN',
                                style: const TextStyle(
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
