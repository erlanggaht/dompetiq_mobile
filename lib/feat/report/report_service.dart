import 'package:dio/dio.dart';

import 'package:flutter_application_1/core/config.dart';
import 'package:flutter_application_1/core/network/dio_client.dart';
import 'package:flutter_application_1/core/cache_manager.dart';
import 'package:flutter_application_1/feat/user/user_service.dart';

class ReportService {
  final Dio _dio = DioClient.instance;

  Future<Map<String, dynamic>> monthlySummary(String month) async {
    final userId = '${(await UserService.me())['id']}';
    final cached = await CacheManager.read(
      key: 'report.$month',
      userId: userId,
    );
    if (cached != null && !cached.stale) {
      return (cached.data as Map).cast<String, dynamic>();
    }
    try {
      final response = await _dio.get(
        ApiRouteConfig.monthlySummary,
        queryParameters: {'month': month, 'language': 'en'},
      );
      final result = response.data['data'] as Map<String, dynamic>? ?? {};
      await CacheManager.write(
        key: 'report.$month',
        userId: userId,
        data: result,
        ttl: const Duration(minutes: 5),
      );
      return result;
    } on DioException catch (e) {
      if (cached != null) return (cached.data as Map).cast<String, dynamic>();
      throw Exception(
        e.response?.data?['error']?['message'] ?? 'Failed to load report',
      );
    }
  }
}
