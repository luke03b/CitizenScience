/// Data transfer object for updating user profile information.
///
/// Contains the updated user details (name and email).
class UpdateUserRequest {
  final String nome;
  final String cognome;
  final String email;

  UpdateUserRequest({
    required this.nome,
    required this.cognome,
    required this.email,
  });

  /// Converts this request to a JSON map for API transmission.
  Map<String, dynamic> toJson() {
    return {'nome': nome, 'cognome': cognome, 'email': email};
  }
}
