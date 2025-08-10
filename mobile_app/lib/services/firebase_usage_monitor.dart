import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_models.dart';

/// Firebase usage monitoring service to stay within free tier limits
class FirebaseUsageMonitor {
  static final FirebaseUsageMonitor _instance =
      FirebaseUsageMonitor._internal();
  factory FirebaseUsageMonitor() => _instance;
  FirebaseUsageMonitor._internal();

  // Daily limits for Firebase Spark (free) plan
  static const int dailyReadLimit = 50000;
  static const int dailyWriteLimit = 20000;
  static const int dailyDeleteLimit = 20000;

  // Warning thresholds (80% of limits)
  static const int readWarningThreshold = 40000;
  static const int writeWarningThreshold = 16000;
  static const int deleteWarningThreshold = 16000;

  // Current day tracking
  String? _currentDate;
  int _dailyReads = 0;
  int _dailyWrites = 0;
  int _dailyDeletes = 0;

  // Callbacks for limit warnings
  final List<VoidCallback> _warningCallbacks = [];
  final List<VoidCallback> _limitCallbacks = [];

  /// Initialize the monitor
  Future<void> initialize() async {
    try {
      debugPrint('FirebaseUsageMonitor: Starting initialization...');
      await _loadTodayUsage();
      debugPrint(
          'FirebaseUsageMonitor: Initialized with reads: $_dailyReads, writes: $_dailyWrites, deletes: $_dailyDeletes');
    } catch (e) {
      debugPrint('FirebaseUsageMonitor: Initialization failed: $e');
      // Continue without Firebase monitoring for now
      debugPrint(
          'FirebaseUsageMonitor: Continuing without Firebase monitoring');
    }
  }

  /// Record a Firebase operation
  Future<void> recordOperation(String operationType, [int count = 1]) async {
    await _ensureCurrentDate();

    switch (operationType.toLowerCase()) {
      case 'read':
        _dailyReads += count;
        break;
      case 'write':
        _dailyWrites += count;
        break;
      case 'delete':
        _dailyDeletes += count;
        break;
    }

    await _saveTodayUsage();
    _checkThresholds();
  }

  /// Get today's usage statistics
  Future<FirebaseUsageStats> getTodayUsage() async {
    await _ensureCurrentDate();
    return FirebaseUsageStats(
      dailyReads: _dailyReads,
      dailyWrites: _dailyWrites,
      dailyDeletes: _dailyDeletes,
      date: DateTime.now(),
    );
  }

  /// Check if we're approaching limits
  bool get isApproachingLimits {
    return _dailyReads > readWarningThreshold ||
        _dailyWrites > writeWarningThreshold ||
        _dailyDeletes > deleteWarningThreshold;
  }

  /// Check if we've hit limits
  bool get hasHitLimits {
    return _dailyReads >= dailyReadLimit ||
        _dailyWrites >= dailyWriteLimit ||
        _dailyDeletes >= dailyDeleteLimit;
  }

  /// Get usage percentages
  Map<String, double> get usagePercentages {
    return {
      'reads': (_dailyReads / dailyReadLimit) * 100,
      'writes': (_dailyWrites / dailyWriteLimit) * 100,
      'deletes': (_dailyDeletes / dailyDeleteLimit) * 100,
    };
  }

  /// Get remaining operations for today
  Map<String, int> get remainingOperations {
    return {
      'reads': (dailyReadLimit - _dailyReads).clamp(0, dailyReadLimit),
      'writes': (dailyWriteLimit - _dailyWrites).clamp(0, dailyWriteLimit),
      'deletes': (dailyDeleteLimit - _dailyDeletes).clamp(0, dailyDeleteLimit),
    };
  }

  /// Add warning callback
  void addWarningCallback(VoidCallback callback) {
    _warningCallbacks.add(callback);
  }

  /// Add limit reached callback
  void addLimitCallback(VoidCallback callback) {
    _limitCallbacks.add(callback);
  }

  /// Remove callbacks
  void removeWarningCallback(VoidCallback callback) {
    _warningCallbacks.remove(callback);
  }

  void removeLimitCallback(VoidCallback callback) {
    _limitCallbacks.remove(callback);
  }

