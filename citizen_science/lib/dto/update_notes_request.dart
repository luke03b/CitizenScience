/// Data transfer object for updating sighting notes.
///
/// Contains the updated note text for a sighting.
class UpdateNotesRequest {
  final String note;

  UpdateNotesRequest({required this.note});

  /// Converts this request to a JSON map for API transmission.
  Map<String, dynamic> toJson() {
    return {'note': note};
  }
}
