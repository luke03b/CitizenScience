import 'platform_utils_web.dart';

/// Utility class for web platform-specific functionality.
/// 
/// Provides methods to detect the app's running environment,
/// particularly for PWA (Progressive Web App) detection.
/// This utility is designed exclusively for web platforms.
class PlatformUtils {
  /// Checks if the app is running in PWA standalone mode.
  /// 
  /// Returns true when running on web in standalone mode.
  /// Returns false for regular browser mode.
  static bool isStandalonePWA() {
    return checkStandaloneMode();
  }
}
