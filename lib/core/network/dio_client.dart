import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DioClient {
  static const _baseUrl = String.fromEnvironment("API_URL");
  static const _sessionCookieName = '_Host-session';
  static const _csrfCookieName = 'csrf_token';

  static final navigatorKey = GlobalKey<NavigatorState>();

  static final Map<String, String> _cookies = {};
  static String? _sessionCookie;
  static String? _csrfToken;
  static bool _sessionLoaded = false;
  static bool _sessionValidated = false;

  static const _authEndpoints = [
    '/auth/login',
    '/auth/create-account',
    '/auth/reset-password/send',
    '/auth/reset-pin/send',
    '/auth/csrf-token',
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
              debugPrint(
                '[session] request ${options.method} ${options.uri.path} '
                'hasCookie=${_cookies.containsKey(_sessionCookieName)}',
              );
              if (_cookies.isNotEmpty) {
                options.headers['Cookie'] = _cookies.entries
                    .map((e) => '${e.key}=${e.value}')
                    .join('; ');
              }
              if (_csrfToken != null) {
                options.headers['X-CSRF-Token'] = _csrfToken;
              }
              handler.next(options);
            },
            onResponse: (response, handler) {
              debugPrint(
                '[session] response ${response.requestOptions.uri.path} '
                'status=${response.statusCode} '
                'hasSetCookie=${response.headers['set-cookie'] != null}',
              );
              _captureSession(response);
              handler.next(response);
            },
            onError: (error, handler) async {
              debugPrint(
                '[session] error ${error.requestOptions.uri.path} '
                'status=${error.response?.statusCode} '
                'hasCookie=${_cookies.containsKey(_sessionCookieName)}',
              );
              if (error.response != null) {
                _captureSession(error.response!);
              }
              final codeError = error.response?.data?['error']?['codeError'];
              if (error.response?.statusCode == 403 &&
                  codeError == 'CSRF_INVALID' &&
                  error.requestOptions.extra['csrfRetried'] != true) {
                try {
                  final tokenResponse = await _dio.get('/auth/csrf-token');
                  final token = tokenResponse.data['data']?['token'] as String?;
                  if (token != null) {
                    _csrfToken = token;
                    _cookies[_csrfCookieName] = token;
                    await _storage.write(key: _csrfCookieName, value: token);
                  }
                  error.requestOptions.extra['csrfRetried'] = true;
                  final response = await _dio.fetch(error.requestOptions);
                  return handler.resolve(response);
                } catch (_) {
                  return handler.next(error);
                }
              }
              final isAuthRequest = _authEndpoints.any(
                (endpoint) => error.requestOptions.uri.path.contains(endpoint),
              );
              if (error.response?.statusCode == 401 &&
                  !isAuthRequest &&
                  _sessionLoaded &&
                  _sessionValidated) {
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

  static bool get hasSession => _sessionCookie != null;

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
        debugPrint(
          '[session] remove via set-cookie ${name == _sessionCookieName}',
        );
        _cookies.remove(name);
        if (name == _sessionCookieName) {
          _sessionCookie = null;
          _storage.delete(key: _sessionCookieName);
        }
        if (name == _csrfCookieName) {
          _csrfToken = null;
          _storage.delete(key: _csrfCookieName);
        }
        continue;
      }
      _cookies[name] = value;
      if (name == _sessionCookieName) {
        _sessionCookie = nameValue;
        _storage.write(key: _sessionCookieName, value: nameValue);
      }
      if (name == _csrfCookieName) {
        _csrfToken = value;
        _storage.write(key: _csrfCookieName, value: value);
      }
    }
  }

  static final _storage = FlutterSecureStorage();

  static Future<void> loadSession() async {
    _sessionValidated = false;
    _sessionCookie = await _storage.read(key: _sessionCookieName);
    _csrfToken = await _storage.read(key: _csrfCookieName);
    _sessionLoaded = true;
    debugPrint('[session] load storedCookie=${_sessionCookie != null}');
    if (_csrfToken != null) _cookies[_csrfCookieName] = _csrfToken!;
    if (_sessionCookie == null) return;
    final separator = _sessionCookie!.indexOf('=');
    if (separator > 0) {
      _cookies[_sessionCookieName] = _sessionCookie!.substring(separator + 1);
    }
  }

  static Future<void> clearSession() async {
    debugPrint(
      '[session] clearSession from ${StackTrace.current.toString().split('\n').take(4).join(' | ')}',
    );
    _sessionCookie = null;
    _cookies.remove(_sessionCookieName);
    _cookies.remove('_tmpUser');
    _csrfToken = null;
    await _storage.delete(key: _sessionCookieName);
    await _storage.delete(key: _csrfCookieName);
  }

  static void markSessionValidated(bool valid) {
    _sessionValidated = true;
    if (!valid) clearSession();
  }
}
