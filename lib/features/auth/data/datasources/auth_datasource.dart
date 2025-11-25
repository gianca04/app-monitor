import 'package:dio/dio.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../../domain/exceptions/auth_exceptions.dart';
import 'package:monitor/core/constants/api_constants.dart';

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
        '${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}',
        data: request.toJson(),
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      return LoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw NetworkException('No se pudo conectar al servidor. Verifica tu conexión y la dirección del servidor.');
      }

      final data = e.response?.data;
      if (data != null) {
        if (data['errors'] != null) {
          final errors = Map<String, List<String>>.from(data['errors']);
          throw ValidationException(errors);
        }
        if (data['success'] == false && data['message'] == 'Credenciales inválidas') {
          throw InvalidCredentialsException();
        }
      }

      throw AuthException(data?['message'] ?? 'Error desconocido en login');
    }
  }
}