import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/sighting_model.dart';

class AppStateProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoggedIn = false;
  final List<SightingModel> _sightings = [];

  bool get isLoggedIn => _isLoggedIn;
  UserModel? get currentUser => _currentUser;
  List<SightingModel> get userSightings => _sightings.where((s) => s.userId == _currentUser?.id).toList();
  List<SightingModel> get allSightings => _sightings;

  void login(String email, String password) {
    // Mock login - no backend connection yet
    _currentUser = UserModel(
      id: '1',
      firstName: 'Mario',
      lastName: 'Rossi',
      email: email,
    );
    _isLoggedIn = true;
    _loadMockSightings();
    notifyListeners();
  }

  void register(String firstName, String lastName, String email, String password) {
    // Mock registration - no backend connection yet
    _currentUser = UserModel(
      id: '1',
      firstName: firstName,
      lastName: lastName,
      email: email,
    );
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _isLoggedIn = false;
    _sightings.clear();
    notifyListeners();
  }

  void updateUserInfo(String firstName, String lastName, String email) {
    if (_currentUser != null) {
      _currentUser = UserModel(
        id: _currentUser!.id,
        firstName: firstName,
        lastName: lastName,
        email: email,
      );
      notifyListeners();
    }
  }

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
      );
      notifyListeners();
    }
  }

  void _loadMockSightings() {
    // Mock data for demonstration
    _sightings.addAll([
      SightingModel(
        id: '1',
        userId: '1',
        userName: 'Mario Rossi',
        flowerName: 'Rosa Canina',
        location: 'Parco Sempione, Milano',
        date: DateTime.now().subtract(const Duration(days: 5)),
        images: ['/assets/images/rosacanina.jpg'],
        notes: 'Bellissima rosa selvatica trovata nel parco',
        latitude: 45.4719,
        longitude: 9.1769,
      ),
      SightingModel(
        id: '2',
        userId: '1',
        userName: 'Mario Rossi',
        flowerName: 'Margherita',
        location: 'Giardini Pubblici, Milano',
        date: DateTime.now().subtract(const Duration(days: 3)),
        images: [
          '/assets/images/margherita.jpg', 
          '/assets/images/margherita2.jpg', 
          '/assets/images/margherita3.jpeg'
          ],
        notes: 'Campo di margherite meraviglioso',
        latitude: 45.4758,
        longitude: 9.2034,
      ),
      SightingModel(
        id: '3',
        userId: '2',
        userName: 'Luca Bianchi',
        flowerName: 'Tulipano',
        location: 'Villa Reale, Monza',
        date: DateTime.now().subtract(const Duration(days: 1)),
        images: ['/assets/images/tulipano.jpg'],
        notes: 'Tulipani colorati in fioritura',
        latitude: 45.5833,
        longitude: 9.2667,
      ),
    ]);
  }
}
