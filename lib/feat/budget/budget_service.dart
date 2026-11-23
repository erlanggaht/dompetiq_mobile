import 'package:dio/dio.dart';

import 'package:flutter_application_1/core/config.dart';
import 'package:flutter_application_1/core/network/dio_client.dart';
import 'package:flutter_application_1/core/cache_manager.dart';
import 'package:flutter_application_1/feat/user/user_service.dart';

class BudgetService {
  final Dio _dio = DioClient.instance;

  Future<List<Map<String, dynamic>>> budgets() async {
    final userId = '${(await UserService.me())['id']}';
    final cached = await CacheManager.read(key: 'budgets', userId: userId);
    if (cached != null && !cached.stale) {
      return (cached.data as List).cast<Map<String, dynamic>>();
    }
    try {
      final response = await _dio.get(ApiRouteConfig.budget);
      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      final result = (data['budgets'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      await CacheManager.write(
        key: 'budgets',
        userId: userId,
        data: result,
        ttl: const Duration(minutes: 1),
      );
      await CacheManager.clearAll();
      return result;
    } on DioException catch (e) {
      if (cached != null) {
        return (cached.data as List).cast<Map<String, dynamic>>();
      }
      throw Exception(_message(e, 'Failed to load budgets'));
    }
  }

  Future<void> create({
    required String periodType,
    required int categoryUserId,
    required int allocated,
  }) async {
    try {
      await _dio.post(
        ApiRouteConfig.budget,
        data: {
          'periodType': periodType,
          'categoryUserId': categoryUserId,
          'allocated': allocated,
        },
      );
      await CacheManager.clearAll();
    } on DioException catch (e) {
      throw Exception(_message(e, 'Failed to create budget'));
    }
  }

  Future<void> updateItem(int id, int allocated) async {
    try {
      await _dio.patch(
        '${ApiRouteConfig.budget}/item/$id',
        data: {'allocated': allocated},
      );
    } on DioException catch (e) {
      throw Exception(_message(e, 'Failed to update budget'));
    }
  }

  Future<void> deleteItem(int id) async {
    try {
      await _dio.delete('${ApiRouteConfig.budget}/item/$id');
      await CacheManager.clearAll();
    } on DioException catch (e) {
      throw Exception(_message(e, 'Failed to delete budget'));
    }
  }

  String _message(DioException e, String fallback) =>
      e.response?.data?['error']?['message'] ?? fallback;
}
