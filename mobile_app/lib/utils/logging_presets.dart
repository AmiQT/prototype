import 'logging_config.dart';

/// Predefined logging configurations for different development scenarios
/// Copy the configuration you want to use into logging_config.dart
class LoggingPresets {
  /// SILENT MODE - No logging at all
  /// Perfect for production or when you want complete silence
  static const Map<String, dynamic> silentMode = {
    'enableAllLogging': false,
    'globalLogLevel': 0,
    'enableVerboseLogging': false,
    'enableShowcaseLogging': false,
    'enableSearchLogging': false,
    'enableAuthLogging': false,
    'enableProfileLogging': false,
    'enableEventLogging': false,
    'enableNetworkLogging': false,
    'enableDatabaseLogging': false,
    'enableInitializationLogging': false,
    'enablePerformanceLogging': false,
    'enableErrorLogging': false,
  };

  /// ERROR ONLY MODE - Only critical errors are logged
  /// Good for production monitoring
  static const Map<String, dynamic> errorOnlyMode = {
    'enableAllLogging': true,
    'globalLogLevel': 1,
    'enableVerboseLogging': false,
    'enableShowcaseLogging': false,
    'enableSearchLogging': false,
    'enableAuthLogging': false,
    'enableProfileLogging': false,
    'enableEventLogging': false,
    'enableNetworkLogging': false,
    'enableDatabaseLogging': false,
    'enableInitializationLogging': false,
    'enablePerformanceLogging': false,
    'enableErrorLogging': true,
  };

  /// WARNING MODE - Errors and warnings only (RECOMMENDED FOR DEBUGGING)
  /// Good balance between information and noise
  static const Map<String, dynamic> warningMode = {
    'enableAllLogging': true,
    'globalLogLevel': 2,
    'enableVerboseLogging': false,
    'enableShowcaseLogging': false,
    'enableSearchLogging': false,
    'enableAuthLogging': false,
    'enableProfileLogging': false,
    'enableEventLogging': false,
    'enableNetworkLogging': false,
    'enableDatabaseLogging': false,
    'enableInitializationLogging': false,
    'enablePerformanceLogging': true,
    'enableErrorLogging': true,
  };

  /// INFO MODE - Errors, warnings, and basic info
  /// Good for development when you need more context
  static const Map<String, dynamic> infoMode = {
    'enableAllLogging': true,
    'globalLogLevel': 3,
    'enableVerboseLogging': false,
    'enableShowcaseLogging': false,
    'enableSearchLogging': false,
    'enableAuthLogging': false,
    'enableProfileLogging': false,
    'enableEventLogging': false,
    'enableNetworkLogging': false,
    'enableDatabaseLogging': false,
    'enableInitializationLogging': false,
    'enablePerformanceLogging': true,
    'enableErrorLogging': true,
  };

  /// VERBOSE MODE - Everything is logged
  /// Use only when debugging specific issues
  static const Map<String, dynamic> verboseMode = {
    'enableAllLogging': true,
    'globalLogLevel': 4,
    'enableVerboseLogging': true,
    'enableShowcaseLogging': true,
    'enableSearchLogging': true,
    'enableAuthLogging': true,
    'enableProfileLogging': true,
    'enableEventLogging': true,
    'enableNetworkLogging': true,
    'enableDatabaseLogging': true,
    'enableInitializationLogging': true,
    'enablePerformanceLogging': true,
    'enableErrorLogging': true,
  };

  /// CUSTOM MODES - Specific configurations for different needs

  /// AUTH DEBUG MODE - Focus on authentication issues
  static const Map<String, dynamic> authDebugMode = {
    'enableAllLogging': true,
    'globalLogLevel': 3,
    'enableVerboseLogging': false,
    'enableShowcaseLogging': false,
    'enableSearchLogging': false,
    'enableAuthLogging': true, // Enable auth logging
    'enableProfileLogging': false,
    'enableEventLogging': false,
    'enableNetworkLogging': false,
    'enableDatabaseLogging': false,
    'enableInitializationLogging': false,
    'enablePerformanceLogging': true,
    'enableErrorLogging': true,
  };

  /// NETWORK DEBUG MODE - Focus on network/API issues
  static const Map<String, dynamic> networkDebugMode = {
    'enableAllLogging': true,
    'globalLogLevel': 3,
    'enableVerboseLogging': false,
    'enableShowcaseLogging': false,
    'enableSearchLogging': false,
    'enableAuthLogging': false,
    'enableProfileLogging': false,
    'enableEventLogging': false,
    'enableNetworkLogging': true, // Enable network logging
    'enableDatabaseLogging': false,
    'enableInitializationLogging': false,
    'enablePerformanceLogging': true,
    'enableErrorLogging': true,
  };

  /// PERFORMANCE MODE - Focus on performance monitoring
  static const Map<String, dynamic> performanceMode = {
    'enableAllLogging': true,
    'globalLogLevel': 2,
    'enableVerboseLogging': false,
    'enableShowcaseLogging': false,
    'enableSearchLogging': false,
    'enableAuthLogging': false,
    'enableProfileLogging': false,
    'enableEventLogging': false,
    'enableNetworkLogging': false,
    'enableDatabaseLogging': false,
    'enableInitializationLogging': false,
    'enablePerformanceLogging': true, // Enable performance logging
    'enableErrorLogging': true,
  };

  /// How to use these presets:
  ///
  /// 1. Choose the preset you want from above
  /// 2. Copy the values to lib/utils/logging_config.dart
  /// 3. Restart your app
  ///
  /// Example for WARNING MODE (recommended for debugging):
  ///
  /// In lib/utils/logging_config.dart, change:
  /// static const bool enableAllLogging = true;
  /// static const int globalLogLevel = 2;
  /// static const bool enableVerboseLogging = false;
  /// static const bool enableShowcaseLogging = false;
  /// static const bool enableSearchLogging = false;
  /// static const bool enableAuthLogging = false;
  /// static const bool enableProfileLogging = false;
  /// static const bool enableEventLogging = false;
  /// static const bool enableNetworkLogging = false;
  /// static const bool enableDatabaseLogging = false;
  /// static const bool enableInitializationLogging = false;
  /// static const bool enablePerformanceLogging = true;
  /// static const bool enableErrorLogging = true;
}
