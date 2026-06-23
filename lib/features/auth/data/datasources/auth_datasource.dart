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

      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        final data = responseData['data'] as Map<String, dynamic>?;
        final tokenData = data?['token'] as Map<String, dynamic>?;

        if (tokenData == null || 
            tokenData['access_token'] == null || 
            tokenData['expires_at'] == null) {
          final msg = responseData['message'] ?? 'Respuesta de login inválida';
          throw AuthException(msg.toString());
        }
      } else if (responseData is String) {
        if (responseData.toLowerCase().contains('<html')) {
          throw AuthException('Acceso bloqueado o caída del servidor (respuesta HTML).');
        }
        throw AuthException(responseData);
      } else {
        throw AuthException('Respuesta del servidor no es un objeto válido');
      }

      return LoginResponse.fromJson(responseData);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw NetworkException('No se pudo conectar al servidor. Verifica tu conexión y la dirección del servidor.');
      }

      final data = e.response?.data;
      if (data != null && data is Map<String, dynamic>) {
        if (data['errors'] != null) {
          final errors = Map<String, List<String>>.from(data['errors']);
          throw ValidationException(errors);
        }
        if (data['success'] == false && data['message'] == 'Credenciales inválidas') {
          throw InvalidCredentialsException();
        }
        throw AuthException(data['message']?.toString() ?? 'Error desconocido en login');
      }

      if (data != null && data is String) {
        if (data.toLowerCase().contains('<html')) {
          throw AuthException('El servidor retornó un error en formato HTML. Posiblemente el servidor esté caído o el acceso esté restringido.');
        }
        throw AuthException(data);
      }

      throw AuthException('Error en la comunicación con el servidor: ${e.message}');
    } catch (e) {
      // Re-lanzar cualquier otra excepción (como AuthException ya capturada o errores de parseo)
      rethrow;
    }
  }
}