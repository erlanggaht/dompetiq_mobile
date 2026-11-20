import 'package:dio/dio.dart';

import 'package:flutter_application_1/core/config.dart';
import 'package:flutter_application_1/core/network/dio_client.dart';

class NotificationService {
  final Dio _dio = DioClient.instance;

  Future<List<Map<String, dynamic>>> list() async {
    try {
      final response = await _dio.get(ApiRouteConfig.notifications);
      return (response.data['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['error']?['message'] ??
            'Failed to load notifications',
      );
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _dio.patch('${ApiRouteConfig.notifications}/$id/read');
    } on DioException {
      return;
    }
  }
}
