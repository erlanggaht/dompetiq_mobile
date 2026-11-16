import 'dart:math';

import 'package:android_id/android_id.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceId {
  static const _key = 'deviceId';
  static const _storage = FlutterSecureStorage();
  static String? _cached;

  // ANDROID_ID tetap sama saat install ulang, jadi tidak memakan slot device baru
  static Future<String> get() async {
    if (_cached != null) return _cached!;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidId = await AndroidId().getId();
      if (androidId != null) return _cached = androidId;
    }
    var id = await _storage.read(key: _key);
    if (id == null) {
      id = generateUuidV4();
      await _storage.write(key: _key, value: id);
    }
    return _cached = id;
  }
}

String generateUuidV4() {
  final bytes = List.generate(16, (_) => Random.secure().nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
