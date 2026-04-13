import 'package:flutter_test/flutter_test.dart';
import 'package:citizen_science/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('fullName returns first and last name concatenated', () {
      // Arrange
      final user = UserModel(
        id: '1',
        firstName: 'Mario',
        lastName: 'Rossi',
        email: 'mario@example.com',
      );

      // Act & Assert
      expect(user.fullName, 'Mario Rossi');
    });

    test('isResearcher returns true when role is ricercatore', () {
      // Arrange
      final user = UserModel(
        id: '1',
        firstName: 'Mario',
        lastName: 'Rossi',
        email: 'mario@example.com',
        role: 'ricercatore',
      );

      // Act & Assert
      expect(user.isResearcher, isTrue);
    });

    test('isResearcher is case-insensitive', () {
      // Arrange
      final user = UserModel(
        id: '1',
        firstName: 'Mario',
        lastName: 'Rossi',
        email: 'mario@example.com',
        role: 'RICERCATORE',
      );

      // Act & Assert
      expect(user.isResearcher, isTrue);
    });

    test('isResearcher returns false when role is utente', () {
      // Arrange
      final user = UserModel(
        id: '1',
        firstName: 'Mario',
        lastName: 'Rossi',
        email: 'mario@example.com',
        role: 'utente',
      );

      // Act & Assert
      expect(user.isResearcher, isFalse);
    });

    test('isResearcher returns false when role is null', () {
      // Arrange
      final user = UserModel(
        id: '1',
        firstName: 'Mario',
        lastName: 'Rossi',
        email: 'mario@example.com',
      );

      // Act & Assert
      expect(user.isResearcher, isFalse);
    });

    test('fullName with empty strings returns a single space', () {
      // Arrange
      final user = UserModel(
        id: '2',
        firstName: '',
        lastName: '',
        email: 'empty@example.com',
      );

      // Act & Assert
      expect(user.fullName, ' ');
    });
  });
}
