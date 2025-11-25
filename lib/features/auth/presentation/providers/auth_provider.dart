import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../data/models/login_request.dart';
import '../../data/models/login_response.dart';
import '../../data/datasources/auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/exceptions/auth_exceptions.dart';

// Providers para dependencias
final dioProvider = Provider((ref) => Dio());
final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());
final authDataSourceProvider = Provider((ref) => AuthDataSourceImpl(ref.watch(dioProvider)));
final authRepositoryProvider = Provider((ref) => AuthRepositoryImpl(ref.watch(authDataSourceProvider)));
final loginUseCaseProvider = Provider((ref) => LoginUseCase(ref.watch(authRepositoryProvider)));

// Estado del auth
class AuthState {
  final bool isLoading;
  final bool isLoggedIn;
  final bool isChecking;
  final String? error;
  final LoginResponse? response;

  AuthState({this.isLoading = false, this.isLoggedIn = false, this.isChecking = true, this.error, this.response});

  AuthState copyWith({bool? isLoading, bool? isLoggedIn, bool? isChecking, String? error, LoginResponse? response}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isChecking: isChecking ?? this.isChecking,
      error: error ?? this.error,
      response: response ?? this.response,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase loginUseCase;
  final FlutterSecureStorage secureStorage;

  AuthNotifier(this.loginUseCase, this.secureStorage) : super(AuthState()) {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final token = await secureStorage.read(key: 'auth_token');
    final expiresAtStr = await secureStorage.read(key: 'expires_at');
    if (token != null && token.isNotEmpty && expiresAtStr != null) {
      final expiresAt = DateTime.parse(expiresAtStr);
      if (DateTime.now().isBefore(expiresAt)) {
        state = state.copyWith(isLoggedIn: true, isChecking: false);
      } else {
        // Token expirado, limpiar
        await secureStorage.delete(key: 'auth_token');
        await secureStorage.delete(key: 'expires_at');
        state = state.copyWith(isChecking: false);
      }
    } else {
      state = state.copyWith(isChecking: false);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final request = LoginRequest(email: email, password: password);
      final response = await loginUseCase(request);
      await secureStorage.write(key: 'auth_token', value: response.token);
      await secureStorage.write(key: 'expires_at', value: response.expiresAt.toIso8601String());
      state = state.copyWith(isLoading: false, isLoggedIn: true, response: response);
    } catch (e) {
      String errorMessage;
      if (e is NetworkException) {
        errorMessage = e.message;
      } else if (e is ValidationException) {
        errorMessage = e.formattedErrors;
      } else if (e is InvalidCredentialsException) {
        errorMessage = e.message;
      } else if (e is AuthException) {
        errorMessage = e.message;
      } else {
        errorMessage = 'Error desconocido';
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  Future<void> logout() async {
    await secureStorage.delete(key: 'auth_token');
    await secureStorage.delete(key: 'expires_at');
    state = state.copyWith(isLoggedIn: false, response: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final loginUseCase = ref.watch(loginUseCaseProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthNotifier(loginUseCase, secureStorage);
});