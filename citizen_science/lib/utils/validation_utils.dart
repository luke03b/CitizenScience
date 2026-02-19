/// Result of a validation check.
class ValidationResult {
  /// Whether the validation passed.
  final bool isValid;
  
  /// Error message if validation failed, null otherwise.
  final String? errorMessage;

  const ValidationResult({
    required this.isValid,
    this.errorMessage,
  });

  /// Factory for a successful validation.
  const ValidationResult.success() : isValid = true, errorMessage = null;

  /// Factory for a failed validation.
  const ValidationResult.error(String message) : isValid = false, errorMessage = message;
}

/// Utility class for common validation operations.
class ValidationUtils {
  /// Validates latitude and longitude coordinates.
  /// 
  /// Checks that both values are present, parseable as doubles,
  /// and within valid ranges (-90 to 90 for latitude, -180 to 180 for longitude).
  static ValidationResult validateCoordinates(String? latStr, String? lngStr) {
    if (latStr == null || latStr.isEmpty || lngStr == null || lngStr.isEmpty) {
      return const ValidationResult.error('Seleziona una posizione');
    }

    final lat = double.tryParse(latStr);
    final lng = double.tryParse(lngStr);
    
    if (lat == null || lng == null) {
      return const ValidationResult.error('Coordinate non valide');
    }

    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return const ValidationResult.error('Coordinate fuori dai limiti validi');
    }

    return const ValidationResult.success();
  }
}
