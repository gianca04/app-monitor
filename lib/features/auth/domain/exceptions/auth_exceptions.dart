class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends AuthException {
  NetworkException() : super('Error de conexión. Verifica tu conexión a internet.');
}

class ValidationException extends AuthException {
  final Map<String, List<String>> errors;

  ValidationException(this.errors) : super('Errores de validación');

  String get formattedErrors => errors.values.expand((list) => list).join('\n');
}

class InvalidCredentialsException extends AuthException {
  InvalidCredentialsException() : super('Credenciales inválidas');
}