  /// Get optimization suggestions based on current usage
  List<String> getOptimizationSuggestions() {
    final suggestions = <String>[];

    if (_dailyReads > readWarningThreshold) {
      suggestions.addAll([
        'Consider caching frequently accessed data locally',
        'Reduce the number of real-time listeners',
        'Use pagination for large data sets',
        'Implement offline-first data loading',
      ]);
    }

    if (_dailyWrites > writeWarningThreshold) {
      suggestions.addAll([
        'Batch multiple operations together',
        'Reduce the frequency of data updates',
        'Use local storage for temporary data',
        'Implement write queuing for offline scenarios',
      ]);
    }

    if (_dailyDeletes > deleteWarningThreshold) {
      suggestions.addAll([
        'Consider soft deletes instead of hard deletes',
        'Batch delete operations',
        'Implement data archiving instead of deletion',
      ]);
    }

    return suggestions;
  }

  /// Estimate cost if upgraded to Blaze plan
  Map<String, double> estimateBlazeCost() {
    // Blaze plan pricing (above free tier)
    const double readCostPer100k = 0.06;
    const double writeCostPer100k = 0.18;
    const double deleteCostPer100k = 0.18;

    final excessReads =
        (_dailyReads - dailyReadLimit).clamp(0, double.infinity);
    final excessWrites =
        (_dailyWrites - dailyWriteLimit).clamp(0, double.infinity);
    final excessDeletes =
        (_dailyDeletes - dailyDeleteLimit).clamp(0, double.infinity);

    final readCost = (excessReads / 100000) * readCostPer100k;
    final writeCost = (excessWrites / 100000) * writeCostPer100k;
    final deleteCost = (excessDeletes / 100000) * deleteCostPer100k;

    return {
      'reads': readCost,
      'writes': writeCost,
      'deletes': deleteCost,
      'total': readCost + writeCost + deleteCost,
    };
  }

  /// Reset daily counters (called automatically at midnight)
  Future<void> resetDailyCounters() async {
    _dailyReads = 0;
    _dailyWrites = 0;
    _dailyDeletes = 0;
    _currentDate = _getTodayString();
    await _saveTodayUsage();
    debugPrint('FirebaseUsageMonitor: Daily counters reset');
  }

  /// Private methods

  Future<void> _ensureCurrentDate() async {
    final today = _getTodayString();
    if (_currentDate != today) {
      await resetDailyCounters();
    }
  }

  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadTodayUsage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _getTodayString();

      _currentDate = prefs.getString('firebase_usage_date') ?? today;

      if (_currentDate == today) {
        _dailyReads = prefs.getInt('firebase_daily_reads') ?? 0;
        _dailyWrites = prefs.getInt('firebase_daily_writes') ?? 0;
        _dailyDeletes = prefs.getInt('firebase_daily_deletes') ?? 0;
      } else {
        // New day, reset counters
        await resetDailyCounters();
      }
    } catch (e) {
      debugPrint('FirebaseUsageMonitor: Error loading usage data: $e');
      await resetDailyCounters();
    }
  }

  Future<void> _saveTodayUsage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'firebase_usage_date', _currentDate ?? _getTodayString());
      await prefs.setInt('firebase_daily_reads', _dailyReads);
      await prefs.setInt('firebase_daily_writes', _dailyWrites);
      await prefs.setInt('firebase_daily_deletes', _dailyDeletes);
    } catch (e) {
      debugPrint('FirebaseUsageMonitor: Error saving usage data: $e');
    }
  }

  void _checkThresholds() {
    // Check warning thresholds
    if (isApproachingLimits && !hasHitLimits) {
      for (final callback in _warningCallbacks) {
        try {
          callback();
        } catch (e) {
          debugPrint('FirebaseUsageMonitor: Error in warning callback: $e');
        }
      }
    }

    // Check limit thresholds
    if (hasHitLimits) {
      for (final callback in _limitCallbacks) {
        try {
          callback();
        } catch (e) {
          debugPrint('FirebaseUsageMonitor: Error in limit callback: $e');
        }
      }
    }
  }

  /// Get detailed usage report
  Map<String, dynamic> getUsageReport() {
    final percentages = usagePercentages;
    final remaining = remainingOperations;
    final suggestions = getOptimizationSuggestions();
    final costs = estimateBlazeCost();

    return {
      'date': _currentDate,
      'usage': {
        'reads': _dailyReads,
        'writes': _dailyWrites,
        'deletes': _dailyDeletes,
      },
      'limits': {
        'reads': dailyReadLimit,
        'writes': dailyWriteLimit,
        'deletes': dailyDeleteLimit,
      },
      'percentages': percentages,
      'remaining': remaining,
      'status': {
        'approaching_limits': isApproachingLimits,
        'hit_limits': hasHitLimits,
      },
      'suggestions': suggestions,
      'estimated_blaze_cost': costs,
    };
  }

  /// Dispose resources
  void dispose() {
    _warningCallbacks.clear();
    _limitCallbacks.clear();
  }
}
