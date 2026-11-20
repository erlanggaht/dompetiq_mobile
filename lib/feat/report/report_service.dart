import 'package:dio/dio.dart';

import 'package:flutter_application_1/core/config.dart';
import 'package:flutter_application_1/core/network/dio_client.dart';

class ReportService {
  final Dio _dio = DioClient.instance;

  Future<Map<String, dynamic>> monthlySummary(String month) async {
    try {
      final response = await _dio.get(
        ApiRouteConfig.monthlySummary,
        queryParameters: {'month': month, 'language': 'en'},
      );
      return response.data['data'] as Map<String, dynamic>? ?? {};
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['error']?['message'] ?? 'Failed to load report',
      );
    }
  }
}
