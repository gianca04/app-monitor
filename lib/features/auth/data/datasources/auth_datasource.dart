import 'package:dio/dio.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

abstract class AuthDataSource {
  Future<LoginResponse> login(LoginRequest request);
}

class AuthDataSourceImpl implements AuthDataSource {
  final Dio dio;

  AuthDataSourceImpl(this.dio);

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await dio.post(
        'http://127.0.0.1:8000/api/login',
        data: request.toJson(),
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      return LoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error en login');
    }
  }
}