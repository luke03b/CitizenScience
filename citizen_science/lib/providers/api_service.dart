import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../dto/auth_response.dart';
import '../dto/login_request.dart';
import '../dto/register_request.dart';
import '../dto/user_response.dart';
import '../dto/sighting_response.dart';
import '../dto/change_password_request.dart';
import '../dto/update_notes_request.dart';
import '../dto/update_user_request.dart';

/// Service class for handling all API communication.
///
/// Provides methods for authentication, user management, sightings,
/// and AI model operations. Manages JWT tokens for authenticated requests.
class ApiService {
  static const String _baseUrl = 'http://localhost:8080';

  /// API endpoint base URL with /api prefix.
  static String get apiUrl => '$_baseUrl/api';

  /// Base URL for serving static files (photos).
  static String get baseUrl => _baseUrl;

  String? _token;

  /// Sets the JWT token for authenticated requests.
  void setToken(String? token) {
    _token = token;
  }

  /// Returns headers for JSON requests, optionally including auth token.
  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {'Content-Type': 'application/json'};

    if (includeAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  /// Returns headers for multipart requests with auth token.
  Map<String, String> _getMultipartHeaders() {
    final headers = <String, String>{};

    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  /// Parses error messages from API response body.
  String _parseErrorMessage(String responseBody) {
    try {
      final Map<String, dynamic> errorData = jsonDecode(responseBody);
      if (errorData.containsKey('message')) {
        return errorData['message'];
      }
      if (errorData.containsKey('error')) {
        return errorData['error'];
      }
    } catch (e) {
      // Silently fail parsing
    }
    return 'Si è verificato un errore. Riprova.';
  }

  /// Authenticates user with email and password.
  ///
  /// Returns an [AuthResponse] containing JWT token and user data.
  /// Throws an [Exception] if authentication fails.
  Future<AuthResponse> login(LoginRequest request) async {
    final response = await http.post(
      Uri.parse('$apiUrl/auth/login'),
      headers: _getHeaders(includeAuth: false),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
      _token = authResponse.token;
      return authResponse;
    } else {
      throw Exception(_parseErrorMessage(response.body));
    }
  }

  /// Registers a new user account.
  ///
  /// Returns an [AuthResponse] containing JWT token and user data.
  /// Throws an [Exception] if registration fails.
  Future<AuthResponse> register(RegisterRequest request) async {
    final response = await http.post(
      Uri.parse('$apiUrl/auth/register'),
      headers: _getHeaders(includeAuth: false),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 201) {
      final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
      _token = authResponse.token;
      return authResponse;
    } else {
      throw Exception(_parseErrorMessage(response.body));
    }
  }

  /// Changes the current user's password.
  ///
  /// Requires [request] with old and new passwords.
  /// Returns success message or throws an [Exception] if change fails.
  Future<String> changePassword(ChangePasswordRequest request) async {
    final response = await http.put(
      Uri.parse('$apiUrl/auth/change-password'),
      headers: _getHeaders(),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data['message'];
    } else {
      throw Exception(_parseErrorMessage(response.body));
    }
  }

  /// Fetches the current authenticated user's information.
  ///
  /// Requires a valid JWT token.
  /// Throws an [Exception] if request fails.
  Future<UserResponse> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$apiUrl/users/me'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return UserResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_parseErrorMessage(response.body));
    }
  }

