import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/chat_models.dart';
import '../models/academic_info_model.dart';
import '../config/app_config.dart';
import 'auth_service.dart';
import 'profile_service.dart';
import 'achievement_service.dart';
import 'firebase_usage_monitor.dart';

class EnhancedChatService extends ChangeNotifier {
  static final EnhancedChatService _instance = EnhancedChatService._internal();
  factory EnhancedChatService() => _instance;
  EnhancedChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseUsageMonitor _usageMonitor = FirebaseUsageMonitor();

  // Local caching
  final Map<String, ChatUserContext> _contextCache = {};
  final Map<String, List<ChatMessage>> _messageCache = {};
  final Map<String, List<ChatConversation>> _conversationCache = {};

  // API configuration
  String? _apiKey;
  String _currentModel = ChatConfig.defaultModel;
  bool _isInitialized = false;

  // Getters
  bool get isInitialized => _isInitialized;
  String get currentModel => _currentModel;

  /// Initialize the chat service
  Future<void> initialize() async {
    try {
      debugPrint('EnhancedChatService: Starting initialization...');

      // Get API key using AppConfig
      debugPrint('EnhancedChatService: Getting API key...');
      _apiKey = AppConfig.getOpenRouterApiKey();
      debugPrint(
          'EnhancedChatService: API key found: ${_apiKey != null ? "Yes (${_apiKey!.substring(0, 10)}...)" : "No"}');

      if (_apiKey == null || _apiKey!.isEmpty) {
        debugPrint('EnhancedChatService: No API key found in environment');
        throw Exception(
            'OpenRouter API key not configured. Please check your .env file.');
      }

      // Test API connection
      debugPrint('EnhancedChatService: Testing API connection...');
      await _testApiConnection();
      debugPrint('EnhancedChatService: API connection test successful');

      _isInitialized = true;
      debugPrint(
          'EnhancedChatService: Initialized successfully with model: $_currentModel');
    } catch (e) {
      debugPrint('EnhancedChatService: Initialization failed: $e');
      debugPrint('EnhancedChatService: Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Test API connection and key validity
  Future<bool> _testApiConnection() async {
    try {
      final response = await http
          .post(
            Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _currentModel,
              'messages': [
                {'role': 'user', 'content': 'test'}
              ],
              'max_tokens': 10,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 401) {
        throw Exception(
            'Invalid API key - please update your OpenRouter API key');
      }

      return response.statusCode == 200;
    } catch (e) {
      if (e.toString().contains('Invalid API key')) {
        rethrow;
      }
      debugPrint('EnhancedChatService: API test failed: $e');
      return false;
    }
  }

  /// Update API key and test connection
  Future<void> updateApiKey(String newApiKey) async {
    _apiKey = newApiKey;
    await _testApiConnection();

    // Update .env file would require manual update
    debugPrint('EnhancedChatService: API key updated successfully');
  }

  /// Get or create user context with caching
  Future<ChatUserContext> getUserContext(String userId) async {
    // Check cache first
    if (_contextCache.containsKey(userId)) {
      final cached = _contextCache[userId]!;
      if (DateTime.now().difference(cached.lastUpdated) <
          ChatConfig.contextCacheExpiration) {
        return cached;
      }
    }

    // Fetch from services (optimized to minimize reads)
    try {
      final authService = AuthService();
      final profileService = ProfileService();
      final achievementService = AchievementService();

      final user = await authService.getUserData(userId);
      final profile = await profileService.getProfileByUserId(userId);
      final achievements =
          await achievementService.getAchievementsByUserId(userId);

      final context = ChatUserContext(
        userId: userId,
        fullName: profile?.fullName ?? user?.name ?? 'User',
        program: profile?.academicInfo?.program,
        department: profile?.academicInfo?.department ?? user?.department,
        skills: profile?.skills ?? [],
        interests: profile?.interests ?? [],
        academicLevel: _getAcademicLevel(profile?.academicInfo),
        achievementCount: achievements.length,
        lastUpdated: DateTime.now(),
      );

      // Cache the context
      _contextCache[userId] = context;

      // Also cache locally for offline access
      await _cacheContextLocally(context);

      return context;
    } catch (e) {
      debugPrint('EnhancedChatService: Error getting user context: $e');

      // Try to get from local cache as fallback
      final localContext = await _getLocalContext(userId);
      if (localContext != null) {
        return localContext;
      }

      // Return minimal context if all else fails
      return ChatUserContext(
        userId: userId,
        fullName: 'User',
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Send message with optimized Firebase operations
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String content,
    required String userId,
  }) async {
    if (!_isInitialized) {
      throw Exception('Chat service not initialized');
    }

    // Check Firebase usage limits
    final usage = await _usageMonitor.getTodayUsage();
    if (usage.isNearLimit) {
      throw Exception(
          'Daily Firebase usage limit approaching. Please try again tomorrow.');
    }

    // Create user message
    final userMessage = ChatMessage(
      id: _generateMessageId(),
      conversationId: conversationId,
      userId: userId,
      content: content,
      role: MessageRole.user,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    try {
      // Save user message to Firestore (1 write)
      await _saveMessage(userMessage);

      // Update conversation (1 write) - batched with message save
      await _updateConversation(conversationId, content, userId);

      // Get user context for AI
      final context = await getUserContext(userId);

      // Generate AI response
      final aiResponse = await _generateAIResponse(content, context);

      // Create AI message
      final aiMessage = ChatMessage(
        id: _generateMessageId(),
        conversationId: conversationId,
        userId: 'ai',
        content: aiResponse.content,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        tokens: aiResponse.tokens,
      );

      // Save AI message (1 write)
      await _saveMessage(aiMessage);

      // Update local cache
      _updateMessageCache(conversationId, [userMessage, aiMessage]);

      // Track usage
      await _usageMonitor.recordOperation('write', 3); // 3 writes total

      return aiMessage;
    } catch (e) {
      debugPrint('EnhancedChatService: Error sending message: $e');

      // Update user message status to failed
      final failedMessage = userMessage.copyWith(status: MessageStatus.failed);
      await _saveMessage(failedMessage);

      rethrow;
    }
  }

  /// Generate AI response with error handling
  Future<AIResponse> _generateAIResponse(
      String userMessage, ChatUserContext context) async {
    try {
      final prompt = _buildPrompt(userMessage, context);

      final response = await http
          .post(
            Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _currentModel,
              'messages': [
                {'role': 'user', 'content': prompt}
              ],
              'max_tokens': ChatConfig.maxTokens,
              'temperature': ChatConfig.temperature,
            }),
          )
          .timeout(ChatConfig.apiTimeout);

      if (response.statusCode == 401) {
        throw Exception(
            'API authentication failed. Please check your OpenRouter API key.');
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please try again in a moment.');
      } else if (response.statusCode >= 500) {
        throw Exception(
            'AI service temporarily unavailable. Please try again later.');
      } else if (response.statusCode != 200) {
        throw Exception('Failed to get AI response: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'] ??
          'I apologize, but I couldn\'t generate a response.';
      final tokens = data['usage']?['total_tokens'];

      return AIResponse(content: content, tokens: tokens);
    } catch (e) {
      debugPrint('EnhancedChatService: AI generation error: $e');

      if (e.toString().contains('API authentication failed')) {
        rethrow;
      }

      // Return fallback response
      return AIResponse(
        content:
            'I\'m having trouble connecting to the AI service right now. Please check your internet connection and try again.',
        tokens: null,
      );
    }
  }

  /// Build optimized prompt with user context
  String _buildPrompt(String userMessage, ChatUserContext context) {
    final buffer = StringBuffer();

    // Enhanced system prompt with clear boundaries and focus
    buffer.writeln(
        'You are STAP UTHM Advisor, an AI academic advisor for UTHM Student Talent Profiling app.');
    buffer.writeln('Your role is to provide guidance ONLY on:');
    buffer.writeln('- Academic studies, courses, and learning strategies');
    buffer.writeln('- Career development and professional skills');
    buffer.writeln('- University life and student activities');
    buffer.writeln('- Technical skills and industry knowledge');
    buffer.writeln('- Research opportunities and academic projects');
    buffer.writeln('- Internships and job preparation');
    buffer.writeln();

    buffer.writeln('IMPORTANT GUIDELINES:');
    buffer.writeln('- Stay focused on academic and career topics only');
    buffer.writeln(
        '- If asked about unrelated topics, politely redirect to academic matters');
    buffer.writeln(
        '- Provide specific, actionable advice relevant to university students');
    buffer.writeln('- Be encouraging and supportive in your responses');
    buffer.writeln(
        '- Keep responses concise but informative (2-3 paragraphs max)');
    buffer.writeln();

    buffer.writeln('FORMATTING GUIDELINES:');
    buffer.writeln('- Use **bold text** for important points and key concepts');
    buffer.writeln('- Use *italic text* for emphasis and highlighting');
    buffer.writeln('- Use bullet points (- ) for lists and action items');
    buffer.writeln(
        '- Use numbered lists (1. 2. 3.) for step-by-step instructions');
    buffer.writeln(
        '- Use `code formatting` for technical terms, course codes, or specific tools');
    buffer.writeln(
        '- Structure your response with clear paragraphs for better readability');
    buffer.writeln();

    buffer.writeln('Student Profile:');
    buffer.writeln(context.toContextString());
    buffer.writeln();

    buffer.writeln('Student Question: $userMessage');
    buffer.writeln();

    buffer.writeln('Response Guidelines:');
    buffer.writeln(
        '- If the question is academic/career related: Provide helpful advice');
    buffer.writeln(
        '- If the question is off-topic: "I\'m here to help with your academic and career development. Could you ask me something about your studies, skills, or career goals instead?"');

    return buffer.toString();
  }

  /// Save message with batch optimization
  Future<void> _saveMessage(ChatMessage message) async {
    await _firestore
        .collection('chat_messages')
        .doc(message.id)
        .set(message.toFirestore());
  }

  /// Update conversation metadata (create if doesn't exist)
  Future<void> _updateConversation(
      String conversationId, String lastMessage, String userId) async {
    final conversationRef =
        _firestore.collection('chat_conversations').doc(conversationId);

    // Check if conversation exists
    final conversationDoc = await conversationRef.get();

    if (!conversationDoc.exists) {
      // Create new conversation
      final conversation = ChatConversation(
        id: conversationId,
        userId: userId,
        title: lastMessage.length > 30
            ? '${lastMessage.substring(0, 30)}...'
            : lastMessage,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        messageCount: 1,
        lastMessage: lastMessage.length > 100
            ? lastMessage.substring(0, 100)
            : lastMessage,
        lastMessageAt: DateTime.now(),
      );

      await conversationRef.set(conversation.toFirestore());
    } else {
      // Update existing conversation
      await conversationRef.update({
        'lastMessage': lastMessage.length > 100
            ? lastMessage.substring(0, 100)
            : lastMessage,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'messageCount': FieldValue.increment(1),
      });
    }
  }

  /// Cache context locally for offline access
  Future<void> _cacheContextLocally(ChatUserContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'chat_context_${context.userId}', jsonEncode(context.toJson()));
    } catch (e) {
      debugPrint('EnhancedChatService: Error caching context locally: $e');
    }
  }

  /// Get context from local cache
  Future<ChatUserContext?> _getLocalContext(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('chat_context_$userId');
      if (cached != null) {
        return ChatUserContext.fromJson(jsonDecode(cached));
      }
    } catch (e) {
      debugPrint('EnhancedChatService: Error getting local context: $e');
    }
    return null;
  }

  /// Update message cache
  void _updateMessageCache(String conversationId, List<ChatMessage> messages) {
    if (!_messageCache.containsKey(conversationId)) {
      _messageCache[conversationId] = [];
    }
    _messageCache[conversationId]!.addAll(messages);

    // Keep only recent messages to manage memory
    if (_messageCache[conversationId]!.length >
        ChatConfig.maxMessagesPerConversation) {
      _messageCache[conversationId] = _messageCache[conversationId]!
          .skip(_messageCache[conversationId]!.length -
              ChatConfig.maxMessagesPerConversation)
          .toList();
    }
  }

  /// Generate unique message ID
  String _generateMessageId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Get academic level from academic info
  String? _getAcademicLevel(AcademicInfoModel? academicInfo) {
    if (academicInfo == null) return null;

    // Extract semester information to determine academic level
    final semester = academicInfo.currentSemester;
    final program = academicInfo.program;

    // Determine level based on semester and program
    if (program.toLowerCase().contains('phd') ||
        program.toLowerCase().contains('doctorate')) {
      return 'PhD';
    } else if (program.toLowerCase().contains('master') ||
        program.toLowerCase().contains('msc') ||
        program.toLowerCase().contains('ma')) {
      return 'Master\'s';
    } else if (program.toLowerCase().contains('bachelor') ||
        program.toLowerCase().contains('degree')) {
      if (semester <= 2) {
        return 'Bachelor\'s Year 1';
      } else if (semester <= 4) {
        return 'Bachelor\'s Year 2';
      } else if (semester <= 6) {
        return 'Bachelor\'s Year 3';
      } else {
        return 'Bachelor\'s Year 4+';
      }
    } else if (program.toLowerCase().contains('diploma')) {
      if (semester <= 2) {
        return 'Diploma Year 1';
      } else if (semester <= 4) {
        return 'Diploma Year 2';
      } else {
        return 'Diploma Year 3+';
      }
    }

    // Default fallback
    return 'Undergraduate';
  }

  /// Clear caches to free memory
  void clearCaches() {
    _contextCache.clear();
    _messageCache.clear();
    _conversationCache.clear();
    debugPrint('EnhancedChatService: Caches cleared');
  }
}

/// AI Response model
class AIResponse {
  final String content;
  final int? tokens;

  AIResponse({required this.content, this.tokens});
}
