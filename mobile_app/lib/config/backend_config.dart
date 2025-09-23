/*
 * Backend Configuration for Production APK
 * Centralized configuration to ensure all services use the correct backend URL
 */

class BackendConfig {
  // Use Render backend for production APK (stable URL)
  static const String baseUrl = 'https://prototype-348e.onrender.com';

  // Headers for API requests
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // API endpoints
  static const Map<String, String> endpoints = {
    'health': '/health',
    'auth': '/api/auth',
    'users': '/api/users',
    'profiles': '/api/profiles',
    'events': '/api/events',
    'media': '/api/media',
    'search': '/api/search',
    'analytics': '/api/analytics',
    'showcase': '/api/showcase',
    'sync': '/api/sync',
  };

  // Get full URL for endpoint
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  // Check if backend is reachable
  static bool get isProductionMode => baseUrl.contains('render.com');
  static bool get isDevelopmentMode =>
      baseUrl.contains('ngrok') || baseUrl.contains('localhost');
}
