import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../app/constants/api_endpoints.dart';
import 'auth_models.dart';
import 'private_api_error.dart';

class AuthApi {
  final Dio dio;
  AuthApi({Dio? client, String? baseUrl})
    : dio =
          client ??
          Dio(
            BaseOptions(
              baseUrl: (baseUrl ?? ApiEndpoints.baseUrl).endsWith('/')
                  ? (baseUrl ?? ApiEndpoints.baseUrl)
                  : '${baseUrl ?? ApiEndpoints.baseUrl}/',
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 15),
            ),
          );
  Future<Map<String, dynamic>> request(
    String path, {
    Object? body,
    String method = 'POST',
    String? access,
    bool get = false,
  }) async {
    try {
      final response = await dio.request<Object?>(
        path,
        data: body,
        options: Options(
          method: get ? 'GET' : method,
          headers: access == null ? null : {'Authorization': 'Bearer $access'},
        ),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const AuthFailure(AuthProblem.protocol);
      }
      return data;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      throw AuthFailure(
        status == 403
            ? AuthProblem.permission
            : status == 409
            ? AuthProblem.conflict
            : status == 401
            ? AuthProblem.credentials
            : status == 429
            ? AuthProblem.rate
            : status == 503 || (status != null && status >= 500)
            ? AuthProblem.unavailable
            : status != null
            ? AuthProblem.validation
            : AuthProblem.network,
      );
    }
  }

  Future<Object?> privateRequest(
    String path, {
    Object? body,
    required String method,
    required String access,
  }) async {
    try {
      final response = await dio.request<Object?>(
        path,
        data: body,
        options: Options(
          method: method,
          headers: {'Authorization': 'Bearer $access'},
        ),
      );
      return response.data;
    } on DioException catch (error) {
      throw PrivateApiFailure.from(error);
    }
  }

  Future<Uint8List> download(String path, String access) async {
    try {
      final response = await dio.get<List<int>>(
        path,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Authorization': 'Bearer $access'},
        ),
      );
      return Uint8List.fromList(response.data!);
    } on DioException catch (error) {
      throw AuthFailure(
        error.response?.statusCode == 401
            ? AuthProblem.credentials
            : error.response?.statusCode == 404
            ? AuthProblem.validation
            : AuthProblem.network,
      );
    }
  }
}
