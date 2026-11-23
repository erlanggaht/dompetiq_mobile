import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CacheEntry<T> {
  final T data;
  final bool stale;

  const CacheEntry(this.data, {required this.stale});
}

class CacheManager {
  static const _prefix = 'cache.v1';

  static Future<void> write({
    required String key,
    required String userId,
    required Object data,
    required Duration ttl,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key(key, userId),
      jsonEncode({
        'cachedAt': DateTime.now().toUtc().toIso8601String(),
        'ttlSeconds': ttl.inSeconds,
        'data': data,
      }),
    );
  }

  static Future<CacheEntry<dynamic>?> read({
    required String key,
    required String userId,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key(key, userId));
    if (raw == null) return null;

    try {
      final value = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(value['cachedAt'] as String);
      final ttl = Duration(seconds: value['ttlSeconds'] as int);
      return CacheEntry(
        value['data'],
        stale: DateTime.now().toUtc().isAfter(cachedAt.add(ttl)),
      );
    } catch (_) {
      await remove(key: key, userId: userId);
      return null;
    }
  }

  static Future<void> remove({
    required String key,
    required String userId,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key(key, userId));
  }

  static Future<void> clearUser(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    final keys = preferences.getKeys().where(
      (key) => key.startsWith('$_prefix.$userId.'),
    );
    for (final key in keys) {
      await preferences.remove(key);
    }
  }

  static String _key(String key, String userId) => '$_prefix.$userId.$key';
}
