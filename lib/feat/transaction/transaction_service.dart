import 'package:dio/dio.dart';

import '../../core/config.dart';
import '../../core/network/dio_client.dart';
import '../user/user_service.dart';
import '../../core/cache_manager.dart';

String apiDate(DateTime value) {
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  return '$m-$d-${value.year}';
}

class TransactionPage {
  final List<Map<String, dynamic>> items;
  final int total;

  const TransactionPage(this.items, this.total);
}

class TransactionService {
  final Dio _dio = DioClient.instance;
  static Future<void> clearOptionsCache() => CacheManager.clearAll();

  Future<List<Map<String, dynamic>>> categories() async {
    final userId = await _userId();
    final cached = await CacheManager.read(key: 'categories', userId: userId);
    if (cached != null && !cached.stale) {
      final result = (cached.data as List).cast<Map<String, dynamic>>();
      return result;
    }
    try {
      final response = await _dio.get(
        ApiRouteConfig.categoryMe,
        queryParameters: {'flat': 'true', 'language': 'en'},
      );
      final result = (response.data['data'] as List)
          .cast<Map<String, dynamic>>();
      await CacheManager.write(
        key: 'categories',
        userId: userId,
        data: result,
        ttl: const Duration(hours: 24),
      );
      return result;
    } on DioException catch (e) {
      if (cached != null) {
        return (cached.data as List).cast<Map<String, dynamic>>();
      }
      throw Exception(_message(e, 'Failed to load categories'));
    }
  }

  Future<List<Map<String, dynamic>>> rekenings() async {
    final userId = await _userId();
    final cached = await CacheManager.read(key: 'rekenings', userId: userId);
    if (cached != null && !cached.stale) {
      final result = (cached.data as List).cast<Map<String, dynamic>>();
      return result;
    }
    try {
      final response = await _dio.get(
        ApiRouteConfig.rekeningMe,
        queryParameters: {'flat': 'true'},
      );
      final result = (response.data['data'] as List)
          .cast<Map<String, dynamic>>();
      await CacheManager.write(
        key: 'rekenings',
        userId: userId,
        data: result,
        ttl: const Duration(minutes: 5),
      );
      return result;
    } on DioException catch (e) {
      if (cached != null) {
        return (cached.data as List).cast<Map<String, dynamic>>();
      }
      throw Exception(_message(e, 'Failed to load accounts'));
    }
  }

  Future<TransactionPage> records({
    int page = 1,
    int pageSize = 20,
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
          'page': page,
          'pageSize': pageSize,
          'qtype': ?type,
          'q': ?(search == null || search.isEmpty ? null : search),
          'qrekeningUserId': ?rekeningUserId?.toString(),
          'qcategoryUserId': ?categoryId?.toString(),
          'qtransactionDate': ?(start == null ? null : apiDate(start)),
          'qtransactionDateEnd': ?(end == null ? null : apiDate(end)),
        },
      );
      final items = (response.data['data'] as List)
          .cast<Map<String, dynamic>>();
      if (page == 1) {
        final activity = await _dio.get(ApiRouteConfig.savingsGoalActivity);
        items.addAll(
          (activity.data['data'] as List).cast<Map<String, dynamic>>(),
        );
      }
      final meta = response.data['meta'] as Map<String, dynamic>? ?? {};
      return TransactionPage(
        items,
        (meta['totalRowCount'] as num?)?.toInt() ?? 0,
      );
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

  Future<String> _userId() async {
    final profile = await UserService.me();
    return '${profile['id']}';
  }
}
