import 'package:flutter_test/flutter_test.dart';
import 'package:citizen_science/models/sighting_model.dart';

SightingModel _buildSighting({List<String>? images, DateTime? date}) {
  return SightingModel(
    id: '1',
    userId: 'u1',
    userName: 'Mario Rossi',
    flowerName: 'Rosa Canina',
    location: 'Milano',
    date: date ?? DateTime(2024, 6, 15),
    images: images ?? [],
    notes: 'Belle rose',
    latitude: 45.4642,
    longitude: 9.1900,
  );
}

void main() {
  group('SightingModel', () {
    group('firstImage', () {
      test('returns first URL when images list is non-empty', () {
        // Arrange
        final sighting = _buildSighting(
          images: [
            'http://example.com/img1.jpg',
            'http://example.com/img2.jpg',
          ],
        );

        // Act & Assert
        expect(sighting.firstImage, 'http://example.com/img1.jpg');
      });

      test('returns empty string when images list is empty', () {
        // Arrange
        final sighting = _buildSighting(images: []);

        // Act & Assert
        expect(sighting.firstImage, isEmpty);
      });

      test('returns single element when list has one image', () {
        // Arrange
        final sighting = _buildSighting(
          images: ['http://example.com/only.jpg'],
        );

        // Act & Assert
        expect(sighting.firstImage, 'http://example.com/only.jpg');
      });
    });

    group('formattedDate', () {
      test('returns date formatted as DD/MM/YYYY', () {
        // Arrange
        final sighting = _buildSighting(date: DateTime(2024, 6, 15));

        // Act & Assert
        expect(sighting.formattedDate, '15/6/2024');
      });

      test('formats single-digit day and month correctly', () {
        // Arrange
        final sighting = _buildSighting(date: DateTime(2023, 1, 5));

        // Act & Assert
        expect(sighting.formattedDate, '5/1/2023');
      });

      test('formats end-of-year date correctly', () {
        // Arrange
        final sighting = _buildSighting(date: DateTime(2022, 12, 31));

        // Act & Assert
        expect(sighting.formattedDate, '31/12/2022');
      });
    });

    test('stores aiModelUsed and aiConfidence when provided', () {
      // Arrange
      final sighting = SightingModel(
        id: '2',
        userId: 'u2',
        userName: 'Luigi Bianchi',
        flowerName: 'Tulipano',
        location: 'Roma',
        date: DateTime(2024, 3, 20),
        images: [],
        notes: '',
        latitude: 41.9028,
        longitude: 12.4964,
        aiModelUsed: 'resnet50',
        aiConfidence: 0.95,
      );

      // Act & Assert
      expect(sighting.aiModelUsed, 'resnet50');
      expect(sighting.aiConfidence, 0.95);
    });

    test('aiModelUsed and aiConfidence default to null', () {
      // Arrange
      final sighting = _buildSighting();

      // Act & Assert
      expect(sighting.aiModelUsed, isNull);
      expect(sighting.aiConfidence, isNull);
    });
  });
}
