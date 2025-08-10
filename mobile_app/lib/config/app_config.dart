import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration class
/// Provides fallback mechanisms for environment variables
class AppConfig {
  static const String _openRouterApiKeyEnv = 'OPENROUTER_API_KEY';

  /// Get OpenRouter API key with fallback mechanisms
  static String? getOpenRouterApiKey() {
    try {
      // Try to get from dotenv first
      final apiKey = dotenv.env[_openRouterApiKeyEnv];
      if (apiKey?.isNotEmpty == true) {
        debugPrint('AppConfig: API key found in dotenv');
        return apiKey;
      }
    } catch (e) {
      debugPrint('AppConfig: Error accessing dotenv: $e');
    }

    // If dotenv fails, try to get from platform environment
    try {
      const apiKey = String.fromEnvironment(_openRouterApiKeyEnv);
      if (apiKey.isNotEmpty) {
        debugPrint('AppConfig: API key found in platform environment');
        return apiKey;
      }
    } catch (e) {
      debugPrint('AppConfig: Error accessing platform environment: $e');
    }

    // Fallback: Return hardcoded key for testing (TEMPORARY)
    // TODO: Remove this in production
    const fallbackKey =
        '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';
    if (fallbackKey.isNotEmpty) {
      debugPrint('AppConfig: Using fallback API key for testing');
      return fallbackKey;
    }

    debugPrint('AppConfig: No API key found in any environment');
    return null;
  }

  /// Check if API key is configured
  static bool get hasApiKey {
    final apiKey = getOpenRouterApiKey();
    return apiKey?.isNotEmpty == true;
  }

  /// Get API key preview for debugging
  static String? getApiKeyPreview() {
    final apiKey = getOpenRouterApiKey();
    if (apiKey?.isNotEmpty == true) {
      return '${apiKey!.substring(0, 10)}...';
    }
    return null;
  }

  /// Initialize configuration
  static Future<void> initialize() async {
    debugPrint('AppConfig: Initializing configuration...');

    try {
      await dotenv.load();
      debugPrint('AppConfig: Dotenv loaded successfully');
    } catch (e) {
      if (e.toString().contains('FileNotFoundError')) {
        debugPrint(
            'AppConfig: .env file not found - this is normal in some environments');
      } else {
        debugPrint('AppConfig: Failed to load dotenv: $e');
      }
    }

    final hasKey = hasApiKey;
    debugPrint('AppConfig: API key configured: $hasKey');

    if (hasKey) {
      debugPrint('AppConfig: API key preview: ${getApiKeyPreview()}');
    }
  }

  /// Get configuration summary for debugging
  static Map<String, dynamic> getDebugInfo() {
    return {
      'hasApiKey': hasApiKey,
      'apiKeyPreview': getApiKeyPreview(),
      'dotenvLoaded': _isDotenvLoaded(),
    };
  }

  /// Check if dotenv is loaded
  static bool _isDotenvLoaded() {
    try {
      dotenv.env.isEmpty; // This will throw if not loaded
      return true;
    } catch (e) {
      return false;
    }
  }
}
