import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../data/models/login_request.dart';
import '../../data/models/login_response.dart';
import '../../data/datasources/auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/exceptions/auth_exceptions.dart';

// Providers para dependencias
final dioProvider = Provider((ref) => Dio());
final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main');
});

// Dio provider con autenticación
final authenticatedDioProvider = Provider((ref) {
  final dio = Dio();
  final secureStorage = ref.watch(secureStorageProvider);

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await secureStorage.read(key: 'auth_token');
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      options.headers['Accept'] = 'application/json';
      options.headers['Content-Type'] = 'application/json';
      return handler.next(options);
    },
  ));

  return dio;
});

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
  final SharedPreferences sharedPreferences;

  AuthNotifier(this.loginUseCase, this.secureStorage, this.sharedPreferences) : super(AuthState()) {
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

      // Guardar información del usuario y empleado en SharedPreferences
      if (response.user != null) {
        await sharedPreferences.setInt('user_id', response.user!['id']);
        await sharedPreferences.setString('user_name', response.user!['name']);
        await sharedPreferences.setString('user_email', response.user!['email']);
      }
      if (response.employee != null) {
        await sharedPreferences.setInt('employee_id', response.employee!['id']);
        await sharedPreferences.setString('employee_document_type', response.employee!['document_type']);
        await sharedPreferences.setString('employee_document_number', response.employee!['document_number']);
        await sharedPreferences.setString('employee_first_name', response.employee!['first_name']);
        await sharedPreferences.setString('employee_last_name', response.employee!['last_name']);
        await sharedPreferences.setString('employee_position', response.employee!['position']);
      }

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
    // Limpiar información del usuario y empleado
    await sharedPreferences.remove('user_id');
    await sharedPreferences.remove('user_name');
    await sharedPreferences.remove('user_email');
    await sharedPreferences.remove('employee_id');
    await sharedPreferences.remove('employee_document_type');
    await sharedPreferences.remove('employee_document_number');
    await sharedPreferences.remove('employee_first_name');
    await sharedPreferences.remove('employee_last_name');
    await sharedPreferences.remove('employee_position');
    state = state.copyWith(isLoggedIn: false, response: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final loginUseCase = ref.watch(loginUseCaseProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final sharedPreferences = ref.watch(sharedPreferencesProvider);
  return AuthNotifier(loginUseCase, secureStorage, sharedPreferences);
});