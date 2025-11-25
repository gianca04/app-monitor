import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_datasource.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource dataSource;

  AuthRepositoryImpl(this.dataSource);

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    return await dataSource.login(request);
  }
}