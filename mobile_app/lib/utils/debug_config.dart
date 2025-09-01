import 'package:flutter/foundation.dart';
import 'logging_config.dart';

// Override debugPrint to silence all output
void _silentDebugPrint(String? message, {int? wrapWidth}) {
  // Do nothing - complete silence
}

class DebugConfig {
  // Use LoggingConfig for centralized control
  static const int globalLogLevel = LoggingConfig.globalLogLevel;

  // Override debugPrint for complete silence
  static void _silentPrint(String message) {
    // Do nothing - complete silence
  }

  // Specific logging controls - now controlled by LoggingConfig
  static const bool enableVerboseLogging = LoggingConfig.enableVerboseLogging;
  static const bool enableShowcaseLogging = LoggingConfig.enableShowcaseLogging;
  static const bool enableSearchLogging = LoggingConfig.enableSearchLogging;
  static const bool enableAuthLogging = LoggingConfig.enableAuthLogging;
  static const bool enableProfileLogging = LoggingConfig.enableProfileLogging;
  static const bool enableEventLogging = LoggingConfig.enableEventLogging;
  static const bool enableNetworkLogging = LoggingConfig.enableNetworkLogging;
  static const bool enableInitializationLogging =
      LoggingConfig.enableInitializationLogging;

  // Log level constants
  static const int LOG_LEVEL_NONE = LoggingConfig.LOG_LEVEL_NONE;
  static const int LOG_LEVEL_ERROR = LoggingConfig.LOG_LEVEL_ERROR;
  static const int LOG_LEVEL_WARNING = LoggingConfig.LOG_LEVEL_WARNING;
  static const int LOG_LEVEL_INFO = LoggingConfig.LOG_LEVEL_INFO;
  static const int LOG_LEVEL_VERBOSE = LoggingConfig.LOG_LEVEL_VERBOSE;

  // Conditional logging helper with level control
  static void logIfEnabled(String message,
      {bool verbose = false, int level = LOG_LEVEL_INFO}) {
    if (!LoggingConfig.shouldLog(level)) return;
    if (verbose && !enableVerboseLogging) return;
    _silentDebugPrint(message);
  }

  // Level-based logging methods
  static void logError(String message) {
    if (!LoggingConfig.enableAllLogging) return;
    if (LoggingConfig.shouldLogError() &&
        LoggingConfig.shouldLog(LOG_LEVEL_ERROR)) {
      _silentPrint('❌ ERROR: $message');
    }
  }

  static void logWarning(String message) {
    if (!LoggingConfig.enableAllLogging) return;
    if (LoggingConfig.shouldLog(LOG_LEVEL_WARNING)) {
      _silentPrint('⚠️ WARNING: $message');
    }
  }

  static void logInfo(String message) {
    if (!LoggingConfig.enableAllLogging) return;
    if (LoggingConfig.shouldLog(LOG_LEVEL_INFO)) {
      _silentPrint('ℹ️ INFO: $message');
    }
  }

  static void logVerbose(String message) {
    if (!LoggingConfig.enableAllLogging) return;
    if (LoggingConfig.shouldLogVerbose()) {
      _silentPrint('🔍 VERBOSE: $message');
    }
  }

  // Showcase specific logging
  static void logShowcase(String message) {
    if (!LoggingConfig.enableAllLogging) return;
    if (LoggingConfig.shouldLogShowcase()) {
      _silentPrint('📱 SHOWCASE: $message');
    }
  }

  // Search specific logging
  static void logSearch(String message) {
    if (!LoggingConfig.enableAllLogging) return;
    if (LoggingConfig.shouldLogSearch()) {
      _silentPrint('🔍 SEARCH: $message');
    }
  }

  // Auth specific logging
  static void logAuth(String message) {
    if (!LoggingConfig.enableAllLogging) return;
    if (LoggingConfig.shouldLogAuth()) {
      _silentPrint('🔐 AUTH: $message');
    }
  }

  // Profile specific logging
  static void logProfile(String message) {
    if (!LoggingConfig.enableAllLogging) return;
    if (LoggingConfig.shouldLogProfile()) {
      _silentPrint('👤 PROFILE: $message');
    }
  }

  // Event specific logging
  static void logEvent(String message) {
    if (!LoggingConfig.enableAllLogging) return;
    if (LoggingConfig.shouldLogEvent()) {
      _silentPrint('📅 EVENT: $message');
    }
  }

  // Network specific logging
  static void logNetwork(String message) {
    if (!LoggingConfig.enableAllLogging) return;
    if (LoggingConfig.shouldLogNetwork()) {
      _silentPrint('🌐 NETWORK: $message');
    }
  }

  // Initialization specific logging
  static void logInit(String message) {
    if (!LoggingConfig.enableAllLogging) return;
    if (LoggingConfig.shouldLogInit()) {
      _silentPrint('🚀 INIT: $message');
    }
  }

  // Performance logging (disabled for clean terminal)
  static void logPerformance(String message) {
    if (!LoggingConfig.enableAllLogging) return;
    if (LoggingConfig.shouldLogPerformance()) {
      _silentPrint('⚡ PERFORMANCE: $message');
    }
  }

  // Critical error logging (also disabled for silence)
  static void logCritical(String message) {
    if (!LoggingConfig.enableAllLogging) return;
    if (LoggingConfig.shouldLogError()) {
      _silentPrint('🚨 CRITICAL: $message');
    }
  }

  // Development helper - quick enable/disable for debugging
  static void enableVerboseMode() {
    print('To enable verbose mode, set globalLogLevel to 4 in LoggingConfig');
  }

  static void enableCleanMode() {
    print('Clean mode active: Only errors will be shown');
  }
}
