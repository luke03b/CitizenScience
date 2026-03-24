import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../models/sighting_model.dart';
import '../models/pending_sighting_model.dart';
import '../dto/login_request.dart';
import '../dto/register_request.dart';
import '../dto/user_response.dart';
import '../dto/update_user_request.dart';
import '../dto/sighting_response.dart';
import '../utils/url_utils.dart';
import '../services/connectivity_service.dart';
import '../services/offline_storage_service.dart';
import 'api_service.dart';

/// Provider managing application state including authentication and sightings.
/// 
/// Handles user authentication, JWT token management, and sighting data.
/// Notifies listeners when state changes occur.
class AppStateProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoggedIn = false;
  final List<SightingModel> _sightings = [];
  final List<PendingSightingModel> _pendingSightings = [];
  final ApiService _apiService = ApiService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final OfflineStorageService _offlineStorage = OfflineStorageService();
  String? _token;
  bool _isOnline = true;

  bool get isLoggedIn => _isLoggedIn;
  UserModel? get currentUser => _currentUser;
  bool get isOnline => _isOnline;
  
  /// Returns sightings created by the current user.
  List<SightingModel> get userSightings => _sightings.where((s) => s.userId == _currentUser?.id).toList();
  
  /// Returns all cached sightings.
  List<SightingModel> get allSightings => _sightings;
  
  /// Returns pending sightings waiting to be uploaded.
  List<PendingSightingModel> get pendingSightings => _pendingSightings;
  
  ApiService get apiService => _apiService;

  AppStateProvider() {
    _initConnectivityMonitoring();
  }

  /// Initializes connectivity monitoring.
  void _initConnectivityMonitoring() {
    _connectivityService.startMonitoring((hasConnection) async {
      _isOnline = hasConnection;
      notifyListeners();
      
      if (hasConnection && _isLoggedIn) {
        // Try to sync pending sightings when connection is restored
        await _syncPendingSightings();
      }
    });
    
    // Check initial connectivity
    _connectivityService.hasConnection().then((hasConnection) {
      _isOnline = hasConnection;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }

  /// Checks for stored JWT token and attempts auto-login.
  /// 
  /// Returns true if auto-login succeeds, false otherwise.
  Future<bool> checkAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      
      if (token == null) {
        return false;
      }
      
      if (JwtDecoder.isExpired(token)) {
        await logout();
        return false;
      }
      
      _token = token;
      _apiService.setToken(token);
      
      // Try to get user from cache first
      final cachedUser = await _offlineStorage.getCachedUserData();
      if (cachedUser != null) {
        _currentUser = cachedUser;
        _isLoggedIn = true;
        notifyListeners();
      }
      
      // Try to refresh from API if online
      if (_isOnline) {
        try {
          final userResponse = await _apiService.getCurrentUser();
          _currentUser = _mapUserResponseToModel(userResponse);
          await _offlineStorage.cacheUserData(_currentUser!);
        } catch (e) {
          // Use cached data if API fails
          if (cachedUser == null) {
            await logout();
            return false;
          }
        }
      }
      
      _isLoggedIn = true;
      
      // Load pending sightings
      await _loadPendingSightings();
      
      notifyListeners();
      return true;
    } catch (e) {
      await logout();
      return false;
    }
  }

  /// Authenticates user with email and password.
  /// 
  /// Stores JWT token and updates current user state on success.
  Future<void> login(String email, String password) async {
    try {
      final request = LoginRequest(email: email, password: password);
      final authResponse = await _apiService.login(request);
      
      _token = authResponse.token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', _token!);
      
      _currentUser = _mapUserResponseToModel(authResponse.user);
      await _offlineStorage.cacheUserData(_currentUser!);
      _isLoggedIn = true;
      
      // Load pending sightings
      await _loadPendingSightings();
      
      // Try to sync pending sightings
      if (_isOnline) {
        await _syncPendingSightings();
      }
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Registers a new user account.
  /// 
  /// Stores JWT token and updates current user state on success.
  Future<void> register(String firstName, String lastName, String email, String password, {String ruolo = 'utente'}) async {
    try {
      final request = RegisterRequest(
        nome: firstName,
        cognome: lastName,
        email: email,
        password: password,
        ruolo: ruolo,
      );
      final authResponse = await _apiService.register(request);
      
      _token = authResponse.token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', _token!);
      
      _currentUser = _mapUserResponseToModel(authResponse.user);
      await _offlineStorage.cacheUserData(_currentUser!);
      _isLoggedIn = true;
      
      // Load pending sightings
      await _loadPendingSightings();
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Logs out the current user and clears all stored data.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await _offlineStorage.clearCachedUserData();
    
    _token = null;
    _apiService.setToken(null);
    _currentUser = null;
    _isLoggedIn = false;
    _sightings.clear();
    _pendingSightings.clear();
    notifyListeners();
  }

  /// Maps [UserResponse] DTO to [UserModel].
  UserModel _mapUserResponseToModel(UserResponse userResponse) {
    return UserModel(
      id: userResponse.id,
      firstName: userResponse.nome,
      lastName: userResponse.cognome,
      email: userResponse.email,
      role: userResponse.ruolo,
    );
  }

  /// Updates local user information without making an API call.
  void updateUserInfo(String firstName, String lastName, String email) {
    if (_currentUser != null) {
      _currentUser = UserModel(
        id: _currentUser!.id,
        firstName: firstName,
        lastName: lastName,
        email: email,
        role: _currentUser!.role,
      );
      notifyListeners();
    }
  }

  /// Updates user information via API and refreshes local state.
  Future<void> updateUserInfoApi(String firstName, String lastName, String email) async {
    if (!_isOnline) {
      throw Exception('Nessuna connessione di rete. Riprova');
    }
    
    try {
      final request = UpdateUserRequest(
        nome: firstName,
        cognome: lastName,
        email: email,
      );
      final userResponse = await _apiService.updateCurrentUser(request);
      _currentUser = _mapUserResponseToModel(userResponse);
      await _offlineStorage.cacheUserData(_currentUser!);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Updates the notes of a specific sighting in local state.
  void updateSightingNotes(String sightingId, String notes) {
    final index = _sightings.indexWhere((s) => s.id == sightingId);
    if (index != -1) {
      final sighting = _sightings[index];
      _sightings[index] = SightingModel(
        id: sighting.id,
        userId: sighting.userId,
        userName: sighting.userName,
        flowerName: sighting.flowerName,
        location: sighting.location,
        date: sighting.date,
        images: sighting.images,
        notes: notes,
        latitude: sighting.latitude,
        longitude: sighting.longitude,
        aiModelUsed: sighting.aiModelUsed,
        aiConfidence: sighting.aiConfidence,
      );
      notifyListeners();
    }
  }

  /// Deletes a sighting by ID via API and removes it from local state.
  Future<void> deleteSighting(String sightingId) async {
    try {
      await _apiService.deleteSighting(sightingId);
      
      _sightings.removeWhere((s) => s.id == sightingId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Maps [SightingResponse] DTO to [SightingModel].
  SightingModel _mapSightingResponseToModel(SightingResponse response) {
    String userName = 'Utente';
    if (response.userNome != null && response.userCognome != null) {
      userName = '${response.userNome} ${response.userCognome}';
    } else if (response.userNome != null) {
      userName = response.userNome!;
    } else if (response.userCognome != null) {
      userName = response.userCognome!;
    }

    String address = response.indirizzo ?? 
        '${response.latitudine.toStringAsFixed(4)}, ${response.longitudine.toStringAsFixed(4)}';

    List<String> photoUrls = UrlUtils.toAbsoluteUrls(response.photoUrls);

    return SightingModel(
      id: response.id,
      userId: response.userId,
      userName: userName,
      flowerName: response.nome,
      location: address,
      date: response.data,
      images: photoUrls,
      notes: response.note ?? '',
      latitude: response.latitudine,
      longitude: response.longitudine,
      aiModelUsed: response.aiModelUsed,
      aiConfidence: response.aiConfidence,
    );
  }

  /// Fetches sightings created by the current user from the API.
  Future<void> fetchUserSightings() async {
    if (_currentUser == null) return;
    
    if (!_isOnline) {
      throw Exception('Nessuna connessione di rete. Riprova');
    }
    
    try {
      final sightingsResponse = await _apiService.getSightingsByUser(_currentUser!.id);
      
      _sightings.removeWhere((s) => s.userId == _currentUser!.id);
      
      final mappedSightings = sightingsResponse.map((response) => 
        _mapSightingResponseToModel(response)
      ).toList();
      _sightings.addAll(mappedSightings);
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches sightings within a radius of a geographic location from the API.
  /// 
  /// Returns sightings within [radiusKm] kilometers of coordinates [lat], [lng].
  Future<List<SightingModel>> fetchSightingsByLocation({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    if (!_isOnline) {
      throw Exception('Nessuna connessione di rete. Riprova');
    }
    
    try {
      final sightingsResponse = await _apiService.getSightingsByLocation(
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
      );
      
      final sightings = sightingsResponse.map((response) => 
        _mapSightingResponseToModel(response)
      ).toList();
      
      for (var sighting in sightings) {
        final existingIndex = _sightings.indexWhere((s) => s.id == sighting.id);
        if (existingIndex != -1) {
          _sightings[existingIndex] = sighting;
        } else {
          _sightings.add(sighting);
        }
      }
      
      notifyListeners();
      return sightings;
    } catch (e) {
      rethrow;
    }
  }

  /// Creates a new sighting, either online or offline.
  /// 
  /// If online, uploads immediately. If offline, saves to pending queue.
  /// When [aiModel] is provided it is sent to the backend as an override for
  /// this sighting only and does NOT change the user's default model selection.
  Future<void> createSighting({
    required XFile photo,
    required DateTime date,
    required double latitude,
    required double longitude,
    String? notes,
    String? aiModel,
  }) async {
    if (_isOnline) {
      // Try to create online
      try {
        await _apiService.createSighting(
          photo: photo,
          data: date,
          latitudine: latitude,
          longitudine: longitude,
          note: notes,
          aiModel: aiModel,
        );
        return;
      } catch (e) {
        // If fails, fall through to offline mode
      }
    }
    
    // Save as pending sighting
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Copy photo to persistent storage
    final photoPaths = <String>[];
    try {
      final newPath = await _offlineStorage.copyFileToPersistentStorage(photo.path);
      
      // For web, also store the actual photo bytes in IndexedDB
      // For native platforms, this is a no-op
      final bytes = await photo.readAsBytes();
      await _offlineStorage.storePhotoBytes(newPath, bytes);
      
      photoPaths.add(newPath);
    } catch (e) {
      // If photo storage fails (web or native), skip
      debugPrint('Failed to store photo: $e');
    }
    
    final pendingSighting = PendingSightingModel(
      id: id,
      photoPaths: photoPaths,
      date: date,
      latitude: latitude,
      longitude: longitude,
      notes: notes,
      createdAt: DateTime.now(),
    );
    
    await _offlineStorage.savePendingSighting(pendingSighting);
    _pendingSightings.add(pendingSighting);
    notifyListeners();
  }

  /// Loads pending sightings from storage.
  Future<void> _loadPendingSightings() async {
    final pending = await _offlineStorage.getPendingSightings();
    _pendingSightings.clear();
    _pendingSightings.addAll(pending);
    notifyListeners();
  }

  /// Syncs pending sightings to the server when online.
  Future<void> _syncPendingSightings() async {
    if (!_isOnline || _pendingSightings.isEmpty) return;
    
    final pendingCopy = List<PendingSightingModel>.from(_pendingSightings);
    
    for (final pending in pendingCopy) {
      try {
        if (pending.photoPaths.isEmpty) continue;

        // Use the first (and only) stored photo path
        final path = pending.photoPaths.first;
        XFile photo;
        try {
          // Try to get photo bytes (for web)
          final bytes = await _offlineStorage.getPhotoBytes(path);
          if (bytes != null) {
            // Create XFile from bytes (web)
            photo = XFile.fromData(bytes, name: path.split('_').last);
          } else {
            // Create XFile from path (native)
            photo = XFile(path);
          }
        } catch (e) {
          // Fall back to creating from path
          photo = XFile(path);
        }
        
        await _apiService.createSighting(
          photo: photo,
          data: pending.date,
          latitudine: pending.latitude,
          longitudine: pending.longitude,
          note: pending.notes,
        );
        
        // Remove from pending after successful upload
        await _offlineStorage.removePendingSighting(pending.id);
        await _offlineStorage.deletePendingPhotos(pending.photoPaths);
        _pendingSightings.removeWhere((s) => s.id == pending.id);
        
      } catch (e) {
        // Continue with other pending sightings if one fails
      }
    }
    
    notifyListeners();
  }

  /// Manually triggers sync of pending sightings.
  Future<void> syncPendingSightings() async {
    await _syncPendingSightings();
  }

  /// Deletes a pending sighting.
  Future<void> deletePendingSighting(String id) async {
    try {
      final pending = _pendingSightings.firstWhere((s) => s.id == id);
      await _offlineStorage.removePendingSighting(id);
      await _offlineStorage.deletePendingPhotos(pending.photoPaths);
      _pendingSightings.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      // Sighting not found, just remove from storage
      await _offlineStorage.removePendingSighting(id);
      _pendingSightings.removeWhere((s) => s.id == id);
      notifyListeners();
    }
  }
}
