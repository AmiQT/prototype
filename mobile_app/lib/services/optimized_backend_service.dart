import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'network_service.dart';
import 'cache_service.dart';
import '../config/supabase_config.dart';
import '../config/backend_config.dart';

class OptimizedBackendService {
  static const String baseUrl = BackendConfig.baseUrl; // Use stable backend URL

  static final OptimizedBackendService _instance =
      OptimizedBackendService._internal();
  factory OptimizedBackendService() => _instance;
  OptimizedBackendService._internal();

  final NetworkService _networkService = NetworkService();
  final CacheService _cacheService = CacheService();
  final OptimizedHttpClient _httpClient = OptimizedHttpClient();

  Future<void> initialize() async {
    await _networkService.initialize();
    await _cacheService.initialize();
    _httpClient.initialize();
    debugPrint('🚀 Optimized backend service initialized');
  }

  // Get Supabase auth token for authentication
  static Future<String?> _getAuthToken() async {
    try {
      final session = SupabaseConfig.auth.currentSession;
      if (session?.accessToken != null) {
        return session!.accessToken;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Optimized GET request with caching
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    Duration? cacheDuration,
    bool forceRefresh = false,
  }) async {
    // Build URL
    final uri = Uri.parse('$baseUrl$endpoint');
    final finalUri =
        queryParams != null ? uri.replace(queryParameters: queryParams) : uri;

    // Generate cache key
    final cacheKey = 'api_${finalUri.toString().hashCode}';

    try {
      // Try cache first (unless force refresh or no network)
      if (!forceRefresh && _networkService.isConnected) {
        final cachedData = _cacheService.get<Map<String, dynamic>>(cacheKey);
        if (cachedData != null) {
          debugPrint('📡 Cache hit: $endpoint');
          return cachedData;
        }
      }

      // If no network and no cache, throw error
      if (!_networkService.isConnected) {
        throw Exception('No internet connection and no cached data available');
      }

      // Get auth token
      final token = await _getAuthToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      // Make request with optimizations
      final response = await _httpClient.get(finalUri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Cache successful responses
        if (cacheDuration != null) {
          await _cacheService.store(cacheKey, data, duration: cacheDuration);
        }

        // Track data usage
        DataUsageTracker().trackDownload(response.contentLength ?? 0);

        debugPrint(
            '📡 API success: $endpoint (${response.contentLength ?? 0} bytes)');
        return data;
      } else {
        throw Exception(
            'API request failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('📡 API error: $endpoint - $e');

      // Try to return cached data as fallback
      final cachedData = _cacheService.get<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) {
        debugPrint('📡 Returning stale cache data for: $endpoint');
        return cachedData;
      }

      rethrow;
    }
  }

  // Optimized POST request
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool requiresWifi = false,
  }) async {
    try {
      // Check if WiFi is required for this operation
      if (requiresWifi && !_networkService.isOnWifi) {
        throw Exception('This operation requires WiFi connection');
      }

      if (!_networkService.isConnected) {
        throw Exception('No internet connection');
      }

      final token = await _getAuthToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final uri = Uri.parse('$baseUrl$endpoint');
      final body = jsonEncode(data);

      final response = await _httpClient.post(
        uri,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        // Track data usage
        DataUsageTracker().trackUpload(body.length);
        DataUsageTracker().trackDownload(response.contentLength ?? 0);

        debugPrint('📡 POST success: $endpoint');
        return responseData;
      } else {
        throw Exception(
            'POST request failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('📡 POST error: $endpoint - $e');
      rethrow;
    }
  }

  // Batch request for mobile data efficiency
  Future<List<Map<String, dynamic>>> batchGet(
    List<String> endpoints, {
    Duration cacheDuration = CacheService.mediumCache,
  }) async {
    final results = <Map<String, dynamic>>[];

    // If on mobile data, process in smaller batches
    final batchSize = _networkService.isOnMobile ? 3 : 10;

    for (int i = 0; i < endpoints.length; i += batchSize) {
      final batch = endpoints.skip(i).take(batchSize);
      final batchResults = await Future.wait(
        batch.map((endpoint) => get(endpoint, cacheDuration: cacheDuration)),
      );
      results.addAll(batchResults);

      // Reduced delay between batches for better performance
      if (_networkService.isOnMobile && i + batchSize < endpoints.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    return results;
  }

  // Prefetch data for offline use
  Future<void> prefetchCriticalData(String userId) async {
    if (!_networkService.isOnWifi) {
      debugPrint('📡 Skipping prefetch on mobile data');
      return;
    }

    try {
      debugPrint('📡 Starting critical data prefetch...');

      // Prefetch user profile
      await get('/api/profiles/$userId', cacheDuration: CacheService.longCache);

      // Prefetch user achievements
      await get('/api/achievements?user_id=$userId',
          cacheDuration: CacheService.mediumCache);

      // Prefetch recent events
      await get('/api/events?limit=20',
          cacheDuration: CacheService.mediumCache);

      debugPrint('📡 Critical data prefetch completed');
    } catch (e) {
      debugPrint('📡 Prefetch failed: $e');
    }
  }

  // Check data usage and warn user
  Future<bool> checkDataUsageWarning() async {
    if (_networkService.isOnWifi) return true;

    final tracker = DataUsageTracker();
    if (tracker.isHighDataUsage()) {
      // You can show a dialog here or return false to prevent the operation
      debugPrint('⚠️ High data usage detected');
      return false;
    }

    return true;
  }

  // Get network-optimized pagination
  Map<String, String> getOptimizedPagination({int page = 1}) {
    // Reduce page size on mobile data
    final pageSize = _networkService.isOnMobile ? 10 : 20;

    return {
      'page': page.toString(),
      'limit': pageSize.toString(),
    };
  }

  // Dispose resources
  void dispose() {
    _networkService.dispose();
    _httpClient.dispose();
  }
}
