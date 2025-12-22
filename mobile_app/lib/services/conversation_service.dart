import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_models.dart';
import '../config/supabase_config.dart';
import '../config/backend_config.dart';

/// Service for managing chat conversations with backend integration
class ConversationService extends ChangeNotifier {
  static final ConversationService _instance = ConversationService._internal();
  factory ConversationService() => _instance;
  ConversationService._internal();

  static const String baseUrl = BackendConfig.baseUrl; // Use stable backend URL

  // Local caching
  final Map<String, List<ChatConversation>> _conversationCache = {};
  final Map<String, List<ChatMessage>> _messageCache = {};

  /// Get conversations for a user with caching
  Future<List<ChatConversation>> getUserConversations(String userId) async {
    // Check cache first
    if (_conversationCache.containsKey(userId)) {
      final cached = _conversationCache[userId]!;
      if (cached.isNotEmpty) {
        return cached;
      }
    }

    try {
      // Fetch from Supabase with optimization
      final response = await SupabaseConfig.from('chat_conversations')
          .select()
          .eq('userId', userId)
          .eq('isActive', true)
          .order('updatedAt', ascending: false)
          .limit(ChatConfig.maxConversationsPerUser);

      final conversations =
          response.map((json) => ChatConversation.fromJson(json)).toList();

      // Cache the results
      _conversationCache[userId] = conversations;

      return conversations;
    } catch (e) {
      debugPrint('ConversationService: Error getting conversations: $e');

      // Try to get from local cache as fallback
      final localConversations = await _getLocalConversations(userId);
      return localConversations ?? [];
    }
  }

  /// Create a new conversation
  Future<ChatConversation> createConversation({
    required String userId,
    String? title,
  }) async {
    final conversation = ChatConversation(
      id: _generateConversationId(),
      userId: userId,
      title: title ?? 'New Conversation',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      // Save to Supabase
      await SupabaseConfig.from('chat_conversations').insert({
        'id': conversation.id,
        'userId': conversation.userId,
        'title': conversation.title,
        'createdAt': conversation.createdAt.toIso8601String(),
        'updatedAt': conversation.updatedAt.toIso8601String(),
        'isActive': true,
      });

      // Update cache
      if (!_conversationCache.containsKey(userId)) {
        _conversationCache[userId] = [];
      }
      _conversationCache[userId]!.insert(0, conversation);

      // Keep only recent conversations in cache
      if (_conversationCache[userId]!.length >
          ChatConfig.maxConversationsPerUser) {
        _conversationCache[userId] = _conversationCache[userId]!
            .take(ChatConfig.maxConversationsPerUser)
            .toList();
      }

      // Track usage (placeholder for future implementation)
      // await _usageMonitor.recordOperation('write', 1); // Removed usage monitor

      // Cache locally
      await _cacheConversationLocally(conversation);

      notifyListeners();
      return conversation;
    } catch (e) {
      debugPrint('ConversationService: Error creating conversation: $e');
      rethrow;
    }
  }

  /// Get messages for a conversation with pagination
  Future<List<ChatMessage>> getConversationMessages({
    required String conversationId,
    int limit = 50,
    dynamic startAfter, // Changed from DocumentSnapshot to dynamic
  }) async {
    // Check cache first
    if (_messageCache.containsKey(conversationId) && startAfter == null) {
      final cached = _messageCache[conversationId]!;
      if (cached.isNotEmpty) {
        return cached;
      }
    }

    try {
      final response = await SupabaseConfig.from('chat_messages')
          .select()
          .eq('conversationId', conversationId)
          .order('timestamp', ascending: false)
          .limit(limit);

      final messages =
          response.map((json) => ChatMessage.fromJson(json)).toList();

      // Reverse to show oldest first
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Cache the results
      if (startAfter == null) {
        _messageCache[conversationId] = messages;
      } else {
        // Append to existing cache
        if (_messageCache.containsKey(conversationId)) {
          _messageCache[conversationId]!.insertAll(0, messages);
        }
      }

      return messages;
    } catch (e) {
      debugPrint('ConversationService: Error getting messages: $e');

      // Try to get from local cache as fallback
      final localMessages = await _getLocalMessages(conversationId);
      return localMessages ?? [];
    }
  }

