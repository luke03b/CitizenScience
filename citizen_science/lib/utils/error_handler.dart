import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';
import '../l10n/app_locale.dart';

/// Utility class for handling and formatting error messages.
/// 
/// Converts various exception types into user-friendly localized messages.
class ErrorHandler {
  /// Maximum length for user-friendly error messages from backend.
  /// Messages longer than this are likely to be technical error traces.
  static const int _maxUserFriendlyMessageLength = 200;

  /// Gets a user-friendly error message from an exception.
  /// 
  /// Maps common exception types to localized error messages.
  /// Handles network errors, HTTP errors, and other common exceptions.
  static String getErrorMessage(BuildContext context, dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Network connectivity errors
    if (error is SocketException || 
        errorString.contains('failed to fetch') ||
        errorString.contains('network error') ||
        errorString.contains('socketexception') ||
        errorString.contains('no address associated')) {
      return AppLocale.errorNetworkConnection.getString(context);
    }
    
    // Timeout errors
    if (error is TimeoutException || 
        errorString.contains('timeout') ||
        errorString.contains('timed out')) {
      return AppLocale.errorTimeout.getString(context);
    }
    
    // HTTP Client errors
    if (error is http.ClientException) {
      return AppLocale.errorNetworkConnection.getString(context);
    }
    
    // Authentication errors
    if (errorString.contains('invalid credentials') ||
        errorString.contains('credenziali non valide') ||
        errorString.contains('unauthorized') ||
        errorString.contains('401')) {
      return AppLocale.errorInvalidCredentials.getString(context);
    }
    
    if (errorString.contains('wrong password') ||
        errorString.contains('password errata') ||
        errorString.contains('incorrect password')) {
      return AppLocale.errorWrongPassword.getString(context);
    }
    
    // Email errors
    if (errorString.contains('email already exists') ||
        errorString.contains('email già registrata') ||
        errorString.contains('duplicate email')) {
      return AppLocale.errorEmailAlreadyExists.getString(context);
    }
    
    if (errorString.contains('invalid email') ||
        errorString.contains('email non valida')) {
      return AppLocale.errorInvalidEmail.getString(context);
    }
    
    // Password errors
    if (errorString.contains('weak password') ||
        errorString.contains('password debole') ||
        errorString.contains('password too short')) {
      return AppLocale.errorWeakPassword.getString(context);
    }
    
    // Authorization errors
    if (errorString.contains('forbidden') ||
        errorString.contains('403') ||
        errorString.contains('non autorizzato')) {
      return AppLocale.errorUnauthorized.getString(context);
    }
    
    // Not found errors
    if (errorString.contains('not found') ||
        errorString.contains('404') ||
        errorString.contains('non trovato')) {
      return AppLocale.errorNotFound.getString(context);
    }
    
    // Server errors
    if (errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504') ||
        errorString.contains('internal server error') ||
        errorString.contains('bad gateway') ||
        errorString.contains('service unavailable')) {
      return AppLocale.errorServerUnavailable.getString(context);
    }
    
    // Validation errors
    if (errorString.contains('invalid data') ||
        errorString.contains('validation failed') ||
        errorString.contains('dati non validi')) {
      return AppLocale.errorInvalidData.getString(context);
    }
    
    // If error message is already a user-friendly message (from backend)
    // Check if it's a generic Exception with a custom message
    if (error is Exception && 
        !errorString.contains('clientexception') &&
        !errorString.contains('socketexception') &&
        !errorString.contains('timeoutexception')) {
      // Get the original error message
      String message = error.toString();
      
      // Remove "Exception: " prefix if it exists (case-insensitive check)
      if (message.toLowerCase().startsWith('exception: ')) {
        message = message.substring(11); // Remove "Exception: " prefix
      }
      
      // If the message looks like a user-friendly message (short and simple), return it
      // We allow colons as they might be part of legitimate user messages
      if (message.isNotEmpty && 
          message.length < _maxUserFriendlyMessageLength &&
          !message.contains('stack trace') &&
          !message.contains('stacktrace') &&
          !message.contains('\n')) {
        return message;
      }
    }
    
    // Default to generic error message
    return AppLocale.errorUnexpected.getString(context);
  }
}
