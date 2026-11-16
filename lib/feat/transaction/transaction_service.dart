import 'package:dio/dio.dart';

import '../../core/config.dart';
import '../../core/network/dio_client.dart';

class TransactionService {
  final Dio _dio = DioClient.instance;

  Future<List<Map<String, dynamic>>> categories() async {
    try {
      final response = await _dio.get(
        ApiRouteConfig.categoryMe,
        queryParameters: {'flat': 'true', 'language': 'en'},
      );
      return (response.data['data'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(_message(e, 'Failed to load categories'));
    }
  }

  Future<List<Map<String, dynamic>>> rekenings() async {
    try {
      final response = await _dio.get(
        ApiRouteConfig.rekeningMe,
        queryParameters: {'flat': 'true'},
      );
      return (response.data['data'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(_message(e, 'Failed to load accounts'));
    }
  }

  Future<void> create({
    required String type,
    required int amount,
    required int categoryId,
    required int rekeningUserId,
    required String transactionDate,
    required String description,
  }) async {
    try {
      await _dio.post(
        ApiRouteConfig.financialRecord,
        data: {
          'type': type,
          'amount': amount,
          'categoryId': categoryId,
          'rekeningUserId': rekeningUserId,
          'transactionDate': transactionDate,
          'description': description,
        },
      );
    } on DioException catch (e) {
      throw Exception(_message(e, 'Failed to save transaction'));
    }
  }

  String _message(DioException e, String fallback) =>
      e.response?.data?['error']?['message'] ?? fallback;
}
