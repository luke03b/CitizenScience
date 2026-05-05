import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:citizen_science/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('isDarkMode is false by default', () {
      // Arrange
      final provider = ThemeProvider();

      // Assert
      expect(provider.isDarkMode, isFalse);
    });

    test('currentTheme is light by default', () {
      // Arrange
      final provider = ThemeProvider();

      // Assert
      expect(provider.currentTheme.brightness, Brightness.light);
    });

    test('toggleTheme switches to dark mode', () {
      // Arrange
      final provider = ThemeProvider();

      // Act
      provider.toggleTheme();

      // Assert
      expect(provider.isDarkMode, isTrue);
      expect(provider.currentTheme.brightness, Brightness.dark);
    });

    test('toggleTheme switches back to light mode', () {
      // Arrange
      final provider = ThemeProvider();

      // Act
      provider.toggleTheme();
      provider.toggleTheme();

      // Assert
      expect(provider.isDarkMode, isFalse);
      expect(provider.currentTheme.brightness, Brightness.light);
    });

    test('toggleTheme notifies listeners', () {
      // Arrange
      final provider = ThemeProvider();
      var notified = false;
      provider.addListener(() => notified = true);

      // Act
      provider.toggleTheme();

      // Assert
      expect(notified, isTrue);
    });

    test('multiple toggles notify listeners each time', () {
      // Arrange
      final provider = ThemeProvider();
      var count = 0;
      provider.addListener(() => count++);

      // Act
      provider.toggleTheme();
      provider.toggleTheme();
      provider.toggleTheme();

      // Assert
      expect(count, 3);
    });

    test('currentTheme returns ThemeData instance', () {
      // Arrange
      final provider = ThemeProvider();

      // Assert
      expect(provider.currentTheme, isA<ThemeData>());
    });

    test('dark theme has dark brightness', () {
      // Arrange
      final provider = ThemeProvider();
      provider.toggleTheme();

      // Assert
      expect(provider.currentTheme.brightness, Brightness.dark);
    });

    test('loadTheme restores saved dark mode preference', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({'is_dark_mode': true});
      final provider = ThemeProvider();

      // Act
      await provider.loadTheme();

      // Assert
      expect(provider.isDarkMode, isTrue);
      expect(provider.currentTheme.brightness, Brightness.dark);
    });

    test('toggleTheme persists the selected theme', () async {
      // Arrange
      final provider = ThemeProvider();

      // Act
      provider.toggleTheme();
      await Future<void>.delayed(Duration.zero);

      final prefs = await SharedPreferences.getInstance();

      // Assert
      expect(provider.isDarkMode, isTrue);
      expect(prefs.getBool('is_dark_mode'), isTrue);
    });
  });
}
