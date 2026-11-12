import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/config.dart';

import '../../core/network/dio_client.dart';

class PinService {
  final Dio _dio = DioClient.instance;

  Future<void> verifyLoginPin({
    required String challengeToken,
    required String pin,
  }) async {
    try {
      await _dio.post(
        ApiRouteConfig.loginPin,
        data: {'challengeToken': challengeToken, 'pin': pin},
      );
    } on DioException catch (e) {
      final message =
          e.response?.data?['error']?['message'] ?? 'Verifikasi PIN gagal';
      throw Exception(message);
    }
  }
}
