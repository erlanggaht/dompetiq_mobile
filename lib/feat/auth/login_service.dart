import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/config.dart';

import '../../../core/network/dio_client.dart';

class MaxDeviceException implements Exception {
  @override
  String toString() => 'Maksimal login di 5 perangkat';
}

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
      final codeError = e.response?.data?['error']?['codeError'];
      if (codeError == 'INVALID_DEVICE_LIMIT') throw MaxDeviceException();
      final message = e.response?.data?['error']?['message'] ?? 'Login gagal';
      throw Exception(message);
    }
  }

  Future<bool> isSessionValid() async {
    try {
      final response = await _dio.get(ApiRouteConfig.loginCheck);
      return response.data['data']?['isLogin'] == true;
    } on DioException {
      return false;
    }
  }

  Future<void> logout({required String deviceId}) async {
    try {
      await _dio.post(ApiRouteConfig.logout, data: {'deviceId': deviceId});
    } on DioException catch (e) {
      final message = e.response?.data?['error']?['message'] ?? 'Logout gagal';
      throw Exception(message);
    } finally {
      DioClient.clearSession();
    }
  }
}
