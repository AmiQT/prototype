import 'package:flutter/foundation.dart';
import 'network_service.dart';
import 'cache_service.dart';
import 'optimized_backend_service.dart';
import 'image_optimization_service.dart';
import 'offline_service.dart';

class AppInitializationService {
  static final AppInitializationService _instance = AppInitializationService._internal();
  factory AppInitializationService() => _instance;
  AppInitializationService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🚀 Starting app initialization...');

      // Initialize core services in order
      await _initializeCoreServices();
      
      // Initialize optimization services
      await _initializeOptimizationServices();
      
      // Perform initial setup
      await _performInitialSetup();

      _isInitialized = true;
      debugPrint('✅ App initialization completed successfully');
    } catch (e) {
      debugPrint('❌ App initialization failed: $e');
      rethrow;
    }
  }

  Future<void> _initializeCoreServices() async {
    debugPrint('📱 Initializing core services...');
    
    // Network service (must be first)
    await NetworkService().initialize();
    
    // Cache service
    await CacheService().initialize();
    
    debugPrint('✅ Core services initialized');
  }

  Future<void> _initializeOptimizationServices() async {
    debugPrint('⚡ Initializing optimization services...');
    
    // Backend service with optimizations
    await OptimizedBackendService().initialize();
    
    // Image optimization
    await ImageOptimizationService().initialize();
    
    // Offline support
    await OfflineService().initialize();
    
    debugPrint('✅ Optimization services initialized');
  }

  Future<void> _performInitialSetup() async {
    debugPrint('🔧 Performing initial setup...');
    
    // Clean expired cache
    await CacheService().cleanExpired();
    
    // Clean old images
    await ImageOptimizationService().cleanCache();
    
    // Sync pending offline actions
    await OfflineService().syncPendingActions();
    
    // Reset data usage tracking for new session
    DataUsageTracker().resetSession();
    
    debugPrint('✅ Initial setup completed');
  }

  // Get initialization status
  Map<String, dynamic> getInitializationStatus() {
    return {
      'isInitialized': _isInitialized,
      'networkStatus': NetworkService().isConnected,
      'cacheInfo': CacheService().getCacheInfo(),
      'offlineStatus': OfflineService().getOfflineStatus(),
      'dataUsage': DataUsageTracker().getSessionUsage(),
    };
  }

  // Cleanup resources
  Future<void> dispose() async {
    debugPrint('🧹 Cleaning up app services...');
    
    NetworkService().dispose();
    OptimizedBackendService().dispose();
    
    _isInitialized = false;
    debugPrint('✅ App cleanup completed');
  }
}