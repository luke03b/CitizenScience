import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

/// Service for monitoring network connectivity status.
/// 
/// Provides methods to check current connectivity and stream
/// of connectivity changes.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Checks if device currently has internet connectivity.
  /// 
  /// Returns true if connected via WiFi, mobile, or ethernet.
  Future<bool> hasConnection() async {
    try {
      final List<ConnectivityResult> connectivityResult = 
          await _connectivity.checkConnectivity();
      return connectivityResult.isNotEmpty && 
             !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  /// Subscribes to connectivity changes.
  /// 
  /// Calls [onConnectivityChanged] whenever connectivity status changes.
  void startMonitoring(Function(bool) onConnectivityChanged) {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final hasConnection = results.isNotEmpty && 
                             !results.contains(ConnectivityResult.none);
        onConnectivityChanged(hasConnection);
      },
    );
  }

  /// Stops monitoring connectivity changes.
  void stopMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  /// Disposes of resources.
  void dispose() {
    stopMonitoring();
  }
}
