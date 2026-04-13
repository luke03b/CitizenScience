import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:citizen_science/widgets/custom_button.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('CustomButton', () {
    group('default elevated style', () {
      testWidgets('given text when built then displays the text', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          _wrap(CustomButton(text: 'Invia', onPressed: () {})),
        );

        // Assert
        expect(find.text('Invia'), findsOneWidget);
      });

      testWidgets('given onPressed when tapped then callback is invoked', (
        WidgetTester tester,
      ) async {
        // Arrange
        var pressed = false;
        await tester.pumpWidget(
          _wrap(CustomButton(text: 'Go', onPressed: () => pressed = true)),
        );

        // Act
        await tester.tap(find.byType(ElevatedButton));

        // Assert
        expect(pressed, isTrue);
      });

      testWidgets(
        'given isLoading false when built then renders ElevatedButton',
        (WidgetTester tester) async {
          // Arrange & Act
          await tester.pumpWidget(
            _wrap(CustomButton(text: 'Submit', onPressed: () {})),
          );

          // Assert
          expect(find.byType(ElevatedButton), findsOneWidget);
        },
      );
    });

    group('loading state', () {
      testWidgets(
        'given isLoading true when built then shows CircularProgressIndicator',
        (WidgetTester tester) async {
          // Arrange & Act
          await tester.pumpWidget(
            _wrap(
              CustomButton(text: 'Submit', onPressed: () {}, isLoading: true),
            ),
          );

          // Assert
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        },
      );

      testWidgets('given isLoading true when built then hides text', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          _wrap(
            CustomButton(text: 'Submit', onPressed: () {}, isLoading: true),
          ),
        );

        // Assert
        expect(find.text('Submit'), findsNothing);
      });

      testWidgets(
        'given isLoading true when tapped then onPressed is not called',
        (WidgetTester tester) async {
          // Arrange
          var pressed = false;
          await tester.pumpWidget(
            _wrap(
              CustomButton(
                text: 'Submit',
                onPressed: () => pressed = true,
                isLoading: true,
              ),
            ),
          );

          // Act
          await tester.tap(find.byType(ElevatedButton));

          // Assert
          expect(pressed, isFalse);
        },
      );
    });

    group('outlined style', () {
      testWidgets(
        'given isOutlined true when built then renders OutlinedButton',
        (WidgetTester tester) async {
          // Arrange & Act
          await tester.pumpWidget(
            _wrap(
              CustomButton(text: 'Annulla', onPressed: () {}, isOutlined: true),
            ),
          );

          // Assert
          expect(find.byType(OutlinedButton), findsOneWidget);
          expect(find.byType(ElevatedButton), findsNothing);
        },
      );

      testWidgets(
        'given isOutlined true when tapped then callback is invoked',
        (WidgetTester tester) async {
          // Arrange
          var pressed = false;
          await tester.pumpWidget(
            _wrap(
              CustomButton(
                text: 'Annulla',
                onPressed: () => pressed = true,
                isOutlined: true,
              ),
            ),
          );

          // Act
          await tester.tap(find.byType(OutlinedButton));

          // Assert
          expect(pressed, isTrue);
        },
      );

      testWidgets(
        'given isOutlined true with isLoading when tapped then onPressed is not called',
        (WidgetTester tester) async {
          // Arrange
          var pressed = false;
          await tester.pumpWidget(
            _wrap(
              CustomButton(
                text: 'Annulla',
                onPressed: () => pressed = true,
                isOutlined: true,
                isLoading: true,
              ),
            ),
          );

          // Act
          await tester.tap(find.byType(OutlinedButton));

          // Assert
          expect(pressed, isFalse);
        },
      );
    });

    group('icon variant', () {
      testWidgets('given icon when built then shows icon and text', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          _wrap(
            CustomButton(text: 'Aggiungi', onPressed: () {}, icon: Icons.add),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.add), findsOneWidget);
        expect(find.text('Aggiungi'), findsOneWidget);
      });
    });
  });
}
