import 'package:flutter_application_1/core/config.dart';
import 'package:flutter_application_1/core/network/dio_client.dart';

class UserService {
  static Map<String, dynamic>? _profile;
  static Future<Map<String, dynamic>>? _pending;

  static Future<Map<String, dynamic>> me() {
    final cached = _profile;
    if (cached != null) return Future.value(cached);
    return _pending ??= _fetch();
  }

  static Future<Map<String, dynamic>> refresh() {
    _profile = null;
    _pending = null;
    return me();
  }

  static void clear() {
    _profile = null;
    _pending = null;
  }

  static Future<Map<String, dynamic>> _fetch() async {
    try {
      final response = await DioClient.instance.get(ApiRouteConfig.usersMe);
      return _profile = response.data['data'] as Map<String, dynamic>;
    } catch (_) {
      _pending = null;
      rethrow;
    }
  }
}
