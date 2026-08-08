/// Mirrors the backend `LoginResponse` DTO returned by
/// `POST /auth/v1/staff-login`.
class LoginResponse {
  final String staffId;
  final String staffName;
  final List<String> roles;
  final String institutionName;
  final String authToken;

  const LoginResponse({
    required this.staffId,
    required this.staffName,
    required this.roles,
    required this.institutionName,
    required this.authToken,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      staffId: (json['staffId'] ?? '') as String,
      staffName: (json['staffName'] ?? '') as String,
      roles: (json['roles'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      institutionName: (json['institutionName'] ?? '') as String,
      authToken: (json['authToken'] ?? '') as String,
    );
  }
}