  /// Updates the current user's profile information.
  ///
  /// Returns updated [UserResponse] or throws an [Exception] if update fails.
  Future<UserResponse> updateCurrentUser(UpdateUserRequest request) async {
    final response = await http.put(
      Uri.parse('$apiUrl/users/me'),
      headers: _getHeaders(),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return UserResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_parseErrorMessage(response.body));
    }
  }

  /// Creates a new sighting with photos and location data.
  ///
  /// Uploads [photos] along with sighting metadata.
  /// When [aiModel] is provided it is sent to the backend as an override for
  /// this sighting only and does NOT change the user's default model selection.
  /// Returns the created [SightingResponse] or throws an [Exception] if creation fails.
  Future<SightingResponse> createSighting({
    required XFile photo,
    required DateTime data,
    required double latitudine,
    required double longitudine,
    String? note,
    String? aiModel,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$apiUrl/sightings'),
    );

    request.headers.addAll(_getMultipartHeaders());

    // Add photo
    final stream = http.ByteStream(photo.openRead());
    final length = await photo.length();

    // Determine content type from file extension
    String mimeType = 'image/jpeg';
    final extension = photo.path.toLowerCase().split('.').last;
    if (extension == 'png') {
      mimeType = 'image/png';
    } else if (extension == 'jpg' || extension == 'jpeg') {
      mimeType = 'image/jpeg';
    } else if (extension == 'gif') {
      mimeType = 'image/gif';
    } else if (extension == 'webp') {
      mimeType = 'image/webp';
    }

    final multipartFile = http.MultipartFile(
      'photo',
      stream,
      length,
      filename: photo.path.split('/').last,
      contentType: MediaType.parse(mimeType),
    );
    request.files.add(multipartFile);

    // Add other fields
    request.fields['data'] = data.toIso8601String();
    request.fields['latitudine'] = latitudine.toString();
    request.fields['longitudine'] = longitudine.toString();
    if (note != null && note.isNotEmpty) {
      request.fields['note'] = note;
    }
    if (aiModel != null && aiModel.isNotEmpty) {
      request.fields['aiModel'] = aiModel;
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return SightingResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_parseErrorMessage(response.body));
    }
  }

  /// Fetches all sightings from the database.
  ///
  /// Returns a list of [SightingResponse] objects.
  Future<List<SightingResponse>> getAllSightings() async {
    final response = await http.get(
      Uri.parse('$apiUrl/sightings'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => SightingResponse.fromJson(json)).toList();
    } else {
      throw Exception(_parseErrorMessage(response.body));
    }
  }

  /// Fetches all sightings created by a specific user.
  ///
  /// Returns a list of [SightingResponse] objects for the given [userId].
  Future<List<SightingResponse>> getSightingsByUser(String userId) async {
    final response = await http.get(
      Uri.parse('$apiUrl/sightings/user/$userId'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => SightingResponse.fromJson(json)).toList();
    } else {
      throw Exception(_parseErrorMessage(response.body));
    }
  }

  /// Fetches sightings within a radius of a geographic location.
  ///
  /// Returns sightings within [radiusKm] kilometers of coordinates [lat], [lng].
  Future<List<SightingResponse>> getSightingsByLocation({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$apiUrl/sightings/location?lat=$lat&lng=$lng&radiusKm=$radiusKm',
      ),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => SightingResponse.fromJson(json)).toList();
    } else {
      throw Exception(_parseErrorMessage(response.body));
    }
  }

  /// Updates the notes of a specific sighting.
  ///
  /// Returns updated [SightingResponse] or throws an [Exception] if update fails.
  Future<SightingResponse> updateSightingNotes(
    String id,
    UpdateNotesRequest request,
  ) async {
    final response = await http.put(
      Uri.parse('$apiUrl/sightings/$id/notes'),
      headers: _getHeaders(),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return SightingResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_parseErrorMessage(response.body));
    }
  }

  /// Deletes a sighting by ID.
  ///
  /// Throws an [Exception] if deletion fails.
  Future<void> deleteSighting(String id) async {
    final response = await http.delete(
      Uri.parse('$apiUrl/sightings/$id'),
      headers: _getHeaders(),
    );

    if (response.statusCode != 204) {
      throw Exception(_parseErrorMessage(response.body));
    }
  }

  /// Fetches the list of available AI models with their optional descriptions.
  ///
  /// Returns a list of model objects, each containing:
  /// - `name` (String): the model file name
  /// - `description` (String?): optional human-readable description
  Future<List<Map<String, dynamic>>> getAvailableAiModels() async {
    final response = await http.get(
      Uri.parse('$apiUrl/ai/models'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> models = data['models'];
      return models.map((m) => Map<String, dynamic>.from(m as Map)).toList();
    } else {
      throw Exception(_parseErrorMessage(response.body));
    }
  }

  /// Selects an AI model by name for species identification.
  ///
  /// Throws an [Exception] if selection fails.
  Future<void> selectAiModel(String modelName) async {
    final response = await http.post(
      Uri.parse('$apiUrl/ai/models/select'),
      headers: _getHeaders(),
      body: jsonEncode({'modelName': modelName}),
    );

    if (response.statusCode != 200) {
      throw Exception(_parseErrorMessage(response.body));
    }
  }

  /// Gets the currently selected AI model.
  ///
  /// Returns the name of the currently selected model, or null if none selected.
  Future<String?> getSelectedAiModel() async {
    final response = await http.get(
      Uri.parse('$apiUrl/ai/models/selected'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data['modelName'] as String?;
    } else if (response.statusCode == 404) {
      // No model selected yet
      return null;
    } else {
      throw Exception(_parseErrorMessage(response.body));
    }
  }

  /// Sets the system-wide default AI model.
  ///
  /// Pass an empty string to clear the current default (no default model).
  /// Throws an [Exception] if the model is not found or the request fails.
  Future<void> setDefaultAiModel(String modelName) async {
    final response = await http.post(
      Uri.parse('$apiUrl/ai/models/set-default'),
      headers: _getHeaders(),
      body: jsonEncode({'modelName': modelName}),
    );

    if (response.statusCode != 200) {
      throw Exception(_parseErrorMessage(response.body));
    }
  }
}
