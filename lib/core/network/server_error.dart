import 'package:dio/dio.dart';

bool isServerConnectionError(Object e) {
  if (e is! DioException) return false;
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.badCertificate) {
    return true;
  }
  if (e.type == DioExceptionType.badResponse) {
    return (e.response?.statusCode ?? 0) >= 500;
  }
  return e.type == DioExceptionType.unknown && e.response == null;
}
