import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:citizen_science/widgets/custom_text_field.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  group('CustomTextField', () {
    group('label and hint', () {
      testWidgets('given label when built then displays label text', (
        WidgetTester tester,
      ) async {
        // Arrange
        final controller = TextEditingController();

        // Act
        await tester.pumpWidget(
          _wrap(CustomTextField(controller: controller, label: 'Email')),
        );

        // Assert
        expect(find.text('Email'), findsOneWidget);
      });

      testWidgets('given hint when built then displays hint text', (
        WidgetTester tester,
      ) async {
        // Arrange
        final controller = TextEditingController();

        // Act
        await tester.pumpWidget(
          _wrap(
            CustomTextField(
              controller: controller,
              label: 'Email',
              hint: 'Inserisci email',
            ),
          ),
        );

        // Assert
        expect(find.text('Inserisci email'), findsOneWidget);
      });
    });

    group('password visibility toggle', () {
      testWidgets(
        'given isObscured true when built then shows visibility_off icon',
        (WidgetTester tester) async {
          // Arrange
          final controller = TextEditingController();

          // Act
          await tester.pumpWidget(
            _wrap(
              CustomTextField(
                controller: controller,
                label: 'Password',
                isObscured: true,
              ),
            ),
          );

          // Assert
          expect(find.byIcon(Icons.visibility_off), findsOneWidget);
        },
      );

      testWidgets(
        'given isObscured true when toggle icon tapped then shows visibility icon',
        (WidgetTester tester) async {
          // Arrange
          final controller = TextEditingController();
          await tester.pumpWidget(
            _wrap(
              CustomTextField(
                controller: controller,
                label: 'Password',
                isObscured: true,
              ),
            ),
          );

          // Act
          await tester.tap(find.byIcon(Icons.visibility_off));
          await tester.pump();

          // Assert
          expect(find.byIcon(Icons.visibility), findsOneWidget);
          expect(find.byIcon(Icons.visibility_off), findsNothing);
        },
      );

      testWidgets(
        'given isObscured true when toggled twice then returns to hidden state',
        (WidgetTester tester) async {
          // Arrange
          final controller = TextEditingController();
          await tester.pumpWidget(
            _wrap(
              CustomTextField(
                controller: controller,
                label: 'Password',
                isObscured: true,
              ),
            ),
          );

          // Act
          await tester.tap(find.byIcon(Icons.visibility_off));
          await tester.pump();
          await tester.tap(find.byIcon(Icons.visibility));
          await tester.pump();

          // Assert
          expect(find.byIcon(Icons.visibility_off), findsOneWidget);
        },
      );

      testWidgets(
        'given isObscured false when built then does not show toggle icon',
        (WidgetTester tester) async {
          // Arrange
          final controller = TextEditingController();

          // Act
          await tester.pumpWidget(
            _wrap(
              CustomTextField(
                controller: controller,
                label: 'Username',
                isObscured: false,
              ),
            ),
          );

          // Assert
          expect(find.byIcon(Icons.visibility_off), findsNothing);
          expect(find.byIcon(Icons.visibility), findsNothing);
        },
      );
    });

    group('prefix icon', () {
      testWidgets('given prefixIcon when built then shows the icon', (
        WidgetTester tester,
      ) async {
        // Arrange
        final controller = TextEditingController();

        // Act
        await tester.pumpWidget(
          _wrap(
            CustomTextField(
              controller: controller,
              label: 'Email',
              prefixIcon: Icons.email,
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.email), findsOneWidget);
      });

      testWidgets('given no prefixIcon when built then shows no prefix icon', (
        WidgetTester tester,
      ) async {
        // Arrange
        final controller = TextEditingController();

        // Act
        await tester.pumpWidget(
          _wrap(CustomTextField(controller: controller, label: 'Nome')),
        );

        // Assert
        // No icon widget from prefix should be present (only check specific icons)
        expect(find.byIcon(Icons.email), findsNothing);
      });
    });

    group('enabled state', () {
      testWidgets(
        'given isEnabled false when built then TextFormField is disabled',
        (WidgetTester tester) async {
          // Arrange
          final controller = TextEditingController(text: 'readonly');

          // Act
          await tester.pumpWidget(
            _wrap(
              CustomTextField(
                controller: controller,
                label: 'Campo',
                isEnabled: false,
              ),
            ),
          );

          // Assert
          final textFormField = tester.widget<TextFormField>(
            find.byType(TextFormField),
          );
          expect(textFormField.enabled, isFalse);
        },
      );

      testWidgets(
        'given isEnabled true when built then TextFormField is enabled',
        (WidgetTester tester) async {
          // Arrange
          final controller = TextEditingController();

          // Act
          await tester.pumpWidget(
            _wrap(CustomTextField(controller: controller, label: 'Campo')),
          );

          // Assert
          final textFormField = tester.widget<TextFormField>(
            find.byType(TextFormField),
          );
          expect(textFormField.enabled, isTrue);
        },
      );
    });

    group('text input', () {
      testWidgets(
        'given controller when text entered then controller reflects the value',
        (WidgetTester tester) async {
          // Arrange
          final controller = TextEditingController();
          await tester.pumpWidget(
            _wrap(CustomTextField(controller: controller, label: 'Nome')),
          );

          // Act
          await tester.enterText(find.byType(TextFormField), 'Mario');

          // Assert
          expect(controller.text, 'Mario');
        },
      );
    });
  });
}
