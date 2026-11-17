import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DioClient {
  static const _baseUrl = String.fromEnvironment("API_URL");
  static const _sessionCookieName = '_Host-session';

  static final navigatorKey = GlobalKey<NavigatorState>();

  static final Map<String, String> _cookies = {};
  static String? _sessionCookie;

  static const _authEndpoints = [
    '/auth/login',
    '/auth/create-account',
    '/auth/reset-password/send',
    '/auth/reset-pin/send',
  ];

  static final Dio _dio =
      Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
            extra: {'withCredentials': true},
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
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
            onError: (error, handler) {
              if (error.response != null) {
                _captureSession(error.response!);
              }
              final isAuthRequest = _authEndpoints.any(
                (endpoint) => error.requestOptions.uri.path.contains(endpoint),
              );
              if (error.response?.statusCode == 401 && !isAuthRequest) {
                clearSession();
                navigatorKey.currentState?.pushNamedAndRemoveUntil(
                  '/auth/login',
                  (route) => false,
                );
              }
              handler.next(error);
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
      final value = nameValue.substring(separator + 1);
      if (value.isEmpty) {
        _cookies.remove(name);
        if (name == _sessionCookieName) {
          _sessionCookie = null;
          _storage.delete(key: _sessionCookieName);
        }
        continue;
      }
      _cookies[name] = value;
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
