import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// Removed debug config for production

class AppConfig {
  // API Keys (loaded from environment)
  static String? _openRouterApiKey;
  static String? _geminiApiKey;

  // Getters for API keys
  static bool get hasApiKey =>
      _openRouterApiKey != null && _openRouterApiKey!.isNotEmpty;
  static bool get hasGeminiApiKey =>
      _geminiApiKey != null && _geminiApiKey!.isNotEmpty;
  static String? get openRouterApiKey => _openRouterApiKey;
  static String? get geminiApiKey => _geminiApiKey;

  // Method-style getters for backward compatibility
  static String? getGeminiApiKey() => _geminiApiKey;
  static String? getOpenRouterApiKey() => _openRouterApiKey;

  // Preview methods for debugging (shows only first few characters)
  static String? getGeminiApiKeyPreview() {
    if (_geminiApiKey == null || _geminiApiKey!.isEmpty) return null;
    if (_geminiApiKey!.length <= 8) return _geminiApiKey;
    return '${_geminiApiKey!.substring(0, 8)}...';
  }

  static String? getOpenRouterApiKeyPreview() {
    if (_openRouterApiKey == null || _openRouterApiKey!.isEmpty) return null;
    if (_openRouterApiKey!.length <= 8) return _openRouterApiKey;
    return '${_openRouterApiKey!.substring(0, 8)}...';
  }

  // Initialize method to load environment variables
  static Future<void> initialize() async {
    try {
      // Load environment variables
      await dotenv.load(fileName: "assets/.env");

      // Load API keys from environment file (trim to avoid stray whitespace)
      final envOpenRouterKey =
          dotenv.env['OPENROUTER_API_KEY']?.trim() ?? dotenv.env['openrouter_api_key']?.trim();
      final envGeminiKey =
          dotenv.env['GEMINI_API_KEY']?.trim() ?? dotenv.env['gemini_api_key']?.trim();

      // Also support --dart-define values for CI / release builds
      const String defineOpenRouterKey =
          String.fromEnvironment('OPENROUTER_API_KEY', defaultValue: '');
      const String defineGeminiKey =
          String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

      // Pick first non-empty source for each key
      _openRouterApiKey = _sanitizeApiKey(envOpenRouterKey) ??
          _sanitizeApiKey(defineOpenRouterKey.isNotEmpty ? defineOpenRouterKey : null);
      _geminiApiKey = _sanitizeApiKey(envGeminiKey) ??
          _sanitizeApiKey(defineGeminiKey.isNotEmpty ? defineGeminiKey : null);

      if (kDebugMode) {
        debugPrint('Environment variables loaded');
        debugPrint('OpenRouter API key present: $hasApiKey');
        debugPrint('Gemini API key present: $hasGeminiApiKey');
        if (!hasGeminiApiKey) {
          debugPrint(
              '⚠️ Gemini API key not configured - chatbot features will be disabled');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading environment variables: $e');
        debugPrint('Continuing without API keys...');
        debugPrint(
            '⚠️ API keys not available - some features will be disabled');
      }
      // Set default values if loading fails
      _openRouterApiKey = null;
      _geminiApiKey = null;
    }
  }

  /// Treat placeholder or empty strings as missing keys.
  static String? _sanitizeApiKey(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed == 'your_openrouter_api_key_here' ||
        trimmed == 'your_gemini_api_key_here') {
      return null;
    }
    return trimmed;
  }
  // Cloud Development Configuration
  // Update these URLs after deploying your backend and web dashboard

  // Backend API URLs
  static const String backendUrl = kDebugMode
      ? 'http://localhost:8000' // Local development
      : 'https://prototype-348e.onrender.com'; // Cloud backend

  // Web Dashboard URL
  static const String webDashboardUrl =
      'https://prototype-talent-app.vercel.app';

  // Supabase URLs (already configured in supabase_config.dart)
  static const String supabaseUrl = 'https://xibffemtpboiecpeynon.supabase.co';

  // API Endpoints
  static const String apiBase = '$backendUrl/api';
  static const String authEndpoint = '$apiBase/auth';
  static const String usersEndpoint = '$apiBase/users';
  static const String eventsEndpoint = '$apiBase/events';
  static const String achievementsEndpoint = '$apiBase/achievements';
  static const String mediaEndpoint = '$apiBase/media';
  static const String searchEndpoint = '$apiBase/search';
  static const String analyticsEndpoint = '$apiBase/analytics';

  // Feature Flags
  static const bool enableCloudSync = true;
  static const bool enableOfflineMode = true;
  static const bool enablePushNotifications = true;

  // App Settings
  static const String appName = 'Student Talent Profiling App';
  static const String appVersion = '1.0.0';
  static const int apiTimeoutSeconds = 60; // Increased for Samsung devices
  static const int maxRetryAttempts = 5; // More retries for network issues

  // Development Settings
  static const bool enableDebugLogging = kDebugMode;
  static const bool enablePerformanceMonitoring = true;
  static const bool enableCrashReporting = !kDebugMode;

  // Media Settings
  static const int maxImageSizeMB = 10;
  static const int maxVideoSizeMB = 100;
  static const List<String> allowedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'webp'
  ];
  static const List<String> allowedVideoFormats = ['mp4', 'mov', 'avi'];

  // Cache Settings
  static const Duration cacheExpiration = Duration(days: 7);
  static const int maxCacheSizeMB = 100;

  // Security Settings
  static const bool enableSSLVerification = true;
  static const bool enableCertificatePinning = false;

  // Analytics Settings
  static const bool enableAnalytics = true;
  static const bool enableUserTracking = false;
  static const bool enableCrashAnalytics = true;
}
