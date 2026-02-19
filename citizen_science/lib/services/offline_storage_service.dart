import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pending_sighting_model.dart';
import '../models/user_model.dart';
import 'offline_storage_service_web.dart';

/// Service for managing offline data storage for web platform.
/// 
/// This service is designed exclusively for web platforms and uses
/// IndexedDB for photo storage. It handles caching of user data and
/// pending sightings that need to be synced when network connection
/// is restored.
class OfflineStorageService {
  static const String _userCacheKey = 'cached_user_data';
  static const String _pendingSightingsKey = 'pending_sightings';
  
  final OfflineStorageServicePlatform _platform = OfflineStorageServicePlatform();

  /// Saves user data to local cache for offline access.
  Future<void> cacheUserData(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = {
        'id': user.id,
        'firstName': user.firstName,
        'lastName': user.lastName,
        'email': user.email,
        'role': user.role,
      };
      await prefs.setString(_userCacheKey, jsonEncode(userData));
    } catch (e) {
      // Silently fail
    }
  }

  /// Retrieves cached user data from local storage.
  /// 
  /// Returns null if no cached data exists or if deserialization fails.
  Future<UserModel?> getCachedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString(_userCacheKey);
      
      if (userDataStr == null) return null;
      
      final userData = jsonDecode(userDataStr);
      return UserModel(
        id: userData['id'],
        firstName: userData['firstName'],
        lastName: userData['lastName'],
        email: userData['email'],
        role: userData['role'],
      );
    } catch (e) {
      return null;
    }
  }

  /// Clears cached user data from local storage.
  Future<void> clearCachedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userCacheKey);
    } catch (e) {
      // Silently fail
    }
  }

  /// Saves a pending sighting to local storage.
  /// 
  /// Copies photo files to a persistent location and stores
  /// the sighting data for later upload.
  Future<void> savePendingSighting(PendingSightingModel sighting) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing pending sightings
      final existingSightings = await getPendingSightings();
      
      // Add new sighting
      existingSightings.add(sighting);
      
      // Save to SharedPreferences
      final sightingsJson = existingSightings.map((s) => s.toJson()).toList();
      await prefs.setString(_pendingSightingsKey, jsonEncode(sightingsJson));
    } catch (e) {
      rethrow;
    }
  }

  /// Retrieves all pending sightings from local storage.
  Future<List<PendingSightingModel>> getPendingSightings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sightingsStr = prefs.getString(_pendingSightingsKey);
      
      if (sightingsStr == null) return [];
      
      final List<dynamic> sightingsJson = jsonDecode(sightingsStr);
      return sightingsJson
          .map((json) => PendingSightingModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Removes a pending sighting from local storage after successful upload.
  Future<void> removePendingSighting(String sightingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingSightings = await getPendingSightings();
      
      existingSightings.removeWhere((s) => s.id == sightingId);
      
      final sightingsJson = existingSightings.map((s) => s.toJson()).toList();
      await prefs.setString(_pendingSightingsKey, jsonEncode(sightingsJson));
    } catch (e) {
      // Silently fail
    }
  }

  /// Clears all pending sightings from local storage.
  Future<void> clearPendingSightings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingSightingsKey);
    } catch (e) {
      // Silently fail
    }
  }

  /// Copies a file to persistent storage and returns the new path.
  /// 
  /// On web platforms, stores the file in IndexedDB and returns a unique ID.
  /// On native platforms, copies to the application documents directory.
  Future<String> copyFileToPersistentStorage(String originalPath) async {
    return _platform.copyFileToPersistentStorage(originalPath);
  }
  
  /// Stores photo bytes in persistent storage (web-specific).
  /// 
  /// This method is primarily for web platforms where we need to store
  /// the actual bytes of the photo in IndexedDB alongside the metadata.
  Future<void> storePhotoBytes(String photoId, List<int> bytes) async {
    await _platform.storePhotoBytes(photoId, bytes is Uint8List ? bytes : Uint8List.fromList(bytes));
  }
  
  /// Retrieves photo bytes from persistent storage.
  /// 
  /// Returns the bytes of the photo if found, null otherwise.
  Future<Uint8List?> getPhotoBytes(String photoId) async {
    return _platform.getPhotoBytes(photoId);
  }

  /// Deletes photos associated with a pending sighting.
  Future<void> deletePendingPhotos(List<String> photoPaths) async {
    await _platform.deletePendingPhotos(photoPaths);
  }
}
