import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BalanceVisibility {
  static const _storage = FlutterSecureStorage();
  static const _key = 'balanceVisibleByAccount';
  static final ValueNotifier<bool> visible = ValueNotifier(true);
  static Map<String, bool> _values = {};
  static String _current = 'guest';

  static Future<void> load() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _values = decoded.map(
          (key, value) => MapEntry(key, value == true || value == 'true'),
        );
      }
    } catch (_) {
      _values = {};
    }
    visible.value = _values[_current] ?? true;
  }

  static Future<void> useAccount(Object? id) async {
    _current = id == null ? 'guest' : id.toString();
    visible.value = _values[_current] ?? true;
  }

  static Future<void> toggle() async {
    visible.value = !visible.value;
    _values[_current] = visible.value;
    try {
      await _storage.write(key: _key, value: jsonEncode(_values));
    } catch (_) {
      return;
    }
  }
}
