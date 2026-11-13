import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/config.dart';

import '../../core/network/dio_client.dart';

class RegisterService {
  final Dio _dio = DioClient.instance;

  // id rekening "Uang Tunai" diambil dari backend, tidak di-hardcode
  Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password,
    required String fullName,
    required String age, // MM-DD-YYYY, format yang diminta backend
    required String gender, // 'male' / 'female'
  }) async {
    try {
      final rekenings = await _dio.get(ApiRouteConfig.rekenings);
      final list = (rekenings.data['data'] as List)
          .cast<Map<String, dynamic>>();
      final cash = list.firstWhere(
        (r) => r['name'] == 'Uang Tunai',
        orElse: () => list.first,
      );

      final response = await _dio.post(
        ApiRouteConfig.register,
        data: {
          'email': email,
          'username': username,
          'password': password,
          'fullName': fullName,
          'age': age,
          'gender': gender,
          'roleId': 2, // DEFAULT_ROLE, sama seperti web
          'rekenings': [
            {'id': cash['id'], 'name': cash['name']},
          ],
        },
      );
      return response.data;
    } on DioException catch (e) {
      final message =
          e.response?.data?['error']?['message'] ?? 'Registrasi gagal';
      throw Exception(message);
    }
  }
}
