import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

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
    StorageConfig.refreshAvatarCache();
    return me();
  }

  static void clear() {
    _profile = null;
    _pending = null;
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String username,
    required String email,
    required String gender,
    required String age,
  }) async {
    try {
      final response = await DioClient.instance.patch(
        ApiRouteConfig.usersMe,
        data: {
          'fullName': fullName,
          'username': username,
          'email': email,
          'gender': gender,
          'age': age,
        },
      );
      _profile = response.data['data'] as Map<String, dynamic>;
      return _profile!;
    } on DioException catch (e) {
      final message =
          e.response?.data?['error']?['message'] ?? 'Failed to update profile';
      throw Exception(message);
    }
  }

  static Future<Map<String, dynamic>> uploadAvatar(XFile file) async {
    try {
      final response = await DioClient.instance.patch(
        '${ApiRouteConfig.usersMe}/avatar',
        data: FormData.fromMap({
          'avatar': MultipartFile.fromBytes(
            await file.readAsBytes(),
            filename: file.name,
          ),
        }),
      );
      _profile = response.data['data'] as Map<String, dynamic>;
      StorageConfig.refreshAvatarCache();
      return _profile!;
    } on DioException catch (e) {
      final message =
          e.response?.data?['error']?['message'] ?? 'Failed to upload avatar';
      throw Exception(message);
    }
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
