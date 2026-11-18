import 'package:dio/dio.dart';

import '../../core/config.dart';
import '../../core/network/dio_client.dart';

String apiDate(DateTime value) {
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  return '$m-$d-${value.year}';
}

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

  Future<List<Map<String, dynamic>>> records({
    int pageSize = 50,
    String? type,
    String? search,
    int? rekeningUserId,
    int? categoryId,
    DateTime? start,
    DateTime? end,
  }) async {
    try {
      final response = await _dio.get(
        ApiRouteConfig.financialRecord,
        queryParameters: {
          'pageSize': pageSize,
          'qtype': ?type,
          'q': ?(search == null || search.isEmpty ? null : search),
          'qrekeningUserId': ?rekeningUserId?.toString(),
          'qcategoryUserId': ?categoryId?.toString(),
          'qtransactionDate': ?(start == null ? null : apiDate(start)),
          'qtransactionDateEnd': ?(end == null ? null : apiDate(end)),
        },
      );
      return (response.data['data'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(_message(e, 'Failed to load transactions'));
    }
  }

  Future<Map<String, dynamic>> getOne(String transactionId) async {
    try {
      final response = await _dio.get(
        '${ApiRouteConfig.financialRecord}/$transactionId',
      );
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_message(e, 'Failed to load transaction'));
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

  Future<void> update({
    required String transactionId,
    required String type,
    required int amount,
    required int categoryId,
    required int rekeningUserId,
    required String transactionDate,
    required String description,
  }) async {
    try {
      await _dio.put(
        '${ApiRouteConfig.financialRecord}/$transactionId',
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

  Future<void> delete(String transactionId) async {
    try {
      await _dio.delete('${ApiRouteConfig.financialRecord}/$transactionId');
    } on DioException catch (e) {
      throw Exception(_message(e, 'Failed to delete transaction'));
    }
  }

  String _message(DioException e, String fallback) =>
      e.response?.data?['error']?['message'] ?? fallback;
}
