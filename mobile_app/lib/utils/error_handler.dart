import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'debug_config.dart';

class ErrorHandler {
  static void handleError(dynamic error, StackTrace? stackTrace) {
    if (kDebugMode) {
      DebugConfig.logError('Error: $error');
      if (stackTrace != null) {
        DebugConfig.logError('StackTrace: $stackTrace');
      }
    }

    // Handle Supabase specific errors
    if (error is AuthException) {
      _handleAuthError(error);
    } else if (error is PostgrestException) {
      _handleDatabaseError(error);
    } else if (error is StorageException) {
      _handleStorageError(error);
    } else {
      _handleGenericError(error);
    }
  }

  static void _handleAuthError(AuthException error) {
    if (kDebugMode) {
      DebugConfig.logError('Auth Error: ${error.message}');
    }

    switch (error.statusCode) {
      case '400':
        DebugConfig.logWarning('Bad request - check your input data');
        break;
      case '401':
        DebugConfig.logWarning('Unauthorized - please sign in again');
        break;
      case '403':
        DebugConfig.logWarning('Forbidden - insufficient permissions');
        break;
      case '422':
        DebugConfig.logWarning('Validation error - check your data format');
        break;
      default:
        DebugConfig.logWarning('Authentication error occurred');
    }
  }

  static void _handleDatabaseError(PostgrestException error) {
    if (kDebugMode) {
      DebugConfig.logError('Database Error: ${error.message}');
      DebugConfig.logError('Details: ${error.details}');
      DebugConfig.logError('Hint: ${error.hint}');
    }
  }

  static void _handleStorageError(StorageException error) {
    if (kDebugMode) {
      DebugConfig.logError('Storage Error: ${error.message}');
      DebugConfig.logError('Status Code: ${error.statusCode}');
    }
  }

  static void _handleGenericError(dynamic error) {
    if (kDebugMode) {
      DebugConfig.logError('Generic Error: $error');
    }
  }

  static String getUserFriendlyMessage(dynamic error) {
    if (error is AuthException) {
      switch (error.message) {
        case 'Invalid login credentials':
          return 'Invalid email or password. Please try again.';
        case 'Email not confirmed':
          return 'Please confirm your email address before signing in.';
        case 'User already registered':
          return 'An account with this email already exists.';
        default:
          return 'Authentication error. Please try again.';
      }
    } else if (error is PostgrestException) {
      return 'Data operation failed. Please try again.';
    } else if (error is StorageException) {
      return 'File operation failed. Please try again.';
    } else {
      return 'An error occurred. Please try again.';
    }
  }

  // ==================== UI HELPER METHODS ====================
  // These methods are added for compatibility with existing UI code

  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
