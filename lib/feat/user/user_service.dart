import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_application_1/core/config.dart';
import 'package:flutter_application_1/core/network/dio_client.dart';
import 'package:flutter_application_1/core/cache_manager.dart';

class UserService {
  static Map<String, dynamic>? _profile;
  static Future<Map<String, dynamic>>? _pending;

  static Future<Map<String, dynamic>> me() {
    final cached = _profile;
    if (cached != null) return Future.value(cached);
    return _pending ??= _fetchWithCache();
  }

  static Future<Map<String, dynamic>> refresh() {
    _profile = null;
    _pending = null;
    StorageConfig.refreshAvatarCache();
    return _refreshFromNetwork();
  }

  static Future<Map<String, dynamic>> _refreshFromNetwork() async {
    await CacheManager.remove(key: 'profile', userId: 'current');
    return _fetch();
  }

  static void clear() {
    _profile = null;
    _pending = null;
  }

  static Future<Map<String, dynamic>> _fetchWithCache() async {
    final cached = await CacheManager.read(key: 'profile', userId: 'current');
    if (cached != null && !cached.stale) {
      _profile = (cached.data as Map).cast<String, dynamic>();
      return _profile!;
    }
    try {
      return await _fetch();
    } catch (_) {
      if (cached != null) {
        _profile = (cached.data as Map).cast<String, dynamic>();
        return _profile!;
      }
      rethrow;
    }
  }

  static Future<void> _cacheProfile(Map<String, dynamic> profile) =>
      CacheManager.write(
        key: 'profile',
        userId: 'current',
        data: profile,
        ttl: const Duration(minutes: 10),
      );

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
      await _cacheProfile(_profile!);
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
      await _cacheProfile(_profile!);
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
      _profile = response.data['data'] as Map<String, dynamic>;
      await _cacheProfile(_profile!);
      return _profile!;
    } catch (_) {
      _pending = null;
      rethrow;
    }
  }
}
