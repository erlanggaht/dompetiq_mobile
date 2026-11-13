import 'package:dio/dio.dart';

import 'package:flutter_application_1/core/config.dart';

import '../../core/network/dio_client.dart';

class ForgotPasswordService {
  final Dio _dio = DioClient.instance;

  // backend menerima username ATAU email di field yang sama
  Future<void> sendResetLink({required String username}) async {
    try {
      await _dio.post(
        ApiRouteConfig.resetPasswordSend,
        data: {'username': username},
      );
    } on DioException catch (e) {
      final message = e.response?.data?['error']?['message'] ??
          'Failed to send reset link';
      throw Exception(message);
    }
  }
}
