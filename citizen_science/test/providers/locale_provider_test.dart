import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:citizen_science/providers/locale_provider.dart';

void main() {
  group('LocaleProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('locale defaults to English', () {
      // Arrange
      final provider = LocaleProvider();

      // Assert
      expect(provider.locale.languageCode, 'en');
    });

    test('loadLocale reads from SharedPreferences when saved', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({'language_code': 'it'});
      final provider = LocaleProvider();

      // Act
      await provider.loadLocale();

      // Assert
      expect(provider.locale.languageCode, 'it');
    });

    test('loadLocale defaults to English when nothing is saved', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final provider = LocaleProvider();

      // Act
      await provider.loadLocale();

      // Assert
      expect(provider.locale.languageCode, 'en');
    });

    test('setLocale updates the locale', () async {
      // Arrange
      final provider = LocaleProvider();

      // Act
      await provider.setLocale(const Locale('it'));

      // Assert
      expect(provider.locale.languageCode, 'it');
    });

    test('setLocale persists to SharedPreferences', () async {
      // Arrange
      final provider = LocaleProvider();

      // Act
      await provider.setLocale(const Locale('it'));

      // Verify persistence
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('language_code'), 'it');
    });

    test('setLocale notifies listeners when locale changes', () async {
      // Arrange
      final provider = LocaleProvider();
      var notified = false;
      provider.addListener(() => notified = true);

      // Act
      await provider.setLocale(const Locale('it'));

      // Assert
      expect(notified, isTrue);
    });

    test('setLocale does not notify when same locale is set', () async {
      // Arrange
      final provider = LocaleProvider();
      var count = 0;
      provider.addListener(() => count++);

      // Act — set English twice (English is the default)
      await provider.setLocale(const Locale('en'));
      await provider.setLocale(const Locale('en'));

      // Assert — first call changes from 'en' default (same value, so 0), second call skips
      expect(count, 0);
    });
  });
}
