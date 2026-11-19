import 'package:dio/dio.dart';

import 'package:flutter_application_1/core/config.dart';
import 'package:flutter_application_1/core/network/dio_client.dart';

class ChangePasswordService {
  Future<void> change({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await DioClient.instance.patch(
        ApiRouteConfig.changePassword,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      final message =
          e.response?.data?['error']?['message'] ?? 'Failed to change password';
      throw Exception(message);
    }
  }
}
