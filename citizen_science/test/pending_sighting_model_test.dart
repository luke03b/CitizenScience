import 'package:flutter_test/flutter_test.dart';
import 'package:citizen_science/models/pending_sighting_model.dart';

void main() {
  group('PendingSightingModel', () {
    test('toJson and fromJson should work correctly', () {
      final now = DateTime.now();
      final model = PendingSightingModel(
        id: '123',
        photoPaths: ['/path/to/photo1.jpg', '/path/to/photo2.jpg'],
        date: now,
        latitude: 45.4642,
        longitude: 9.1900,
        notes: 'Test notes',
        createdAt: now,
      );

      final json = model.toJson();
      final fromJson = PendingSightingModel.fromJson(json);

      expect(fromJson.id, model.id);
      expect(fromJson.photoPaths, model.photoPaths);
      expect(fromJson.date, model.date);
      expect(fromJson.latitude, model.latitude);
      expect(fromJson.longitude, model.longitude);
      expect(fromJson.notes, model.notes);
      expect(fromJson.createdAt, model.createdAt);
    });

    test('should handle null notes', () {
      final now = DateTime.now();
      final model = PendingSightingModel(
        id: '456',
        photoPaths: ['/path/to/photo.jpg'],
        date: now,
        latitude: 45.4642,
        longitude: 9.1900,
        notes: null,
        createdAt: now,
      );

      final json = model.toJson();
      final fromJson = PendingSightingModel.fromJson(json);

      expect(fromJson.notes, isNull);
    });
  });
}
