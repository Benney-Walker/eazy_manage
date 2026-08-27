class LoginResponse {
  final String staffName;
  final List<String> roles;
  final String institutionName;
  final String authToken;
  final String refreshToken;

  const LoginResponse({
    required this.staffName,
    required this.roles,
    required this.institutionName,
    required this.authToken,
    required this.refreshToken,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      staffName: (json['staffName'] ?? '') as String,
      roles: (json['roles'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      institutionName: (json['institutionName'] ?? '') as String,
      authToken: (json['authToken'] ?? '') as String,
      refreshToken: (json['refreshToken'] ?? '') as String,
    );
  }
}