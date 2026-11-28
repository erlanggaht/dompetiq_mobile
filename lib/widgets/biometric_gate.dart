import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:flutter_application_1/core/biometric_lock.dart';
import 'package:flutter_application_1/core/app_theme.dart';

/// Locks the wrapped app while biometric unlock is enabled.
class BiometricGate extends StatefulWidget {
  final Widget child;

  const BiometricGate({super.key, required this.child});

  @override
  State<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends State<BiometricGate>
    with WidgetsBindingObserver {
  bool _checking = true;
  bool _enabled = false;
  bool _locked = false;
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    BiometricLock.enabled.addListener(_onPreferenceChanged);
    _load();
  }

  @override
  void dispose() {
    BiometricLock.enabled.removeListener(_onPreferenceChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onPreferenceChanged() {
    if (BiometricLock.enabled.value) {
      _enabled = true;
      return;
    }
    _enabled = false;
    if (_locked && mounted) setState(() => _locked = false);
  }

  Future<void> _load() async {
    final enabled = await BiometricLock.load();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _locked = enabled;
      _checking = false;
    });
    if (enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_enabled) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (!_locked) setState(() => _locked = true);
    } else if (state == AppLifecycleState.resumed &&
        _locked &&
        !_authenticating) {
      _unlock();
    }
  }

  Future<void> _unlock() async {
    if (_authenticating) return;
    _authenticating = true;
    final success = await BiometricLock.authenticate();
    _authenticating = false;
    if (success && mounted) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return ColoredBox(color: Theme.of(context).colorScheme.surface);
    }
    return Stack(
      children: [
        widget.child,
        if (_locked) Positioned.fill(child: _LockOverlay(onUnlock: _unlock)),
      ],
    );
  }
}

class _LockOverlay extends StatelessWidget {
  final VoidCallback onUnlock;

  const _LockOverlay({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIconsRegular.lock,
                    size: 40,
                    color: colors.accent,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'DompetIQ is locked',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Unlock with your biometrics or device PIN.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: colors.grey,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: onUnlock,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Unlock',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
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
