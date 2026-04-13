import 'package:flutter_test/flutter_test.dart';
import 'package:citizen_science/utils/validation_utils.dart';

void main() {
  group('ValidationUtils.validateCoordinates', () {
    group('valid coordinates', () {
      test('returns success for typical Italian coordinates', () {
        // Act
        final result = ValidationUtils.validateCoordinates('45.4642', '9.1900');

        // Assert
        expect(result.isValid, isTrue);
        expect(result.errorMessage, isNull);
      });

      test('accepts zero coordinates', () {
        // Act
        final result = ValidationUtils.validateCoordinates('0', '0');

        // Assert
        expect(result.isValid, isTrue);
      });

      test('accepts boundary latitude value -90', () {
        // Act
        final result = ValidationUtils.validateCoordinates('-90', '0');

        // Assert
        expect(result.isValid, isTrue);
      });

      test('accepts boundary latitude value 90', () {
        // Act
        final result = ValidationUtils.validateCoordinates('90', '0');

        // Assert
        expect(result.isValid, isTrue);
      });

      test('accepts boundary longitude value -180', () {
        // Act
        final result = ValidationUtils.validateCoordinates('0', '-180');

        // Assert
        expect(result.isValid, isTrue);
      });

      test('accepts boundary longitude value 180', () {
        // Act
        final result = ValidationUtils.validateCoordinates('0', '180');

        // Assert
        expect(result.isValid, isTrue);
      });

      test('accepts negative latitude in valid range', () {
        // Act
        final result = ValidationUtils.validateCoordinates(
          '-33.8688',
          '151.2093',
        );

        // Assert
        expect(result.isValid, isTrue);
      });
    });

    group('null and empty inputs', () {
      test('returns error when latStr is null', () {
        // Act
        final result = ValidationUtils.validateCoordinates(null, '9.1900');

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errorMessage, isNotNull);
      });

      test('returns error when lngStr is null', () {
        // Act
        final result = ValidationUtils.validateCoordinates('45.0', null);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errorMessage, isNotNull);
      });

      test('returns error when latStr is empty', () {
        // Act
        final result = ValidationUtils.validateCoordinates('', '9.0');

        // Assert
        expect(result.isValid, isFalse);
      });

      test('returns error when lngStr is empty', () {
        // Act
        final result = ValidationUtils.validateCoordinates('45.0', '');

        // Assert
        expect(result.isValid, isFalse);
      });

      test('returns error when both are null', () {
        // Act
        final result = ValidationUtils.validateCoordinates(null, null);

        // Assert
        expect(result.isValid, isFalse);
      });
    });

    group('non-numeric inputs', () {
      test('returns error for non-numeric latitude', () {
        // Act
        final result = ValidationUtils.validateCoordinates('abc', '9.0');

        // Assert
        expect(result.isValid, isFalse);
      });

      test('returns error for non-numeric longitude', () {
        // Act
        final result = ValidationUtils.validateCoordinates('45.0', 'xyz');

        // Assert
        expect(result.isValid, isFalse);
      });
    });

    group('out-of-range coordinates', () {
      test('returns error for latitude below -90', () {
        // Act
        final result = ValidationUtils.validateCoordinates('-91.0', '9.0');

        // Assert
        expect(result.isValid, isFalse);
      });

      test('returns error for latitude above 90', () {
        // Act
        final result = ValidationUtils.validateCoordinates('91.0', '9.0');

        // Assert
        expect(result.isValid, isFalse);
      });

      test('returns error for longitude below -180', () {
        // Act
        final result = ValidationUtils.validateCoordinates('45.0', '-181.0');

        // Assert
        expect(result.isValid, isFalse);
      });

      test('returns error for longitude above 180', () {
        // Act
        final result = ValidationUtils.validateCoordinates('45.0', '181.0');

        // Assert
        expect(result.isValid, isFalse);
      });
    });
  });

  group('ValidationResult', () {
    test(
      'ValidationResult.success sets isValid to true and errorMessage to null',
      () {
        // Act
        const result = ValidationResult.success();

        // Assert
        expect(result.isValid, isTrue);
        expect(result.errorMessage, isNull);
      },
    );

    test('ValidationResult.error sets isValid to false with a message', () {
      // Act
      const result = ValidationResult.error('Messaggio di errore');

      // Assert
      expect(result.isValid, isFalse);
      expect(result.errorMessage, 'Messaggio di errore');
    });
  });
}
