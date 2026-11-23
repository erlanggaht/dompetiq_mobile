import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/config.dart';
import 'package:flutter_application_1/core/network/dio_client.dart';
import 'package:flutter_application_1/core/cache_manager.dart';
import 'package:flutter_application_1/feat/user/user_service.dart';

class CardService {
  final Dio _dio = DioClient.instance;

  String _message(DioException e, String fallback) =>
      e.response?.data?['error']?['message'] ?? fallback;

  Future<Map<String, dynamic>> load({bool isPrimary = false}) async {
    final userId = '${(await UserService.me())['id']}';
    final key = isPrimary ? 'card.primary' : 'cards';
    final cached = await CacheManager.read(key: key, userId: userId);
    if (cached != null && !cached.stale) {
      return (cached.data as Map).cast<String, dynamic>();
    }
    try {
      final response = await _dio.get(
        ApiRouteConfig.myCard,
        queryParameters: {'isPrimary': isPrimary},
      );
      final result = (response.data['data'] as Map).cast<String, dynamic>();
      await CacheManager.write(
        key: key,
        userId: userId,
        data: result,
        ttl: const Duration(minutes: 5),
      );
      return result;
    } on DioException catch (e) {
      if (cached != null) return (cached.data as Map).cast<String, dynamic>();
      throw Exception(_message(e, 'Failed to load cards'));
    }
  }

  Future<List<Map<String, dynamic>>> availableAccounts() async {
    try {
      final response = await _dio.get(ApiRouteConfig.rekenings);
      return (response.data['data'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(_message(e, 'Failed to load accounts'));
    }
  }

  Future<void> add({required int accountId, required String name}) async {
    try {
      await _dio.post(
        ApiRouteConfig.manageMyCard,
        data: {
          'rekenings': [
            {'id': accountId, 'name': name},
          ],
        },
      );
      await CacheManager.clearAll();
    } on DioException catch (e) {
      throw Exception(_message(e, 'Failed to add card'));
    }
  }

  Future<void> setActive(int rekeningUserId, bool isActive) async {
    try {
      await _dio.put(
        ApiRouteConfig.changeCardStatus,
        data: {'rekeningUserId': rekeningUserId, 'isActive': isActive},
      );
      await CacheManager.clearAll();
    } on DioException catch (e) {
      throw Exception(_message(e, 'Failed to update card status'));
    }
  }

  Future<void> setPrimary(int rekeningUserId) async {
    try {
      await _dio.put(
        ApiRouteConfig.changePrimaryCard,
        data: {'rekeningUserId': rekeningUserId},
      );
      await CacheManager.clearAll();
    } on DioException catch (e) {
      throw Exception(_message(e, 'Failed to set primary card'));
    }
  }

  Future<Map<String, dynamic>> close(
    int rekeningUserId, {
    int? targetRekeningUserId,
  }) async {
    try {
      final response = await _dio.put(
        '${ApiRouteConfig.closeMyCard}/$rekeningUserId',
        data: targetRekeningUserId == null
            ? null
            : {'targetRekeningUserId': targetRekeningUserId},
      );
      await CacheManager.clearAll();
      return (response.data['data'] as Map?)?.cast<String, dynamic>() ?? {};
    } on DioException catch (e) {
      throw Exception(_message(e, 'Failed to close card'));
    }
  }
}
