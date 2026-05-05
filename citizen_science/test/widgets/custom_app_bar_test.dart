import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:citizen_science/widgets/custom_app_bar.dart';

Widget _wrap(PreferredSizeWidget appBar) =>
    MaterialApp(home: Scaffold(appBar: appBar));

void main() {
  group('CustomAppBar', () {
    group('title', () {
      testWidgets('given title when built then displays the title text', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(_wrap(const CustomAppBar(title: 'EcoFlora')));

        // Assert
        expect(find.text('EcoFlora'), findsOneWidget);
      });
    });

    group('logo visibility', () {
      testWidgets('given showLogo true when built then shows app logo', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          _wrap(const CustomAppBar(title: 'Test', showLogo: true)),
        );

        // Assert
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is SvgPicture &&
                widget.bytesLoader is SvgAssetLoader &&
                (widget.bytesLoader as SvgAssetLoader).assetName ==
                    'assets/images/Logo.svg',
          ),
          findsOneWidget,
        );
      });

      testWidgets('given showLogo false when built then hides app logo', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          _wrap(const CustomAppBar(title: 'Test', showLogo: false)),
        );

        // Assert
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is SvgPicture &&
                widget.bytesLoader is SvgAssetLoader &&
                (widget.bytesLoader as SvgAssetLoader).assetName ==
                    'assets/images/Logo.svg',
          ),
          findsNothing,
        );
      });

      testWidgets(
        'given showLogo default (true) when built then shows app logo',
        (WidgetTester tester) async {
          // Arrange & Act
          await tester.pumpWidget(_wrap(const CustomAppBar(title: 'Test')));

          // Assert — default value is true
          expect(
            find.byWidgetPredicate(
              (widget) =>
                  widget is SvgPicture &&
                  widget.bytesLoader is SvgAssetLoader &&
                  (widget.bytesLoader as SvgAssetLoader).assetName ==
                      'assets/images/Logo.svg',
            ),
            findsOneWidget,
          );
        },
      );
    });

    group('actions', () {
      testWidgets('given action widget when built then shows action icon', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          _wrap(
            CustomAppBar(
              title: 'Test',
              actions: [
                IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
              ],
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.settings), findsOneWidget);
      });

      testWidgets(
        'given multiple actions when built then shows all action widgets',
        (WidgetTester tester) async {
          // Arrange & Act
          await tester.pumpWidget(
            _wrap(
              CustomAppBar(
                title: 'Test',
                actions: [
                  IconButton(icon: const Icon(Icons.search), onPressed: () {}),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          );

          // Assert
          expect(find.byIcon(Icons.search), findsOneWidget);
          expect(find.byIcon(Icons.more_vert), findsOneWidget);
        },
      );

      testWidgets('given no actions when built then no extra icons shown', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(_wrap(const CustomAppBar(title: 'Test')));

        // Assert — only the logo science icon should be present, not settings
        expect(find.byIcon(Icons.settings), findsNothing);
      });
    });

    group('leading widget', () {
      testWidgets(
        'given leading widget when built then displays leading icon',
        (WidgetTester tester) async {
          // Arrange & Act
          await tester.pumpWidget(
            _wrap(
              const CustomAppBar(
                title: 'Detail',
                leading: Icon(Icons.arrow_back),
              ),
            ),
          );

          // Assert
          expect(find.byIcon(Icons.arrow_back), findsOneWidget);
        },
      );
    });

    group('preferredSize', () {
      test('preferredSize height equals kToolbarHeight', () {
        // Arrange
        const appBar = CustomAppBar(title: 'Test');

        // Assert
        expect(appBar.preferredSize.height, kToolbarHeight);
      });
    });
  });
}
