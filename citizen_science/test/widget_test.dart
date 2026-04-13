import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:citizen_science/providers/theme_provider.dart';
import 'package:citizen_science/providers/locale_provider.dart';

/// Smoke test verifying that core providers can be instantiated and
/// wired up into a widget tree without crashing.
void main() {
  group('App providers smoke tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets(
      'given ThemeProvider and LocaleProvider when app built then renders MaterialApp',
      (WidgetTester tester) async {
        // Arrange
        final themeProvider = ThemeProvider();

        // Act
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
              ChangeNotifierProvider(create: (_) => LocaleProvider()),
            ],
            child: Consumer<ThemeProvider>(
              builder: (context, theme, _) => MaterialApp(
                theme: theme.currentTheme,
                home: const Scaffold(body: SizedBox()),
              ),
            ),
          ),
        );

        // Assert
        expect(find.byType(MaterialApp), findsOneWidget);
      },
    );

    testWidgets(
      'given light ThemeProvider when consumed then MaterialApp uses light theme',
      (WidgetTester tester) async {
        // Arrange
        final themeProvider = ThemeProvider(); // starts in light mode

        // Act
        await tester.pumpWidget(
          ChangeNotifierProvider<ThemeProvider>.value(
            value: themeProvider,
            child: Consumer<ThemeProvider>(
              builder: (context, theme, _) => MaterialApp(
                theme: theme.currentTheme,
                home: const Scaffold(body: SizedBox()),
              ),
            ),
          ),
        );

        // Assert
        final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(app.theme?.brightness, Brightness.light);
      },
    );

    testWidgets(
      'given ThemeProvider when toggled then MaterialApp rebuilds with dark theme',
      (WidgetTester tester) async {
        // Arrange
        final themeProvider = ThemeProvider();

        await tester.pumpWidget(
          ChangeNotifierProvider<ThemeProvider>.value(
            value: themeProvider,
            child: Consumer<ThemeProvider>(
              builder: (context, theme, _) => MaterialApp(
                theme: theme.currentTheme,
                home: const Scaffold(body: SizedBox()),
              ),
            ),
          ),
        );

        // Act
        themeProvider.toggleTheme();
        await tester.pump();

        // Assert
        final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(app.theme?.brightness, Brightness.dark);
      },
    );
  });
}
