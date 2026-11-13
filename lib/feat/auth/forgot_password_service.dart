import 'package:dio/dio.dart';

import '../../core/network/dio_client.dart';

class ForgotPasswordService {
  final Dio _dio = DioClient.instance;

  // dipakai dua varian: reset password & reset PIN (beda endpoint, body sama)
  Future<void> sendResetLink({
    required String username,
    required String endpoint,
  }) async {
    try {
      await _dio.post(endpoint, data: {'username': username});
    } on DioException catch (e) {
      final message =
          e.response?.data?['error']?['message'] ?? 'Failed to send reset link';
      throw Exception(message);
    }
  }
}
