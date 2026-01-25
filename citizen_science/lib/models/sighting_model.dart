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
  });

  String get firstImage => images.isNotEmpty ? images.first : '';
  String get formattedDate => '${date.day}/${date.month}/${date.year}';
}
