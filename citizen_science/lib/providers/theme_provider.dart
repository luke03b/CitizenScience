import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider managing application theme (light/dark mode).
///
/// Notifies listeners when theme is toggled between light and dark modes.
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  /// Loads the saved theme preference from SharedPreferences.
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themePreferenceKey) ?? false;
    notifyListeners();
  }

  /// Returns the current theme data based on dark mode state.
  ThemeData get currentTheme => _isDarkMode ? _darkTheme : _lightTheme;

  /// Toggles between light and dark theme.
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    _saveThemePreference(_isDarkMode);
  }

  Future<void> _saveThemePreference(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePreferenceKey, isDarkMode);
  }

  static const String _themePreferenceKey = 'is_dark_mode';

  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 10, 113, 13),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color.fromARGB(255, 10, 113, 13),
          onPrimary: Colors.white,
        ),
    appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.white,
      contentTextStyle: const TextStyle(color: Colors.black),
      behavior: SnackBarBehavior.floating,
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 10, 113, 13),
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color.fromARGB(255, 10, 113, 13),
          onPrimary: Colors.white,
          error: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 10, 113, 13),
            brightness: Brightness.light,
          ).error,
        ),
    appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF212121),
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
