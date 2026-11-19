import 'package:dio/dio.dart';

import 'package:flutter_application_1/core/config.dart';
import 'package:flutter_application_1/core/network/dio_client.dart';

class ResetDataService {
  Future<void> reset() async {
    try {
      await DioClient.instance.delete(ApiRouteConfig.resetData);
    } on DioException catch (e) {
      final message =
          e.response?.data?['error']?['message'] ?? 'Failed to reset data';
      throw Exception(message);
    }
  }
}
