/// Data transfer object for sighting responses from the API.
///
/// Contains comprehensive information about a wildlife sighting including
/// location, date, photos, and associated user data.
class SightingResponse {
  final String id;
  final String nome;
  final double latitudine;
  final double longitudine;
  final DateTime data;
  final String userId;
  final String? userNome;
  final String? userCognome;
  final String? note;
  final String? indirizzo;
  final List<String> photoUrls;
  final String? aiModelUsed;
  final double? aiConfidence;

  SightingResponse({
    required this.id,
    required this.nome,
    required this.latitudine,
    required this.longitudine,
    required this.data,
    required this.userId,
    this.userNome,
    this.userCognome,
    this.note,
    this.indirizzo,
    required this.photoUrls,
    this.aiModelUsed,
    this.aiConfidence,
  });

  /// Creates a [SightingResponse] from a JSON map.
  factory SightingResponse.fromJson(Map<String, dynamic> json) {
    return SightingResponse(
      id: json['id'],
      nome: json['nome'],
      latitudine: json['latitudine'].toDouble(),
      longitudine: json['longitudine'].toDouble(),
      data: DateTime.parse(json['data']),
      userId: json['userId'],
      userNome: json['userNome'],
      userCognome: json['userCognome'],
      note: json['note'],
      indirizzo: json['indirizzo'],
      photoUrls: List<String>.from(json['photoUrls'] ?? []),
      aiModelUsed: json['aiModelUsed'],
      aiConfidence: json['aiConfidence']?.toDouble(),
    );
  }

  /// Converts this [SightingResponse] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'latitudine': latitudine,
      'longitudine': longitudine,
      'data': data.toIso8601String(),
      'userId': userId,
      'userNome': userNome,
      'userCognome': userCognome,
      'note': note,
      'indirizzo': indirizzo,
      'photoUrls': photoUrls,
      'aiModelUsed': aiModelUsed,
      'aiConfidence': aiConfidence,
    };
  }
}
