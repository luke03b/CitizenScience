import 'package:flutter_test/flutter_test.dart';
import 'package:citizen_science/dto/user_response.dart';

void main() {
  group('UserResponse', () {
    const validJson = {
      'id': 'u1',
      'nome': 'Mario',
      'cognome': 'Rossi',
      'email': 'mario@example.com',
      'ruolo': 'ricercatore',
    };

    test('fromJson parses all fields correctly', () {
      // Act
      final response = UserResponse.fromJson(validJson);

      // Assert
      expect(response.id, 'u1');
      expect(response.nome, 'Mario');
      expect(response.cognome, 'Rossi');
      expect(response.email, 'mario@example.com');
      expect(response.ruolo, 'ricercatore');
    });

    test('fullName returns nome and cognome concatenated', () {
      // Act
      final response = UserResponse.fromJson(validJson);

      // Assert
      expect(response.fullName, 'Mario Rossi');
    });

    test('toJson serializes all fields correctly', () {
      // Arrange
      final response = UserResponse.fromJson(validJson);

      // Act
      final json = response.toJson();

      // Assert
      expect(json['id'], 'u1');
      expect(json['nome'], 'Mario');
      expect(json['cognome'], 'Rossi');
      expect(json['email'], 'mario@example.com');
      expect(json['ruolo'], 'ricercatore');
    });

    test('fromJson round-trips correctly through toJson', () {
      // Act
      final original = UserResponse.fromJson(validJson);
      final roundTripped = UserResponse.fromJson(original.toJson());

      // Assert
      expect(roundTripped.id, original.id);
      expect(roundTripped.nome, original.nome);
      expect(roundTripped.cognome, original.cognome);
      expect(roundTripped.email, original.email);
      expect(roundTripped.ruolo, original.ruolo);
    });
  });
}
