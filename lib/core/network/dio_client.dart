import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DioClient {
  static const _baseUrl = String.fromEnvironment("API_URL");
  static const _sessionCookieName = '_Host-session';
  static String? _sessionCookie;

  static final Dio _dio =
      Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (_sessionCookie != null) {
                options.headers['Cookie'] = _sessionCookie;
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
      if (raw.startsWith('$_sessionCookieName=')) {
        final cookie = raw.split(';').first;
        _sessionCookie = cookie;
        _storage.write(key: _sessionCookieName, value: cookie);
      }
    }
  }

  static final _storage = FlutterSecureStorage();

  // dipanggil sekali di main(): pulihkan session dari penyimpanan
  static Future<void> loadSession() async {
    _sessionCookie = await _storage.read(key: _sessionCookieName);
  }

  static Future<void> clearSession() async {
    _sessionCookie = null;
    await _storage.delete(key: _sessionCookieName);
  }

  // sementara: cek nilai yang ter-bake dari --dart-define-from-file
  static void debugEnv() {
    debugPrint('API_URL dari env.json = "$_baseUrl"');
    debugPrint('session cookie = ${_sessionCookie != null ? "ada" : "kosong"}');
  }
}
