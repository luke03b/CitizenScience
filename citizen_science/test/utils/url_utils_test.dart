import 'package:flutter_test/flutter_test.dart';
import 'package:citizen_science/utils/url_utils.dart';
import 'package:citizen_science/providers/api_service.dart';

void main() {
  group('UrlUtils', () {
    group('toAbsoluteUrl', () {
      test('returns http URL unchanged', () {
        // Arrange
        const url = 'http://example.com/photo.jpg';

        // Act & Assert
        expect(UrlUtils.toAbsoluteUrl(url), url);
      });

      test('returns https URL unchanged', () {
        // Arrange
        const url = 'https://example.com/photo.jpg';

        // Act & Assert
        expect(UrlUtils.toAbsoluteUrl(url), url);
      });

      test('prepends base URL to relative URL with leading slash', () {
        // Arrange
        const url = '/api/photos/img.jpg';

        // Act
        final result = UrlUtils.toAbsoluteUrl(url);

        // Assert
        expect(result, startsWith('http'));
        expect(result, endsWith('api/photos/img.jpg'));
      });

      test('prepends base URL to relative URL without leading slash', () {
        // Arrange
        const url = 'api/photos/img.jpg';

        // Act
        final result = UrlUtils.toAbsoluteUrl(url);

        // Assert
        expect(result, startsWith('http'));
        expect(result, endsWith('api/photos/img.jpg'));
      });

      test(
        'leading-slash and no-slash relative URLs resolve to same result',
        () {
          // Act
          final withSlash = UrlUtils.toAbsoluteUrl('/api/photos/img.jpg');
          final withoutSlash = UrlUtils.toAbsoluteUrl('api/photos/img.jpg');

          // Assert
          expect(withSlash, withoutSlash);
        },
      );

      test('absolute URL uses ApiService.baseUrl as prefix', () {
        // Arrange
        const url = '/api/photos/test.jpg';

        // Act
        final result = UrlUtils.toAbsoluteUrl(url);

        // Assert
        expect(result, '${ApiService.baseUrl}/api/photos/test.jpg');
      });
    });

    group('toAbsoluteUrls', () {
      test('converts a list of mixed URLs', () {
        // Arrange
        final urls = ['http://example.com/a.jpg', '/api/photos/b.jpg'];

        // Act
        final results = UrlUtils.toAbsoluteUrls(urls);

        // Assert
        expect(results[0], 'http://example.com/a.jpg');
        expect(results[1], startsWith('http'));
        expect(results[1], contains('api/photos/b.jpg'));
      });

      test('returns empty list for empty input', () {
        // Act & Assert
        expect(UrlUtils.toAbsoluteUrls([]), isEmpty);
      });

      test('returns a list with the same length as the input', () {
        // Arrange
        final urls = ['/a.jpg', '/b.jpg', '/c.jpg'];

        // Act
        final results = UrlUtils.toAbsoluteUrls(urls);

        // Assert
        expect(results.length, 3);
      });

      test('preserves order of URLs', () {
        // Arrange
        final urls = [
          'http://example.com/first.jpg',
          'http://example.com/second.jpg',
        ];

        // Act
        final results = UrlUtils.toAbsoluteUrls(urls);

        // Assert
        expect(results[0], contains('first'));
        expect(results[1], contains('second'));
      });
    });
  });
}
