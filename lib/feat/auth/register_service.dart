import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/config.dart';

import '../../core/network/dio_client.dart';

class RegisterService {
  final Dio _dio = DioClient.instance;

  Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      final rekenings = await _dio.get(ApiRouteConfig.rekenings);
      final list = (rekenings.data['data'] as List)
          .cast<Map<String, dynamic>>();
      if (list.isEmpty) throw Exception('Data rekening belum tersedia');
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
          'fullName': username,
          'age': '01-01-2000',
          'gender': 'unknown',
          'roleId': 2,
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
