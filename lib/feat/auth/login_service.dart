import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/config.dart';

import '../../../core/network/dio_client.dart';

class AuthService {
  final Dio _dio = DioClient.instance;

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    required String deviceId,
  }) async {
    try {
      final response = await _dio.post(
        ApiRouteConfig.login,
        data: {
          'username': username,
          'password': password,
          'deviceId': deviceId,
        },
      );
      return response.data;
    } on DioException catch (e) {
      final message = e.response?.data?['error']?['message'] ?? 'Login gagal';
      throw Exception(message);
    }
  }
}
