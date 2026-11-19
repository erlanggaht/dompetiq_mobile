import 'package:dio/dio.dart';

import 'package:flutter_application_1/core/config.dart';
import 'package:flutter_application_1/core/network/dio_client.dart';

class DeleteAccountService {
  Future<void> delete() async {
    try {
      await DioClient.instance.delete(ApiRouteConfig.deleteAccount);
    } on DioException catch (e) {
      final message =
          e.response?.data?['error']?['message'] ?? 'Failed to delete account';
      throw Exception(message);
    }
  }
}
