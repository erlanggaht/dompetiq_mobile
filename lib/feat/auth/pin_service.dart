import 'package:dio/dio.dart';

import 'package:flutter_application_1/core/config.dart';

import '../../core/network/dio_client.dart';
import 'login_service.dart';

class PinLockedException implements Exception {
  final String message;

  PinLockedException(this.message);

  @override
  String toString() => message;
}

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
      // limit device juga dicek di completeLogin
      final codeError = e.response?.data?['error']?['codeError'];
      if (codeError == 'INVALID_DEVICE_LIMIT') throw MaxDeviceException();
      final message =
          e.response?.data?['error']?['message'] ?? 'Verifikasi PIN gagal';
      // 429 dari limiter maupun batas attempt
      if (e.response?.statusCode == 429) throw PinLockedException(message);
      throw Exception(message);
    }
  }
}
