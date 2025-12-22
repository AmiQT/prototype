import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'network_service.dart';
import 'cache_service.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  final NetworkService _networkService = NetworkService();
  final CacheService _cacheService = CacheService();
  SharedPreferences? _prefs;

  // Offline queue for actions to sync when online
  final List<OfflineAction> _pendingActions = [];

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPendingActions();
    
    // Listen for network changes to sync when online
    // Note: You'll need to implement a proper stream listener
    debugPrint('📴 Offline service initialized');
  }

  // Queue action for when network is available
  Future<void> queueAction(OfflineAction action) async {
    _pendingActions.add(action);
    await _savePendingActions();
    debugPrint('📴 Queued offline action: ${action.type}');
  }

  // Sync all pending actions when network is available
  Future<void> syncPendingActions() async {
    if (!_networkService.isConnected || _pendingActions.isEmpty) {
      return;
    }

    debugPrint('📴 Syncing ${_pendingActions.length} pending actions...');
    
    final actionsToSync = List<OfflineAction>.from(_pendingActions);
    _pendingActions.clear();

    for (final action in actionsToSync) {
      try {
        await _executeAction(action);
        debugPrint('📴 Synced action: ${action.type}');
      } catch (e) {
        debugPrint('📴 Failed to sync action: ${action.type} - $e');
        // Re-queue failed actions
        _pendingActions.add(action);
      }
    }

    await _savePendingActions();
    debugPrint('📴 Sync completed. ${_pendingActions.length} actions remaining');
  }

  // Execute a specific action
  Future<void> _executeAction(OfflineAction action) async {
    switch (action.type) {
      case OfflineActionType.createProfile:
        // Implement profile creation sync
        break;
      case OfflineActionType.updateProfile:
        // Implement profile update sync
        break;
      case OfflineActionType.createAchievement:
        // Implement achievement creation sync
        break;
      case OfflineActionType.uploadImage:
        // Implement image upload sync
        break;
    }
  }

  // Save pending actions to persistent storage
  Future<void> _savePendingActions() async {
    if (_prefs == null) return;
    
    final actionsJson = _pendingActions.map((a) => a.toJson()).toList();
    await _prefs!.setString('pending_actions', jsonEncode(actionsJson));
  }

  // Load pending actions from persistent storage
  Future<void> _loadPendingActions() async {
    if (_prefs == null) return;
    
    final actionsString = _prefs!.getString('pending_actions');
    if (actionsString != null) {
      final actionsList = jsonDecode(actionsString) as List;
      _pendingActions.clear();
      _pendingActions.addAll(
        actionsList.map((json) => OfflineAction.fromJson(json)),
      );
      debugPrint('📴 Loaded ${_pendingActions.length} pending actions');
    }
  }

  // Get offline-capable data
  Future<T?> getOfflineData<T>(
    String key,
    Future<T> Function() onlineDataFetcher,
  ) async {
    // Try cache first
    final cachedData = _cacheService.get<T>(key);
    if (cachedData != null) {
      debugPrint('📴 Offline data available: $key');
      return cachedData;
    }

    // If online, fetch and cache
    if (_networkService.isConnected) {
      try {
        final data = await onlineDataFetcher();
        await _cacheService.store(key, data, duration: CacheService.longCache);
        return data;
      } catch (e) {
        debugPrint('📴 Failed to fetch online data: $key - $e');
      }
    }

    debugPrint('📴 No offline data available: $key');
    return null;
  }

  // Check if app can function offline
  bool canWorkOffline() {
    // Check if essential data is cached
    final hasUserProfile = _cacheService.isValid(CacheKeys.userProfile);
    final hasBasicData = _cacheService.isValid(CacheKeys.events);
    
    return hasUserProfile && hasBasicData;
  }

  // Get offline status summary
  Map<String, dynamic> getOfflineStatus() {
    return {
      'isOnline': _networkService.isConnected,
      'canWorkOffline': canWorkOffline(),
      'pendingActions': _pendingActions.length,
      'cacheInfo': _cacheService.getCacheInfo(),
    };
  }
}

// Offline action model
class OfflineAction {
  final String id;
  final OfflineActionType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  OfflineAction({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory OfflineAction.fromJson(Map<String, dynamic> json) {
    return OfflineAction(
      id: json['id'],
      type: OfflineActionType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

enum OfflineActionType {
  createProfile,
  updateProfile,
  createAchievement,
  uploadImage,
}