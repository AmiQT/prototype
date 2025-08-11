import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration class
/// Provides fallback mechanisms for environment variables
class AppConfig {
  static const String _openRouterApiKeyEnv = 'OPENROUTER_API_KEY';
  static const String _geminiApiKeyEnv = 'GEMINI_API_KEY';

  /// Get OpenRouter API key with fallback mechanisms
  static String? getOpenRouterApiKey() {
    try {
      // Try to get from dotenv first
      final apiKey = dotenv.env[_openRouterApiKeyEnv];
      if (apiKey?.isNotEmpty == true) {
        if (kDebugMode) {
          debugPrint('AppConfig: OpenRouter API key found in dotenv');
        }
        return apiKey;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppConfig: Error accessing dotenv: $e');
      }
    }

    // If dotenv fails, try to get from platform environment
    try {
      const apiKey = String.fromEnvironment(_openRouterApiKeyEnv);
      if (apiKey.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
              'AppConfig: OpenRouter API key found in platform environment');
        }
        return apiKey;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppConfig: Error accessing platform environment: $e');
      }
    }

    // No fallback - API key must be provided via environment variables
    if (kDebugMode) {
      debugPrint('AppConfig: No OpenRouter API key found in environment');
    }

    return null;
  }

  /// Get Gemini API key with secure fallback
  static String? getGeminiApiKey() {
    try {
      // Try to get from dotenv first
      if (kDebugMode) {
        debugPrint('AppConfig: Checking dotenv for Gemini API key...');
        debugPrint(
            'AppConfig: Available dotenv keys: ${dotenv.env.keys.toList()}');
      }
      final apiKey = dotenv.env[_geminiApiKeyEnv];
      if (kDebugMode) {
        // SECURITY: Never log the actual API key value
        debugPrint(
            'AppConfig: Gemini API key status: ${apiKey?.isNotEmpty == true ? "found" : "not found"}');
      }
      if (apiKey?.isNotEmpty == true) {
        if (kDebugMode) {
          debugPrint('AppConfig: Gemini API key found in dotenv');
        }
        return apiKey;
      } else {
        if (kDebugMode) {
          debugPrint('AppConfig: Gemini API key is null or empty in dotenv');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppConfig: Error accessing dotenv for Gemini: $e');
      }
    }

    // If dotenv fails, try to get from platform environment
    try {
      const apiKey = String.fromEnvironment(_geminiApiKeyEnv);
      if (apiKey.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('AppConfig: Gemini API key found in platform environment');
        }
        return apiKey;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'AppConfig: Error accessing platform environment for Gemini: $e');
      }
    }

    if (kDebugMode) {
      debugPrint('AppConfig: No Gemini API key found in environment');
    }

    return null;
  }

  /// Check if OpenRouter API key is configured
  static bool get hasApiKey {
    final apiKey = getOpenRouterApiKey();
    return apiKey?.isNotEmpty == true;
  }

  /// Check if Gemini API key is configured
  static bool get hasGeminiApiKey {
    final apiKey = getGeminiApiKey();
    return apiKey?.isNotEmpty == true;
  }

  /// Get API key preview for debugging (secure - only shows first 4 chars)
  static String? getApiKeyPreview() {
    final apiKey = getOpenRouterApiKey();
    if (apiKey?.isNotEmpty == true) {
      // SECURITY: Only show first 4 characters to prevent key exposure
      return '${apiKey!.substring(0, 4)}***';
    }
    return null;
  }

  /// Get Gemini API key preview for debugging (secure - only shows first 4 chars)
  static String? getGeminiApiKeyPreview() {
    final apiKey = getGeminiApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      // SECURITY: Only show first 4 characters to prevent key exposure
      return '${apiKey.substring(0, 4)}***';
    }
    return null;
  }

  /// Initialize configuration
  static Future<void> initialize() async {
    if (kDebugMode) {
      debugPrint('AppConfig: Initializing configuration...');
    }

    // First, check if .env file exists in assets
    try {
      final envContent = await rootBundle.loadString('assets/.env');
      if (kDebugMode) {
        debugPrint('AppConfig: .env file found in assets folder');
        debugPrint('AppConfig: .env content length: ${envContent.length}');
        // SECURITY: Don't log actual content, just basic info
        debugPrint('AppConfig: .env file loaded successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppConfig: .env file not accessible via rootBundle: $e');
      }
    }

    try {
      // Try loading from root level first (for development)
      await dotenv.load(fileName: '.env');
      if (kDebugMode) {
        debugPrint('AppConfig: Dotenv loaded successfully from root');
        debugPrint(
            'AppConfig: Loaded ${dotenv.env.length} environment variables');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppConfig: Failed to load .env from root: $e');
      }

      // Try assets folder as fallback
      try {
        await dotenv.load(fileName: 'assets/.env');
        if (kDebugMode) {
          debugPrint(
              'AppConfig: Dotenv loaded successfully from assets folder');
          debugPrint(
              'AppConfig: Loaded ${dotenv.env.length} environment variables');
        }
      } catch (e2) {
        if (kDebugMode) {
          debugPrint('AppConfig: All dotenv loading methods failed: $e2');
        }
      }
    }

    final hasOpenRouterKey = hasApiKey;
    final hasGeminiKey = hasGeminiApiKey;
    if (kDebugMode) {
      debugPrint('AppConfig: OpenRouter API key configured: $hasOpenRouterKey');
      debugPrint('AppConfig: Gemini API key configured: $hasGeminiKey');

      if (hasOpenRouterKey) {
        debugPrint(
            'AppConfig: OpenRouter API key preview: ${getApiKeyPreview()}');
      }

      if (hasGeminiKey) {
        debugPrint(
            'AppConfig: Gemini API key preview: ${getGeminiApiKeyPreview()}');
      }
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
