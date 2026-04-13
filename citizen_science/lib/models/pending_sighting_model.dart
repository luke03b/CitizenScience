/// Model representing a sighting waiting to be uploaded to the server.
///
/// Contains all necessary information to create a sighting once network
/// connection is restored, including photos stored as base64 strings.
class PendingSightingModel {
  final String id;
  final List<String> photoPaths;
  final DateTime date;
  final double latitude;
  final double longitude;
  final String? notes;
  final DateTime createdAt;

  PendingSightingModel({
    required this.id,
    required this.photoPaths,
    required this.date,
    required this.latitude,
    required this.longitude,
    this.notes,
    required this.createdAt,
  });

  /// Converts the model to a JSON map for storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'photoPaths': photoPaths,
      'date': date.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Creates a model instance from a JSON map.
  factory PendingSightingModel.fromJson(Map<String, dynamic> json) {
    return PendingSightingModel(
      id: json['id'],
      photoPaths: List<String>.from(json['photoPaths']),
      date: DateTime.parse(json['date']),
      latitude: json['latitude'],
      longitude: json['longitude'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
