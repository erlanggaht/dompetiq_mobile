import 'package:dio/dio.dart';

import 'package:flutter_application_1/core/config.dart';
import 'package:flutter_application_1/core/network/dio_client.dart';
import 'package:flutter_application_1/core/cache_manager.dart';
import 'package:flutter_application_1/feat/user/user_service.dart';

class SavingsService {
  final Dio _dio = DioClient.instance;

  Future<Map<String, dynamic>> load() async {
    final userId = '${(await UserService.me())['id']}';
    final cached = await CacheManager.read(key: 'savings', userId: userId);
    if (cached != null && !cached.stale) {
      return (cached.data as Map).cast<String, dynamic>();
    }
    try {
      final response = await _dio.get(ApiRouteConfig.savingsGoals);
      final result = response.data['data'] as Map<String, dynamic>;
      await CacheManager.write(
        key: 'savings',
        userId: userId,
        data: result,
        ttl: const Duration(minutes: 1),
      );
      return result;
    } on DioException catch (e) {
      if (cached != null) return (cached.data as Map).cast<String, dynamic>();
      throw Exception(
        e.response?.data?['error']?['message'] ??
            'Failed to load savings goals',
      );
    }
  }

  Future<List<Map<String, dynamic>>> activity() async {
    return _run(() async {
      final response = await _dio.get(ApiRouteConfig.savingsGoalActivity);
      return (response.data['data'] as List).cast<Map<String, dynamic>>();
    }, 'Failed to load savings activity');
  }

  Future<void> save({
    int? id,
    required String name,
    required int target,
    DateTime? deadline,
  }) => _run(() async {
    final data = {
      'name': name,
      'target': target,
      'deadline': deadline?.toUtc().toIso8601String(),
    };
    if (id == null) {
      await _dio.post(ApiRouteConfig.savingsGoals, data: data);
    } else {
      await _dio.patch('${ApiRouteConfig.savingsGoals}/$id', data: data);
    }
  }, 'Failed to save goal').then((_) => CacheManager.clearAll());

  Future<void> transfer({
    required int goalId,
    required int rekeningUserId,
    required int amount,
    required DateTime date,
  }) => _run(() async {
    await _dio.post(
      '${ApiRouteConfig.savingsGoals}/$goalId/transfers',
      data: {
        'rekeningUserId': rekeningUserId,
        'amount': amount,
        'date': date.toUtc().toIso8601String(),
      },
    );
  }, 'Failed to add money').then((_) => CacheManager.clearAll());

  Future<void> delete(int id) => _run(() async {
    await _dio.delete('${ApiRouteConfig.savingsGoals}/$id');
  }, 'Failed to delete goal').then((_) => CacheManager.clearAll());

  // Backend mixes two error shapes: {error: {message}} and {message}.
  Future<T> _run<T>(Future<T> Function() request, String fallback) async {
    try {
      return await request();
    } on DioException catch (e) {
      final data = e.response?.data;
      throw Exception(
        data?['error']?['message'] ?? data?['message'] ?? fallback,
      );
    }
  }
}
