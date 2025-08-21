import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

      // Load API keys from environment
      _openRouterApiKey = dotenv.env['OPENROUTER_API_KEY'];
      _geminiApiKey = dotenv.env['GEMINI_API_KEY'];

      if (kDebugMode) {
        debugPrint('AppConfig: Environment variables loaded');
        debugPrint('AppConfig: OpenRouter API key present: $hasApiKey');
        debugPrint('AppConfig: Gemini API key present: $hasGeminiApiKey');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppConfig: Error loading environment variables: $e');
        debugPrint('AppConfig: Continuing without API keys...');
      }
      // Set default values if loading fails
      _openRouterApiKey = null;
      _geminiApiKey = null;
    }
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
  static const int apiTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;

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
