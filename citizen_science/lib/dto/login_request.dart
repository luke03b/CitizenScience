/// Data transfer object for login requests.
/// 
/// Contains user credentials for authentication.
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  /// Converts this request to a JSON map for API transmission.
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}
