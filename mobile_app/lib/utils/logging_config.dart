import 'package:flutter/foundation.dart';

/// Centralized logging configuration for the entire app
/// This file allows easy control over what gets logged and at what level
///
/// RECOMMENDED SETTING: WARNING MODE (globalLogLevel = 2)
/// This provides errors and warnings only, reducing terminal spam while keeping important information
class LoggingConfig {
  // Master switch - set to false to disable ALL logging
  static const bool enableAllLogging = false;

  // Global log level (0 = None, 1 = Errors only, 2 = Warnings + Errors, 3 = Info + Warnings + Errors, 4 = Verbose)
  // CLEAN MODE: Set to 1 for Errors only (minimal terminal output)
  static const int globalLogLevel = 1; // Default: Errors only

  // Category-specific logging controls
  // Most categories are disabled by default to reduce terminal spam
  static const bool enableAuthLogging = false; // Authentication logs
  static const bool enableProfileLogging = false; // Profile management logs
  static const bool enableShowcaseLogging = false; // Showcase/post logs
  static const bool enableSearchLogging = false; // Search functionality logs
  static const bool enableEventLogging = false; // Event management logs
  static const bool enableNetworkLogging = false; // Network/API logs
  static const bool enableDatabaseLogging = false; // Database operation logs
  static const bool enableInitializationLogging = false; // App startup logs

  // These are usually kept enabled as they provide valuable information
  static const bool enablePerformanceLogging =
      true; // Performance monitoring (always useful)
  static const bool enableErrorLogging = true; // Error logging (always useful)

  // Verbose logging controls
  static const bool enableVerboseLogging = false; // Detailed debug information
  static const bool enableStackTraceLogging = false; // Stack trace logging

  // Log level constants
  static const int LOG_LEVEL_NONE = 0;
  static const int LOG_LEVEL_ERROR = 1;
  static const int LOG_LEVEL_WARNING = 2;
  static const int LOG_LEVEL_INFO = 3;
  static const int LOG_LEVEL_VERBOSE = 4;

  // Helper methods to check if logging should be enabled
  static bool shouldLog(int level) {
    if (!enableAllLogging) return false;
    return level <= globalLogLevel;
  }

  static bool shouldLogAuth() => enableAuthLogging && shouldLog(LOG_LEVEL_INFO);
  static bool shouldLogProfile() =>
      enableProfileLogging && shouldLog(LOG_LEVEL_INFO);
  static bool shouldLogShowcase() =>
      enableShowcaseLogging && shouldLog(LOG_LEVEL_INFO);
  static bool shouldLogSearch() =>
      enableSearchLogging && shouldLog(LOG_LEVEL_INFO);
  static bool shouldLogEvent() =>
      enableEventLogging && shouldLog(LOG_LEVEL_INFO);
  static bool shouldLogNetwork() =>
      enableNetworkLogging && shouldLog(LOG_LEVEL_INFO);
  static bool shouldLogDatabase() =>
      enableDatabaseLogging && shouldLog(LOG_LEVEL_INFO);
  static bool shouldLogInit() =>
      enableInitializationLogging && shouldLog(LOG_LEVEL_INFO);
  static bool shouldLogPerformance() => enablePerformanceLogging;
  static bool shouldLogError() => enableErrorLogging;
  static bool shouldLogVerbose() =>
      enableVerboseLogging && shouldLog(LOG_LEVEL_VERBOSE);
  static bool shouldLogStackTrace() => enableStackTraceLogging;

  // Quick logging level changes for development
  static void setLogLevel(int level) {
    // This would need to be implemented with a state management solution
    // For now, just update the constant above
    print('To change log level, update globalLogLevel in LoggingConfig');
  }

  // Development presets
  static void setDevelopmentMode() {
    // Set to verbose logging for development
    print(
        'Development mode: Set globalLogLevel to 4 and enableVerboseLogging to true');
  }

  static void setProductionMode() {
    // Set to error-only logging for production
    print(
        'Production mode: Set globalLogLevel to 1 and disable most logging categories');
  }

  static void setDebugMode() {
    // Set to warnings + errors for debugging (RECOMMENDED)
    print(
        'Debug mode: Set globalLogLevel to 2 and enable only essential logging');
  }

  // Quick preset methods
  static void enableAllCategories() {
    print(
        'To enable all categories, set all enable*Logging to true and globalLogLevel to 4');
  }

  static void disableAllCategories() {
    print('To disable all categories, set enableAllLogging to false');
  }

  static void enableOnlyErrors() {
    print(
        'To enable only errors, set globalLogLevel to 1 and disable all enable*Logging');
  }
}
