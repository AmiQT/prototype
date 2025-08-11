import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chat_models.dart';
import '../config/app_config.dart';
import 'chat_history_service.dart';

/// Gemini API chat service with multimodal support
/// Supports text, images, PDFs, audio, and video
class GeminiChatService extends ChangeNotifier {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String _model = 'gemini-2.5-flash'; // Free tier model

  final ChatHistoryService _historyService;
  bool _isTyping = false;

  GeminiChatService(this._historyService);

  bool get isTyping => _isTyping;
  bool get hasApiKey {
    final hasKey = AppConfig.hasGeminiApiKey;
    if (kDebugMode) {
      debugPrint('GeminiChatService: hasApiKey = $hasKey');
    }
    return hasKey;
  }

  /// Get API key from secure configuration
  String? get _apiKey {
    final key = AppConfig.getGeminiApiKey();
    if (kDebugMode) {
      debugPrint('GeminiChatService: API key available = ${key != null}');
    }
    return key;
  }

  /// Send message with optional file attachments
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String content,
    required String userId,
    List<File>? attachments,
  }) async {
    if (!hasApiKey) {
      throw Exception('Gemini API key not configured');
    }

    _isTyping = true;
    notifyListeners();

    try {
      // Create user message
      final userMessage = ChatMessage(
        id: _generateMessageId(),
        conversationId: conversationId,
        userId: userId,
        content: content,
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );

      // Save user message to local history
      await _historyService.saveMessage(userMessage);

      // Get conversation history for context
      final history =
          await _historyService.getConversationMessages(conversationId);

      // Build request with multimodal support
      final requestBody =
          await _buildGeminiRequest(content, history, attachments);

      // Send to Gemini API
      final response = await http.post(
        Uri.parse('$_baseUrl/models/$_model:generateContent?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Gemini API error: ${response.statusCode} - ${response.body}');
      }

      final responseData = jsonDecode(response.body);
      final aiContent = _extractContentFromResponse(responseData);

      // Create AI message
      final aiMessage = ChatMessage(
        id: _generateMessageId(),
        conversationId: conversationId,
        userId: 'stap_advisor',
        content: aiContent,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        tokens: _calculateTokens(aiContent),
      );

      // Save AI message to local history
      await _historyService.saveMessage(aiMessage);

      return aiMessage;
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  /// Build Gemini API request with multimodal support
  Future<Map<String, dynamic>> _buildGeminiRequest(
    String userMessage,
    List<ChatMessage> history,
    List<File>? attachments,
  ) async {
    final contents = <Map<String, dynamic>>[];

    // Add conversation history (last 10 messages for context)
    final recentHistory =
        history.length > 10 ? history.sublist(history.length - 10) : history;

    for (final message in recentHistory) {
      contents.add({
        'role': message.role == MessageRole.user ? 'user' : 'model',
        'parts': [
          {'text': message.content}
        ],
      });
    }

    // Build current user message parts
    final currentParts = <Map<String, dynamic>>[];

    // Add text content
    currentParts.add({'text': userMessage});

    // Add file attachments if any
    if (attachments != null && attachments.isNotEmpty) {
      for (final file in attachments) {
        final fileData = await _processFileAttachment(file);
        if (fileData != null) {
          currentParts.add(fileData);
        }
      }
    }

    // Add current user message
    contents.add({
      'role': 'user',
      'parts': currentParts,
    });

    return {
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 2048,
      },
      'systemInstruction': {
        'parts': [
          {
            'text': _buildSystemPrompt(),
          }
        ],
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
      ],
    };
  }

  /// Process file attachment for multimodal input
  Future<Map<String, dynamic>?> _processFileAttachment(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final base64Data = base64Encode(bytes);
      final fileName = file.path.split('/').last.toLowerCase();

      // Determine MIME type based on file extension
      String mimeType;
      if (fileName.endsWith('.pdf')) {
        mimeType = 'application/pdf';
      } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      } else if (fileName.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (fileName.endsWith('.gif')) {
        mimeType = 'image/gif';
      } else if (fileName.endsWith('.webp')) {
        mimeType = 'image/webp';
      } else if (fileName.endsWith('.mp3')) {
        mimeType = 'audio/mp3';
      } else if (fileName.endsWith('.wav')) {
        mimeType = 'audio/wav';
      } else if (fileName.endsWith('.mp4')) {
        mimeType = 'video/mp4';
      } else {
        debugPrint('Unsupported file type: $fileName');
        return null;
      }

      return {
        'inlineData': {
          'mimeType': mimeType,
          'data': base64Data,
        }
      };
    } catch (e) {
      debugPrint('Error processing file attachment: $e');
      return null;
    }
  }

  /// Build system prompt for STAP UTHM Advisor
  String _buildSystemPrompt() {
    return '''
You are STAP UTHM Advisor, an AI academic advisor for UTHM Student Talent Profiling app.

Your role is to provide guidance ONLY on:
- Academic studies, courses, and learning strategies
- Career development and professional skills
- University life and student activities
- Technical skills and industry knowledge
- Research opportunities and academic projects
- Internships and job preparation

IMPORTANT GUIDELINES:
- Stay focused on academic and career topics only
- If asked about unrelated topics, politely redirect to academic matters
- Provide specific, actionable advice relevant to university students
- Be encouraging and supportive in your responses
- Keep responses concise but informative (2-3 paragraphs max)

FORMATTING GUIDELINES:
- Use **bold text** for important points and key concepts
- Use *italic text* for emphasis and highlighting
- Use bullet points (- ) for lists and action items
- Use numbered lists (1. 2. 3.) for step-by-step instructions
- Use `code formatting` for technical terms, course codes, or specific tools
- Structure your response with clear paragraphs for better readability

MULTIMODAL CAPABILITIES:
- When users upload images: Analyze and provide relevant academic/career advice
- When users upload PDFs: Read and discuss the content in academic context
- When users upload audio/video: Process and respond to academic questions
- Always relate multimodal content back to academic and career development

If the question is off-topic: "I'm here to help with your academic and career development. Could you ask me something about your studies, skills, or career goals instead?"
''';
  }

  /// Extract content from Gemini API response
  String _extractContentFromResponse(Map<String, dynamic> response) {
    try {
      final candidates = response['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          return parts[0]['text'] ?? 'Sorry, I couldn\'t generate a response.';
        }
      }
      return 'Sorry, I couldn\'t generate a response.';
    } catch (e) {
      debugPrint('Error extracting response: $e');
      return 'Sorry, there was an error processing the response.';
    }
  }

  /// Calculate approximate token count
  int _calculateTokens(String text) {
    // Rough estimation: 1 token ≈ 4 characters
    return (text.length / 4).round();
  }

  /// Generate unique message ID
  String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}';
  }
}
