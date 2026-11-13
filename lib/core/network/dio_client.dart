import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DioClient {
  static const _baseUrl = String.fromEnvironment("API_URL");
  static const _sessionCookieName = '_Host-session';
  static String? _sessionCookie;
  // beberapa cookie bisa aktif bersamaan (_Host-session, _tmpUser)
  static final Map<String, String> _cookies = {};

  static final Dio _dio =
      Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
            // web: browser baru menyimpan/mengirim cookie lintas origin kalau
            // request pakai withCredentials (diabaikan di Android/iOS)
            extra: {'withCredentials': true},
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            // backend auth-nya cookie-based: tempel session di tiap request
            onRequest: (options, handler) {
              if (_cookies.isNotEmpty) {
                options.headers['Cookie'] = _cookies.entries
                    .map((e) => '${e.key}=${e.value}')
                    .join('; ');
              }
              handler.next(options);
            },
            onResponse: (response, handler) {
              _captureSession(response);
              handler.next(response);
            },
          ),
        );

  static Dio get instance => _dio;

  static void _captureSession(Response response) {
    final setCookies = response.headers['set-cookie'];
    if (setCookies == null) return;
    for (final raw in setCookies) {
      final nameValue = raw.split(';').first;
      final separator = nameValue.indexOf('=');
      if (separator <= 0) continue;
      final name = nameValue.substring(0, separator).trim();
      // map menyimpan nilai saja; format "nama=nilai" dirakit saat dipakai
      _cookies[name] = nameValue.substring(separator + 1);
      if (name == _sessionCookieName) {
        _sessionCookie = nameValue;
        _storage.write(key: _sessionCookieName, value: nameValue);
      }
    }
  }

  static final _storage = FlutterSecureStorage();

  static Future<void> loadSession() async {
    _sessionCookie = await _storage.read(key: _sessionCookieName);
    if (_sessionCookie == null) return;
    final separator = _sessionCookie!.indexOf('=');
    if (separator > 0) {
      _cookies[_sessionCookieName] = _sessionCookie!.substring(separator + 1);
    }
  }

  static Future<void> clearSession() async {
    _sessionCookie = null;
    _cookies.remove(_sessionCookieName);
    _cookies.remove('_tmpUser');
    await _storage.delete(key: _sessionCookieName);
  }
}
