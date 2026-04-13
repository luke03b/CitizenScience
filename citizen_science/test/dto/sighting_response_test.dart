import 'package:flutter_test/flutter_test.dart';
import 'package:citizen_science/dto/sighting_response.dart';

void main() {
  group('SightingResponse', () {
    final baseJson = <String, dynamic>{
      'id': 's1',
      'nome': 'Rosa Canina',
      'latitudine': 45.4642,
      'longitudine': 9.1900,
      'data': '2024-06-15T10:30:00.000Z',
      'userId': 'u1',
      'userNome': 'Mario',
      'userCognome': 'Rossi',
      'note': 'Bella rosa',
      'indirizzo': 'Via Roma 1',
      'photoUrls': ['/api/photos/img1.jpg'],
      'aiModelUsed': 'resnet50',
      'aiConfidence': 0.92,
    };

    test('fromJson parses all required fields', () {
      // Act
      final response = SightingResponse.fromJson(baseJson);

      // Assert
      expect(response.id, 's1');
      expect(response.nome, 'Rosa Canina');
      expect(response.latitudine, 45.4642);
      expect(response.longitudine, 9.1900);
      expect(response.userId, 'u1');
    });

    test('fromJson parses optional user name fields', () {
      // Act
      final response = SightingResponse.fromJson(baseJson);

      // Assert
      expect(response.userNome, 'Mario');
      expect(response.userCognome, 'Rossi');
    });

    test('fromJson parses optional note and indirizzo', () {
      // Act
      final response = SightingResponse.fromJson(baseJson);

      // Assert
      expect(response.note, 'Bella rosa');
      expect(response.indirizzo, 'Via Roma 1');
    });

    test('fromJson parses photoUrls list', () {
      // Act
      final response = SightingResponse.fromJson(baseJson);

      // Assert
      expect(response.photoUrls, ['/api/photos/img1.jpg']);
    });

    test('fromJson parses aiModelUsed and aiConfidence', () {
      // Act
      final response = SightingResponse.fromJson(baseJson);

      // Assert
      expect(response.aiModelUsed, 'resnet50');
      expect(response.aiConfidence, closeTo(0.92, 0.001));
    });

    test('fromJson parses date as DateTime', () {
      // Act
      final response = SightingResponse.fromJson(baseJson);

      // Assert
      expect(response.data, isA<DateTime>());
      expect(response.data.year, 2024);
      expect(response.data.month, 6);
      expect(response.data.day, 15);
    });

    test('fromJson handles null optional fields', () {
      // Arrange
      final json = Map<String, dynamic>.from(baseJson)
        ..['userNome'] = null
        ..['userCognome'] = null
        ..['note'] = null
        ..['indirizzo'] = null
        ..['aiModelUsed'] = null
        ..['aiConfidence'] = null;

      // Act
      final response = SightingResponse.fromJson(json);

      // Assert
      expect(response.userNome, isNull);
      expect(response.userCognome, isNull);
      expect(response.note, isNull);
      expect(response.indirizzo, isNull);
      expect(response.aiModelUsed, isNull);
      expect(response.aiConfidence, isNull);
    });

    test('fromJson handles empty photoUrls list', () {
      // Arrange
      final json = Map<String, dynamic>.from(baseJson)..['photoUrls'] = [];

      // Act
      final response = SightingResponse.fromJson(json);

      // Assert
      expect(response.photoUrls, isEmpty);
    });

    test('fromJson handles null photoUrls', () {
      // Arrange
      final json = Map<String, dynamic>.from(baseJson)..['photoUrls'] = null;

      // Act
      final response = SightingResponse.fromJson(json);

      // Assert
      expect(response.photoUrls, isEmpty);
    });

    test('toJson serializes all fields', () {
      // Arrange
      final response = SightingResponse.fromJson(baseJson);

      // Act
      final json = response.toJson();

      // Assert
      expect(json['id'], 's1');
      expect(json['nome'], 'Rosa Canina');
      expect(json['latitudine'], 45.4642);
      expect(json['longitudine'], 9.1900);
      expect(json['photoUrls'], ['/api/photos/img1.jpg']);
      expect(json['aiModelUsed'], 'resnet50');
    });

    test('fromJson round-trips correctly through toJson', () {
      // Act
      final original = SightingResponse.fromJson(baseJson);
      final roundTripped = SightingResponse.fromJson(original.toJson());

      // Assert
      expect(roundTripped.id, original.id);
      expect(roundTripped.nome, original.nome);
      expect(roundTripped.userId, original.userId);
      expect(roundTripped.photoUrls, original.photoUrls);
    });
  });
}