  /// Update conversation metadata
  Future<void> updateConversation({
    required String conversationId,
    String? title,
    String? lastMessage,
    DateTime? lastMessageAt,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': DateTime.now(),
      };

      if (title != null) updateData['title'] = title;
      if (lastMessage != null) {
        updateData['lastMessage'] = lastMessage.length > 100
            ? lastMessage.substring(0, 100)
            : lastMessage;
      }
      if (lastMessageAt != null) {
        updateData['lastMessageAt'] = lastMessageAt;
      }

      await SupabaseConfig.from('chat_conversations').update({
        'updatedAt': updateData['updatedAt'].toIso8601String(),
        'title': updateData['title'],
        'lastMessage': updateData['lastMessage'],
        'lastMessageAt': updateData['lastMessageAt']?.toIso8601String(),
      }).eq('id', conversationId);

      // Update cache
      for (final conversations in _conversationCache.values) {
        final index = conversations.indexWhere((c) => c.id == conversationId);
        if (index != -1) {
          final updated = conversations[index].copyWith(
            title: title,
            lastMessage: lastMessage,
            lastMessageAt: lastMessageAt,
            updatedAt: DateTime.now(),
          );
          conversations[index] = updated;
          break;
        }
      }

      // Track usage (placeholder for future implementation)
      // await _usageMonitor.recordOperation('write', 1); // Removed usage monitor

      notifyListeners();
    } catch (e) {
      debugPrint('ConversationService: Error updating conversation: $e');
      rethrow;
    }
  }

  /// Delete a conversation (soft delete)
  Future<void> deleteConversation(String conversationId) async {
    try {
      // Soft delete - mark as inactive
      await SupabaseConfig.from('chat_conversations').update({
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      }).eq('id', conversationId);

      // Remove from cache
      for (final conversations in _conversationCache.values) {
        conversations.removeWhere((c) => c.id == conversationId);
      }
      _messageCache.remove(conversationId);

      // Track usage (placeholder for future implementation)
      // await _usageMonitor.recordOperation('write', 1); // Removed usage monitor

      notifyListeners();
    } catch (e) {
      debugPrint('ConversationService: Error deleting conversation: $e');
      rethrow;
    }
  }

  /// Search conversations by title or content
  Future<List<ChatConversation>> searchConversations({
    required String userId,
    required String query,
  }) async {
    if (query.trim().isEmpty) {
      return getUserConversations(userId);
    }

    try {
      // Search in cached conversations first
      if (_conversationCache.containsKey(userId)) {
        final cached = _conversationCache[userId]!;
        final filtered = cached
            .where((conversation) =>
                conversation.title
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                (conversation.lastMessage
                        ?.toLowerCase()
                        .contains(query.toLowerCase()) ??
                    false))
            .toList();

        if (filtered.isNotEmpty) {
          return filtered;
        }
      }

      // If not found in cache, search in Supabase
      // Note: This is a simple implementation. For better search, consider using Algolia or similar
      final conversations = await getUserConversations(userId);
      return conversations
          .where((conversation) =>
              conversation.title.toLowerCase().contains(query.toLowerCase()) ||
              (conversation.lastMessage
                      ?.toLowerCase()
                      .contains(query.toLowerCase()) ??
                  false))
          .toList();
    } catch (e) {
      debugPrint('ConversationService: Error searching conversations: $e');
      return [];
    }
  }

  /// Cache conversation locally for offline access
  Future<void> _cacheConversationLocally(ChatConversation conversation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'conversation_${conversation.userId}_${conversation.id}';
      await prefs.setString(key, jsonEncode(conversation.toJson()));
    } catch (e) {
      debugPrint('ConversationService: Error caching conversation locally: $e');
    }
  }

  /// Get conversations from local cache
  Future<List<ChatConversation>?> _getLocalConversations(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs
          .getKeys()
          .where((key) => key.startsWith('conversation_$userId'));

      if (keys.isEmpty) return null;

      // For simplicity, return empty list. In a full implementation,
      // you would parse the cached data
      return [];
    } catch (e) {
      debugPrint('ConversationService: Error getting local conversations: $e');
      return null;
    }
  }

  /// Get messages from local cache
  Future<List<ChatMessage>?> _getLocalMessages(String conversationId) async {
    try {
      // For simplicity, return empty list. In a full implementation,
      // you would implement local message caching
      return [];
    } catch (e) {
      debugPrint('ConversationService: Error getting local messages: $e');
      return null;
    }
  }

  /// Generate unique conversation ID
  String _generateConversationId() {
    return 'conv_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Clear all caches
  void clearCaches() {
    _conversationCache.clear();
    _messageCache.clear();
    debugPrint('ConversationService: Caches cleared');
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    return {
      'conversations':
          _conversationCache.values.fold(0, (sum, list) => sum + list.length),
      'messages':
          _messageCache.values.fold(0, (sum, list) => sum + list.length),
      'users_cached': _conversationCache.length,
    };
  }
}
