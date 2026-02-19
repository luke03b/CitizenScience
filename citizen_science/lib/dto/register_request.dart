/// Data transfer object for user registration requests.
/// 
/// Contains all required information for creating a new user account.
class RegisterRequest {
  final String nome;
  final String cognome;
  final String email;
  final String password;
  final String ruolo;

  RegisterRequest({
    required this.nome,
    required this.cognome,
    required this.email,
    required this.password,
    this.ruolo = 'utente',
  });

  /// Converts this request to a JSON map for API transmission.
  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'cognome': cognome,
      'email': email,
      'password': password,
      'ruolo': ruolo,
    };
  }
}
