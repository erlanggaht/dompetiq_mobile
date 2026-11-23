import 'package:dio/dio.dart';

import 'package:flutter_application_1/core/config.dart';
import 'package:flutter_application_1/core/network/dio_client.dart';
import 'package:flutter_application_1/core/cache_manager.dart';
import 'package:flutter_application_1/feat/user/user_service.dart';

class NotificationService {
  final Dio _dio = DioClient.instance;

  Future<List<Map<String, dynamic>>> list() async {
    final userId = '${(await UserService.me())['id']}';
    final cached = await CacheManager.read(
      key: 'notifications',
      userId: userId,
    );
    if (cached != null && !cached.stale) {
      return (cached.data as List).cast<Map<String, dynamic>>();
    }
    try {
      final response = await _dio.get(ApiRouteConfig.notifications);
      final result = (response.data['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      await CacheManager.write(
        key: 'notifications',
        userId: userId,
        data: result,
        ttl: const Duration(seconds: 15),
      );
      return result;
    } on DioException catch (e) {
      if (cached != null) {
        return (cached.data as List).cast<Map<String, dynamic>>();
      }
      throw Exception(
        e.response?.data?['error']?['message'] ??
            'Failed to load notifications',
      );
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _dio.patch('${ApiRouteConfig.notifications}/$id/read');
      await CacheManager.clearAll();
    } on DioException {
      return;
    }
  }
}
