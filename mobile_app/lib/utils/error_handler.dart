import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ErrorHandler {
  static void showErrorSnackBar(BuildContext context, String message,
      {Duration? duration}) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: duration ?? const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message,
      {Duration? duration}) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  static void showInfoSnackBar(BuildContext context, String message,
      {Duration? duration}) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  static String getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Authentication error: ${e.message ?? 'Unknown error occurred'}';
    }
  }

  static String getFirestoreErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You don\'t have permission to perform this action.';
      case 'unavailable':
        return 'Service is currently unavailable. Please try again later.';
      case 'deadline-exceeded':
        return 'Request timed out. Please try again.';
      case 'resource-exhausted':
        return 'Service quota exceeded. Please try again later.';
      case 'failed-precondition':
        return 'Operation failed due to invalid conditions.';
      case 'aborted':
        return 'Operation was aborted. Please try again.';
      case 'out-of-range':
        return 'Invalid data range provided.';
      case 'unimplemented':
        return 'This feature is not yet implemented.';
      case 'internal':
        return 'Internal server error. Please try again later.';
      case 'data-loss':
        return 'Data corruption detected. Please contact support.';
      case 'unauthenticated':
        return 'Authentication required. Please sign in again.';
      default:
        return 'Database error: ${e.message ?? 'Unknown error occurred'}';
    }
  }

  static String getGenericErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return getFirebaseAuthErrorMessage(error);
    } else if (error is FirebaseException) {
      return getFirestoreErrorMessage(error);
    } else if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  static Future<T?> handleAsyncOperation<T>(
    Future<T> operation, {
    BuildContext? context,
    String? errorMessage,
    bool showSuccessMessage = false,
    String? successMessage,
  }) async {
    try {
      final result = await operation;

      if (showSuccessMessage && context != null && context.mounted) {
        showSuccessSnackBar(
            context, successMessage ?? 'Operation completed successfully');
      }

      return result;
    } catch (e) {
      final message = errorMessage ?? getGenericErrorMessage(e);

      if (context != null && context.mounted) {
        showErrorSnackBar(context, message);
      }

      // Log error for debugging
      debugPrint('Error in async operation: $e');

      return null;
    }
  }

  static void showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? actionText,
    VoidCallback? onAction,
  }) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          if (actionText != null && onAction != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onAction();
              },
              child: Text(actionText),
            ),
        ],
      ),
    );
  }

  static void showRetryDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onRetry,
  }) {
    showErrorDialog(
      context,
      title: title,
      message: message,
      actionText: 'Retry',
      onAction: onRetry,
    );
  }

  static bool isNetworkError(dynamic error) {
    if (error is FirebaseException) {
      return error.code == 'network-request-failed' ||
          error.code == 'unavailable' ||
          error.code == 'deadline-exceeded';
    }

    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('unreachable');
  }

  static bool isPermissionError(dynamic error) {
    if (error is FirebaseException) {
      return error.code == 'permission-denied' ||
          error.code == 'unauthenticated';
    }

    final errorString = error.toString().toLowerCase();
    return errorString.contains('permission') ||
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden');
  }
}

// Extension to make error handling easier in widgets
extension ErrorHandlerExtension on BuildContext {
  void showError(String message) {
    ErrorHandler.showErrorSnackBar(this, message);
  }

  void showSuccess(String message) {
    ErrorHandler.showSuccessSnackBar(this, message);
  }

  void showInfo(String message) {
    ErrorHandler.showInfoSnackBar(this, message);
  }
}
