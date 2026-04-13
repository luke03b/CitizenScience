import 'package:flutter_test/flutter_test.dart';
import 'package:citizen_science/dto/auth_response.dart';
import 'package:citizen_science/dto/user_response.dart';

void main() {
  group('AuthResponse', () {
    const validJson = {
      'token': 'jwt.token.here',
      'user': {
        'id': 'u1',
        'nome': 'Mario',
        'cognome': 'Rossi',
        'email': 'mario@example.com',
        'ruolo': 'utente',
      },
    };

    test('fromJson parses token correctly', () {
      // Act
      final response = AuthResponse.fromJson(validJson);

      // Assert
      expect(response.token, 'jwt.token.here');
    });

    test('fromJson parses nested user object', () {
      // Act
      final response = AuthResponse.fromJson(validJson);

      // Assert
      expect(response.user.nome, 'Mario');
      expect(response.user.cognome, 'Rossi');
      expect(response.user.email, 'mario@example.com');
      expect(response.user.ruolo, 'utente');
    });

    test('toJson serializes token correctly', () {
      // Arrange
      final user = UserResponse(
        id: 'u1',
        nome: 'Mario',
        cognome: 'Rossi',
        email: 'mario@example.com',
        ruolo: 'utente',
      );
      final response = AuthResponse(token: 'jwt.token.here', user: user);

      // Act
      final json = response.toJson();

      // Assert
      expect(json['token'], 'jwt.token.here');
    });

    test('toJson serializes nested user correctly', () {
      // Arrange
      final user = UserResponse(
        id: 'u1',
        nome: 'Mario',
        cognome: 'Rossi',
        email: 'mario@example.com',
        ruolo: 'utente',
      );
      final response = AuthResponse(token: 'token', user: user);

      // Act
      final json = response.toJson();
      final userJson = json['user'] as Map<String, dynamic>;

      // Assert
      expect(userJson['nome'], 'Mario');
      expect(userJson['cognome'], 'Rossi');
    });

    test('fromJson round-trips correctly through toJson', () {
      // Act
      final original = AuthResponse.fromJson(validJson);
      final roundTripped = AuthResponse.fromJson(original.toJson());

      // Assert
      expect(roundTripped.token, original.token);
      expect(roundTripped.user.id, original.user.id);
    });
  });
}
