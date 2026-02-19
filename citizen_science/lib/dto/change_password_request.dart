/// Data transfer object for password change requests.
/// 
/// Contains the old and new passwords for updating a user's password.
class ChangePasswordRequest {
  final String oldPassword;
  final String newPassword;

  ChangePasswordRequest({
    required this.oldPassword,
    required this.newPassword,
  });

  /// Converts this request to a JSON map for API transmission.
  Map<String, dynamic> toJson() {
    return {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    };
  }
}
