import 'package:flutter/material.dart';

/// Provider managing application theme (light/dark mode).
/// 
/// Notifies listeners when theme is toggled between light and dark modes.
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  /// Returns the current theme data based on dark mode state.
  ThemeData get currentTheme => _isDarkMode ? _darkTheme : _lightTheme;

  /// Toggles between light and dark theme.
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 10, 113, 13),
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color.fromARGB(255, 10, 113, 13),
      onPrimary: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
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
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
  );
}
