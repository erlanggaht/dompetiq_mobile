import 'package:dio/dio.dart';

import 'package:flutter_application_1/core/config.dart';

import '../../core/network/dio_client.dart';

// GET /settings/security/pin (status) & PUT /settings/security/pin (simpan)
class SecurityService {
  final Dio _dio = DioClient.instance;

  // backend menuntut password akun HANYA jika user sudah punya PIN
  Future<bool> getPinStatus() async {
    try {
      final response = await _dio.get(ApiRouteConfig.securityPin);
      return response.data['data']?['hasPin'] == true;
    } on DioException catch (e) {
      final message =
          e.response?.data?['error']?['message'] ?? 'Failed to load PIN status';
      throw Exception(message);
    }
  }

  Future<void> savePin({
    required String pin,
    required String confirmPin,
    String? password,
  }) async {
    try {
      await _dio.put(
        ApiRouteConfig.securityPin,
        data: {
          'pin': pin,
          'confirmPin': confirmPin,
          if (password != null && password.isNotEmpty) 'password': password,
        },
      );
    } on DioException catch (e) {
      final message =
          e.response?.data?['error']?['message'] ?? 'Failed to save PIN';
      throw Exception(message);
    }
  }
}
