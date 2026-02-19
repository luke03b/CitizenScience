import 'user_response.dart';

/// Data transfer object for authentication responses.
/// 
/// Contains the JWT token and user information returned after
/// successful login or registration.
class AuthResponse {
  final String token;
  final UserResponse user;

  AuthResponse({
    required this.token,
    required this.user,
  });

  /// Creates an [AuthResponse] from a JSON map.
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
      user: UserResponse.fromJson(json['user']),
    );
  }

  /// Converts this [AuthResponse] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toJson(),
    };
  }
}
