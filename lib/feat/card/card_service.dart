import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/config.dart';
import 'package:flutter_application_1/core/network/dio_client.dart';

class CardService {
  final Dio _dio = DioClient.instance;

  String _message(DioException e, String fallback) =>
      e.response?.data?['error']?['message'] ?? fallback;

  Future<Map<String, dynamic>> load({bool isPrimary = false}) async {
    try {
      final response = await _dio.get(
        ApiRouteConfig.myCard,
        queryParameters: {'isPrimary': isPrimary},
      );
      return (response.data['data'] as Map).cast<String, dynamic>();
    } on DioException catch (e) {
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
      return (response.data['data'] as Map?)?.cast<String, dynamic>() ?? {};
    } on DioException catch (e) {
      throw Exception(_message(e, 'Failed to close card'));
    }
  }
}
