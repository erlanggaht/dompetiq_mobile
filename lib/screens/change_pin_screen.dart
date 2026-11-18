import 'package:flutter/material.dart';

import 'package:flutter_application_1/feat/settings/security_service.dart';
import 'package:flutter_application_1/widgets/app_page_header.dart';
import 'package:flutter_application_1/widgets/pin_input.dart';

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
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(title: 'Change PIN'),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loadingStatus) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_loadError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _loadStatus, child: const Text('Retry')),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEAECF0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Color(0xFF3B62FF),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _hasPin
                        ? 'Update your 4-digit PIN to keep your account secure.'
                        : 'Set a 4-digit PIN for extra security at login.',
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _FieldLabel('New PIN'),
          const SizedBox(height: 12),
          PinInputField(controller: _newPinController),
          const SizedBox(height: 24),
          _FieldLabel('Confirm New PIN'),
          const SizedBox(height: 12),
          PinInputField(controller: _confirmPinController),
          if (_hasPin) ...[
            const SizedBox(height: 28),
            _FieldLabel('Account Password'),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Your account password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 34),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: _isSaving ? null : _handleSave,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF3B62FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _hasPin ? 'Save New PIN' : 'Activate PIN',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF344054),
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );
}
