/// Data transfer object for user responses from the API.
///
/// Contains user profile information returned from authentication
/// and user management endpoints.
class UserResponse {
  final String id;
  final String nome;
  final String cognome;
  final String email;
  final String ruolo;

  UserResponse({
    required this.id,
    required this.nome,
    required this.cognome,
    required this.email,
    required this.ruolo,
  });

  /// Creates a [UserResponse] from a JSON map.
  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'],
      nome: json['nome'],
      cognome: json['cognome'],
      email: json['email'],
      ruolo: json['ruolo'],
    );
  }

  /// Converts this [UserResponse] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'cognome': cognome,
      'email': email,
      'ruolo': ruolo,
    };
  }

  /// Returns the full name combining nome and cognome.
  String get fullName => '$nome $cognome';
}
