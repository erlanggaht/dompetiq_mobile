import 'package:flutter_application_1/core/config.dart';
import 'package:flutter_application_1/core/network/dio_client.dart';

// profil user cukup diambil sekali per sesi, dipakai drawer & home
class UserService {
  static Map<String, dynamic>? _profile;

  static Future<Map<String, dynamic>> me() async {
    final cached = _profile;
    if (cached != null) return cached;
    final response = await DioClient.instance.get(ApiRouteConfig.usersMe);
    return _profile = response.data['data'] as Map<String, dynamic>;
  }

  static void clear() => _profile = null;
}
