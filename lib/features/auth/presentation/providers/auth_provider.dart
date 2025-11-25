import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../data/models/login_request.dart';
import '../../data/models/login_response.dart';
import '../../data/datasources/auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/exceptions/auth_exceptions.dart';

// Providers para dependencias
final dioProvider = Provider((ref) => Dio());
final authDataSourceProvider = Provider((ref) => AuthDataSourceImpl(ref.watch(dioProvider)));
final authRepositoryProvider = Provider((ref) => AuthRepositoryImpl(ref.watch(authDataSourceProvider)));
final loginUseCaseProvider = Provider((ref) => LoginUseCase(ref.watch(authRepositoryProvider)));

// Estado del auth
class AuthState {
  final bool isLoading;
  final String? error;
  final LoginResponse? response;

  AuthState({this.isLoading = false, this.error, this.response});

  AuthState copyWith({bool? isLoading, String? error, LoginResponse? response}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      response: response ?? this.response,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase loginUseCase;

  AuthNotifier(this.loginUseCase) : super(AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final request = LoginRequest(email: email, password: password);
      final response = await loginUseCase(request);
      state = state.copyWith(isLoading: false, response: response);
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
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final loginUseCase = ref.watch(loginUseCaseProvider);
  return AuthNotifier(loginUseCase);
});