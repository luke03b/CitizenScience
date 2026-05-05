/// Model representing a wildlife sighting in the EcoFlora app.
///
/// Contains information about the sighting including location,
/// date, images, and associated user data.
class SightingModel {
  final String id;
  final String userId;
  final String userName;
  final String flowerName;
  final String location;
  final DateTime date;
  final List<String> images;
  final String notes;
  final double latitude;
  final double longitude;
  final String? aiModelUsed;
  final double? aiConfidence;

  SightingModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.flowerName,
    required this.location,
    required this.date,
    required this.images,
    required this.notes,
    required this.latitude,
    required this.longitude,
    this.aiModelUsed,
    this.aiConfidence,
  });

  /// Returns the first image URL, or empty string if no images.
  String get firstImage => images.isNotEmpty ? images.first : '';

  /// Returns the date formatted as DD/MM/YYYY.
  String get formattedDate => '${date.day}/${date.month}/${date.year}';
}
