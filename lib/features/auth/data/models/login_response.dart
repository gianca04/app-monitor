class LoginResponse {
  final String token;
  final DateTime expiresAt;
  final String message;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? employee;

  LoginResponse({
    required this.token,
    required this.expiresAt,
    required this.message,
    this.user,
    this.employee,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final tokenData = data?['token'] as Map<String, dynamic>?;
    return LoginResponse(
      token: tokenData?['access_token'] ?? '',
      expiresAt: DateTime.parse(tokenData?['expires_at'] ?? ''),
      message: json['message'] ?? '',
      user: data?['user'],
      employee: data?['employee'],
    );
  }
}