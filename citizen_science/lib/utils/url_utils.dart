import '../providers/api_service.dart';

/// Utility class for URL transformations.
class UrlUtils {
  /// Converts a relative URL to an absolute URL using the base API URL.
  ///
  /// If [url] is already absolute (starts with http:// or https://),
  /// returns it unchanged. Otherwise, prepends the base URL.
  static String toAbsoluteUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    String cleanUrl = url.startsWith('/') ? url.substring(1) : url;
    return '${ApiService.baseUrl}/$cleanUrl';
  }

  /// Converts a list of relative URLs to absolute URLs.
  static List<String> toAbsoluteUrls(List<String> urls) {
    return urls.map((url) => toAbsoluteUrl(url)).toList();
  }
}
