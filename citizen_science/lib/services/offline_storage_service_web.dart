import 'dart:convert';
import 'dart:typed_data';
import 'package:idb_shim/idb_browser.dart';

/// Web-specific implementation for offline photo storage using IndexedDB.
///
/// This implementation is designed exclusively for web platforms (including PWAs)
/// and stores photos as base64-encoded strings in the browser's IndexedDB.
/// This approach provides reliable offline caching for progressive web apps
/// without requiring file system access.
class OfflineStorageServicePlatform {
  static const String _dbName = 'citizen_science_offline';
  static const String _photoStoreName = 'pending_photos';
  static const int _dbVersion = 1;

  Database? _db;

  /// Initializes the IndexedDB database.
  Future<void> _initDb() async {
    if (_db != null) return;

    final idbFactory = getIdbFactory()!;
    _db = await idbFactory.open(
      _dbName,
      version: _dbVersion,
      onUpgradeNeeded: (VersionChangeEvent event) {
        final db = event.database;
        // Create object store for photos if it doesn't exist
        if (!db.objectStoreNames.contains(_photoStoreName)) {
          db.createObjectStore(_photoStoreName);
        }
      },
    );
  }

  /// Copies a file to persistent storage and returns the new path.
  ///
  /// For web, this reads the file as bytes and stores it in IndexedDB
  /// as a base64 string, returning a unique identifier as the "path".
  ///
  /// Note: The caller should follow this up with storePhotoData to store
  /// the actual photo bytes if the originalPath is a temporary blob URL.
  Future<String> copyFileToPersistentStorage(String originalPath) async {
    try {
      await _initDb();

      // Generate unique ID for this photo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = originalPath.split('/').last;
      final photoId = '${timestamp}_$fileName';

      // Store metadata about the photo
      final transaction = _db!.transaction(_photoStoreName, idbModeReadWrite);
      final store = transaction.objectStore(_photoStoreName);

      await store.put({
        'path': originalPath,
        'timestamp': timestamp,
        'fileName': fileName,
      }, photoId);
      await transaction.completed;

      return photoId;
    } catch (e) {
      throw Exception('Failed to copy photo to IndexedDB: $e');
    }
  }

  /// Stores photo bytes in IndexedDB.
  ///
  /// This is a web-specific method to store the actual photo data
  /// as a base64 string in IndexedDB.
  Future<void> storePhotoBytes(String photoId, Uint8List bytes) async {
    try {
      await _initDb();

      final base64Data = base64Encode(bytes);

      final transaction = _db!.transaction(_photoStoreName, idbModeReadWrite);
      final store = transaction.objectStore(_photoStoreName);

      final existing = await store.getObject(photoId) as Map<String, dynamic>?;
      if (existing != null) {
        existing['data'] = base64Data;
        await store.put(existing, photoId);
      } else {
        await store.put({'data': base64Data}, photoId);
      }

      await transaction.completed;
    } catch (e) {
      throw Exception('Failed to store photo bytes in IndexedDB: $e');
    }
  }

  /// Retrieves photo bytes from IndexedDB.
  Future<Uint8List?> getPhotoBytes(String photoId) async {
    try {
      await _initDb();

      final transaction = _db!.transaction(_photoStoreName, idbModeReadOnly);
      final store = transaction.objectStore(_photoStoreName);

      final data = await store.getObject(photoId) as Map<String, dynamic>?;
      await transaction.completed;

      if (data != null && data['data'] != null) {
        return base64Decode(data['data']);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Deletes photos associated with a pending sighting.
  Future<void> deletePendingPhotos(List<String> photoPaths) async {
    try {
      await _initDb();

      final transaction = _db!.transaction(_photoStoreName, idbModeReadWrite);
      final store = transaction.objectStore(_photoStoreName);

      for (final photoId in photoPaths) {
        try {
          await store.delete(photoId);
        } catch (e) {
          // Continue deleting other photos even if one fails
        }
      }

      await transaction.completed;
    } catch (e) {
      // Silently fail
    }
  }
}
