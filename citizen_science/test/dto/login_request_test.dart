import 'package:flutter_test/flutter_test.dart';
import 'package:citizen_science/dto/login_request.dart';

void main() {
  group('LoginRequest', () {
    test('toJson serializes email and password', () {
      // Arrange
      final request = LoginRequest(
        email: 'user@example.com',
        password: 'secret123',
      );

      // Act
      final json = request.toJson();

      // Assert
      expect(json['email'], 'user@example.com');
      expect(json['password'], 'secret123');
    });

    test('toJson contains exactly two keys', () {
      // Arrange
      final request = LoginRequest(email: 'a@b.com', password: 'pw');

      // Act
      final json = request.toJson();

      // Assert
      expect(json.keys, containsAll(['email', 'password']));
      expect(json.length, 2);
    });
  });
}
