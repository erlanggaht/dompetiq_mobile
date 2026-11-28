import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Device-level biometric app lock. The preference is stored locally; the
/// backend never sees biometric data.
class BiometricLock {
  static const _storage = FlutterSecureStorage();
  static const _key = 'biometricLockEnabled';
  static final _auth = LocalAuthentication();

  /// Mirrors the stored preference so widgets can react to changes.
  static final ValueNotifier<bool> enabled = ValueNotifier(false);

  static Future<bool> isAvailable() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    } on LocalAuthException {
      return false;
    }
  }

  static Future<bool> load() async {
    var stored = false;
    try {
      stored = await _storage.read(key: _key) == 'true';
    } on PlatformException {
      stored = false;
    }
    enabled.value = stored && await isAvailable();
    return enabled.value;
  }

  static Future<void> setEnabled(bool value) async {
    try {
      await _storage.write(key: _key, value: value ? 'true' : 'false');
    } on PlatformException {
      return;
    }
    enabled.value = value;
  }

  /// Falls back to the device PIN/pattern/passcode when biometrics fail.
  static Future<bool> authenticate({String reason = 'Unlock DompetIQ'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException {
      return false;
    } on LocalAuthException {
      return false;
    }
  }
}
