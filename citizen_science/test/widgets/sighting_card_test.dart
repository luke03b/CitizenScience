import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:citizen_science/models/sighting_model.dart';
import 'package:citizen_science/widgets/sighting_card.dart';
import 'package:citizen_science/widgets/placeholder_image.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

SightingModel _buildSighting({
  String flowerName = 'Rosa Canina',
  String location = 'Milano',
  DateTime? date,
  List<String>? images,
}) {
  return SightingModel(
    id: '1',
    userId: 'u1',
    userName: 'Mario Rossi',
    flowerName: flowerName,
    location: location,
    date: date ?? DateTime(2024, 6, 15),
    images: images ?? [],
    notes: 'Belle rose selvatiche',
    latitude: 45.4642,
    longitude: 9.1900,
  );
}

void main() {
  group('SightingCard', () {
    group('content display', () {
      testWidgets('given sighting when built then displays flower name', (
        WidgetTester tester,
      ) async {
        // Arrange
        final sighting = _buildSighting(flowerName: 'Rosa Canina');

        // Act
        await tester.pumpWidget(
          _wrap(SightingCard(sighting: sighting, onTap: () {})),
        );

        // Assert
        expect(find.text('Rosa Canina'), findsOneWidget);
      });

      testWidgets('given sighting when built then displays location', (
        WidgetTester tester,
      ) async {
        // Arrange
        final sighting = _buildSighting(location: 'Via Roma 1, Milano');

        // Act
        await tester.pumpWidget(
          _wrap(SightingCard(sighting: sighting, onTap: () {})),
        );

        // Assert
        expect(find.text('Via Roma 1, Milano'), findsOneWidget);
      });

      testWidgets(
        'given sighting with date 15/6/2024 when built then displays formatted date',
        (WidgetTester tester) async {
          // Arrange
          final sighting = _buildSighting(date: DateTime(2024, 6, 15));

          // Act
          await tester.pumpWidget(
            _wrap(SightingCard(sighting: sighting, onTap: () {})),
          );

          // Assert
          expect(find.text('15/6/2024'), findsOneWidget);
        },
      );

      testWidgets(
        'given sighting with date 1/1/2023 when built then displays formatted date',
        (WidgetTester tester) async {
          // Arrange
          final sighting = _buildSighting(date: DateTime(2023, 1, 1));

          // Act
          await tester.pumpWidget(
            _wrap(SightingCard(sighting: sighting, onTap: () {})),
          );

          // Assert
          expect(find.text('1/1/2023'), findsOneWidget);
        },
      );
    });

    group('image placeholder', () {
      testWidgets(
        'given sighting with no images when built then shows PlaceholderImage',
        (WidgetTester tester) async {
          // Arrange
          final sighting = _buildSighting(images: []);

          // Act
          await tester.pumpWidget(
            _wrap(SightingCard(sighting: sighting, onTap: () {})),
          );

          // Assert
          expect(find.byType(PlaceholderImage), findsOneWidget);
        },
      );

      testWidgets(
        'given sighting with images when built then does not show PlaceholderImage',
        (WidgetTester tester) async {
          // Arrange — provide an invalid URL so Image.network fails gracefully to error builder
          final sighting = _buildSighting(
            images: ['http://localhost/nonexistent.jpg'],
          );

          // Act
          await tester.pumpWidget(
            _wrap(SightingCard(sighting: sighting, onTap: () {})),
          );
          // Do not pumpAndSettle to avoid waiting for network (which will never resolve in tests)
          await tester.pump();

          // Assert
          expect(find.byType(PlaceholderImage), findsNothing);
        },
      );
    });

    group('interaction', () {
      testWidgets('given onTap when card is tapped then callback is invoked', (
        WidgetTester tester,
      ) async {
        // Arrange
        var tapped = false;
        final sighting = _buildSighting();

        // Act
        await tester.pumpWidget(
          _wrap(SightingCard(sighting: sighting, onTap: () => tapped = true)),
        );
        await tester.tap(find.byType(InkWell));

        // Assert
        expect(tapped, isTrue);
      });
    });

    group('location and date icons', () {
      testWidgets('when built then shows location_on icon', (
        WidgetTester tester,
      ) async {
        // Arrange
        final sighting = _buildSighting();

        // Act
        await tester.pumpWidget(
          _wrap(SightingCard(sighting: sighting, onTap: () {})),
        );

        // Assert
        expect(find.byIcon(Icons.location_on), findsOneWidget);
      });

      testWidgets('when built then shows calendar_today icon', (
        WidgetTester tester,
      ) async {
        // Arrange
        final sighting = _buildSighting();

        // Act
        await tester.pumpWidget(
          _wrap(SightingCard(sighting: sighting, onTap: () {})),
        );

        // Assert
        expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      });
    });
  });
}
