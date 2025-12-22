import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chat_models.dart';
import '../config/app_config.dart';
import 'chat_history_service.dart';

/// Gemini API chat service with multimodal support and RAG
/// Supports text, images, PDFs, audio, and video
/// Enhanced with FSKTM knowledge base integration
class GeminiChatService extends ChangeNotifier {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String _model = 'gemini-2.5-flash'; // Free tier model

  final ChatHistoryService _historyService;
  bool _isTyping = false;
  
  // RAG Response Cache - untuk soalan lazim
  static final Map<String, _CachedResponse> _responseCache = {};
  static const int _maxCacheSize = 50;
  static const Duration _cacheExpiry = Duration(hours: 24);

  GeminiChatService(this._historyService);

  bool get isTyping => _isTyping;
  bool get hasApiKey {
    return AppConfig.hasGeminiApiKey;
  }

  /// Get API key from secure configuration
  String? get _apiKey {
    return AppConfig.getGeminiApiKey();
  }

  /// Send message with optional file attachments and RAG context
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String content,
    required String userId,
    List<File>? attachments,
    String? ragContext, // NEW: Optional RAG context from FSKTM data
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
      
      // Check cache for similar FSKTM queries
      if (ragContext != null) {
        final cachedResponse = _getCachedResponse(content);
        if (cachedResponse != null) {
          debugPrint('RAG Cache HIT for query: ${content.substring(0, content.length.clamp(0, 50))}...');
          final aiMessage = ChatMessage(
            id: _generateMessageId(),
            conversationId: conversationId,
            userId: 'stap_advisor',
            content: cachedResponse,
            role: MessageRole.assistant,
            timestamp: DateTime.now(),
            tokens: _calculateTokens(cachedResponse),
          );
          await _historyService.saveMessage(aiMessage);
          return aiMessage;
        }
      }

      // Get conversation history for context
      final history =
          await _historyService.getConversationMessages(conversationId);

      // Build request with multimodal support and RAG context
      final requestBody =
          await _buildGeminiRequest(content, history, attachments, ragContext);

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
      
      // Cache response for FSKTM queries
      if (ragContext != null) {
        _cacheResponse(content, aiContent);
      }

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

  /// Send message with STREAMING response - word by word output
  /// Returns a Stream of partial content updates
  Stream<String> sendMessageStreaming({
    required String conversationId,
    required String content,
    required String userId,
    List<File>? attachments,
    String? ragContext,
  }) async* {
    if (!hasApiKey) {
      throw Exception('Gemini API key not configured');
    }

    _isTyping = true;
    notifyListeners();

    try {
      // Create and save user message
      final userMessage = ChatMessage(
        id: _generateMessageId(),
        conversationId: conversationId,
        userId: userId,
        content: content,
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );
      await _historyService.saveMessage(userMessage);

      // Check cache for similar FSKTM queries
      if (ragContext != null) {
        final cachedResponse = _getCachedResponse(content);
        if (cachedResponse != null) {
          debugPrint('RAG Cache HIT (streaming): ${content.substring(0, content.length.clamp(0, 50))}...');
          
          // Simulate streaming for cached response
          final words = cachedResponse.split(' ');
          final buffer = StringBuffer();
          for (final word in words) {
            buffer.write('$word ');
            yield buffer.toString();
            await Future.delayed(const Duration(milliseconds: 20));
          }
          
          // Save to history
          final aiMessage = ChatMessage(
            id: _generateMessageId(),
            conversationId: conversationId,
            userId: 'stap_advisor',
            content: cachedResponse,
            role: MessageRole.assistant,
            timestamp: DateTime.now(),
            tokens: _calculateTokens(cachedResponse),
          );
          await _historyService.saveMessage(aiMessage);
          return;
        }
      }

      // Get conversation history
      final history = await _historyService.getConversationMessages(conversationId);

      // Build request
      final requestBody = await _buildGeminiRequest(content, history, attachments, ragContext);

      // Use streaming endpoint
      final client = http.Client();
      try {
        final request = http.Request(
          'POST',
          Uri.parse('$_baseUrl/models/$_model:streamGenerateContent?alt=sse&key=$_apiKey'),
        );
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(requestBody);

        final streamedResponse = await client.send(request);

        if (streamedResponse.statusCode != 200) {
          final errorBody = await streamedResponse.stream.bytesToString();
          throw Exception('Gemini API error: ${streamedResponse.statusCode} - $errorBody');
        }

        final fullContent = StringBuffer();

        await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
          // Parse SSE data
          final lines = chunk.split('\n');
          for (final line in lines) {
            if (line.startsWith('data: ')) {
              final jsonStr = line.substring(6).trim();
              if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;

              try {
                final data = jsonDecode(jsonStr);
                final text = _extractTextFromStreamChunk(data);
                if (text.isNotEmpty) {
                  fullContent.write(text);
                  yield fullContent.toString();
                }
              } catch (e) {
                debugPrint('Stream parse error: $e');
              }
            }
          }
        }

        final finalContent = fullContent.toString();
        
        // Cache response for FSKTM queries
        if (ragContext != null && finalContent.isNotEmpty) {
          _cacheResponse(content, finalContent);
        }

        // Save final AI message
        final aiMessage = ChatMessage(
          id: _generateMessageId(),
          conversationId: conversationId,
          userId: 'stap_advisor',
          content: finalContent,
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
          tokens: _calculateTokens(finalContent),
        );
        await _historyService.saveMessage(aiMessage);
        
      } finally {
        client.close();
      }
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  /// Extract text from streaming chunk
  String _extractTextFromStreamChunk(Map<String, dynamic> data) {
    try {
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          return parts[0]['text'] ?? '';
        }
      }
    } catch (e) {
      debugPrint('Error extracting stream text: $e');
    }
    return '';
  }

  /// Build Gemini API request with multimodal support and RAG context
  Future<Map<String, dynamic>> _buildGeminiRequest(
    String userMessage,
    List<ChatMessage> history,
    List<File>? attachments,
    String? ragContext,
  ) async {
    final contents = <Map<String, dynamic>>[];

    // FEATURE 3: Enhanced Conversation Memory
    // If history is long, create a summary of older messages
    String? conversationSummary;
    List<ChatMessage> recentHistory;
    
    if (history.length > 10) {
      // Keep last 6 messages as detailed context
      recentHistory = history.sublist(history.length - 6);
      
      // Summarize older messages (messages 0 to n-6)
      final olderMessages = history.sublist(0, history.length - 6);
      conversationSummary = _createConversationSummary(olderMessages);
      debugPrint('RAG Memory: Created summary of ${olderMessages.length} older messages');
    } else {
      recentHistory = history;
    }

    // Add conversation summary as first message if exists
    if (conversationSummary != null && conversationSummary.isNotEmpty) {
      contents.add({
        'role': 'user',
        'parts': [
          {'text': '[RINGKASAN PERBUALAN SEBELUM]\n$conversationSummary\n[TAMAT RINGKASAN]'}
        ],
      });
      contents.add({
        'role': 'model',
        'parts': [
          {'text': 'Terima kasih. Saya faham konteks perbualan kita sebelum ini.'}
        ],
      });
    }

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
            'text': _buildSystemPrompt(ragContext),
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

  /// Build system prompt for STAP UTHM Advisor with optional RAG context
  String _buildSystemPrompt(String? ragContext) {
    final basePrompt = StringBuffer();
    
    basePrompt.writeln('''
You are STAP UTHM Advisor, an AI academic advisor for UTHM Student Talent Profiling app, specifically for FSKTM (Fakulti Sains Komputer dan Teknologi Maklumat).

Your role is to provide guidance on:
- Academic studies, courses, and learning strategies
- Career development and professional skills
- University life and student activities at UTHM
- Technical skills and industry knowledge
- Research opportunities and academic projects
- Internships and job preparation
- FSKTM staff, departments, and faculty information
''');

    // Inject RAG context into system prompt if available
    if (ragContext != null && ragContext.isNotEmpty) {
      // Check if context has relevant staff data
      final hasStaffData = ragContext.contains('STAFF BERKAITAN') || ragContext.contains('SENARAI STAFF');
      final hasMinimalContext = ragContext.length < 500;
      
      basePrompt.writeln('''

=== FSKTM KNOWLEDGE BASE (Use this data to answer FSKTM-related questions) ===
$ragContext
=== END OF KNOWLEDGE BASE ===

IMPORTANT INSTRUCTIONS FOR RAG:
1. PRIORITIZE information from the knowledge base above for FSKTM questions
2. Include staff email addresses when asked about specific lecturers
3. Mention department names in both Malay and English when relevant
''');

      // FEATURE 4: Enhanced Fallback Response Instructions
      if (!hasStaffData && hasMinimalContext) {
        basePrompt.writeln('''
4. FALLBACK: If the specific information requested is NOT in the knowledge base:
   - Say: "Maaf, saya tidak menemui maklumat khusus tentang [topik] dalam pangkalan data."
   - Offer alternative: "Walau bagaimanapun, anda boleh menghubungi pejabat FSKTM di fsktm@uthm.edu.my atau +607 453 3606 untuk maklumat lanjut."
   - Suggest related info if available
''');
      } else {
        basePrompt.writeln('''
4. If specific info not found: "Maaf, saya tidak mempunyai maklumat tersebut dalam pangkalan data saya. Sila hubungi FSKTM di fsktm@uthm.edu.my"
''');
      }
    } else {
      // No RAG context - general fallback
      basePrompt.writeln('''

NOTE: No specific FSKTM data available for this query. 
For FSKTM-specific questions (staff, programs, etc.), suggest user ask more specifically or contact:
- Email: fsktm@uthm.edu.my
- Phone: +607 453 3606
- Website: https://fsktm.uthm.edu.my
''');
    }

    basePrompt.writeln('''

RESPONSE GUIDELINES:
- Stay focused on academic, career, and FSKTM-related topics
- If asked about unrelated topics, politely redirect to academic matters
- Provide specific, actionable advice relevant to UTHM students
- Be encouraging and supportive in your responses
- Keep responses concise but informative (2-3 paragraphs max)
- Respond in the same language as the user's question (Malay or English)

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

If the question is off-topic: "Saya di sini untuk membantu dengan pembangunan akademik dan kerjaya anda. Bolehkah anda bertanya tentang pengajian, kemahiran, atau matlamat kerjaya anda?"
''');

    return basePrompt.toString();
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
  
  // ============== CONVERSATION MEMORY METHODS ==============
  
  /// Create a summary of older conversation messages
  /// This helps maintain context without using too many tokens
  String _createConversationSummary(List<ChatMessage> messages) {
    if (messages.isEmpty) return '';
    
    final summary = StringBuffer();
    summary.writeln('Topik yang telah dibincangkan:');
    
    // Extract key topics from messages
    final topics = <String>{};
    final userQuestions = <String>[];
    
    for (final message in messages) {
      if (message.role == MessageRole.user) {
        // Extract short version of user question
        final shortContent = message.content.length > 100 
            ? '${message.content.substring(0, 100)}...' 
            : message.content;
        userQuestions.add('- $shortContent');
        
        // Detect topics mentioned
        final content = message.content.toLowerCase();
        if (content.contains(RegExp(r'staff|pensyarah|lecturer'))) topics.add('Staff/Pensyarah');
        if (content.contains(RegExp(r'program|course|kursus'))) topics.add('Program Akademik');
        if (content.contains(RegExp(r'research|penyelidikan'))) topics.add('Penyelidikan');
        if (content.contains(RegExp(r'contact|telefon|email'))) topics.add('Maklumat Hubungan');
        if (content.contains(RegExp(r'jabatan|department'))) topics.add('Jabatan');
      }
    }
    
    // Add detected topics
    if (topics.isNotEmpty) {
      summary.writeln('Kategori: ${topics.join(', ')}');
    }
    
    // Add last 3 user questions as reference
    summary.writeln('Soalan terdahulu:');
    for (final question in userQuestions.take(3)) {
      summary.writeln(question);
    }
    
    return summary.toString();
  }
  
  // ============== RAG CACHE METHODS ==============
  
  /// Get cached response for similar queries
  String? _getCachedResponse(String query) {
    final normalizedQuery = _normalizeQuery(query);
    final cached = _responseCache[normalizedQuery];
    
    if (cached != null && !cached.isExpired) {
      return cached.response;
    }
    
    // Remove expired entry
    if (cached != null) {
      _responseCache.remove(normalizedQuery);
    }
    
    return null;
  }
  
  /// Cache response for future similar queries
  void _cacheResponse(String query, String response) {
    // Limit cache size
    if (_responseCache.length >= _maxCacheSize) {
      // Remove oldest entries
      final sortedKeys = _responseCache.keys.toList()
        ..sort((a, b) => _responseCache[a]!.timestamp.compareTo(_responseCache[b]!.timestamp));
      
      for (int i = 0; i < 10; i++) {
        _responseCache.remove(sortedKeys[i]);
      }
    }
    
    final normalizedQuery = _normalizeQuery(query);
    _responseCache[normalizedQuery] = _CachedResponse(
      response: response,
      timestamp: DateTime.now(),
    );
  }
  
  /// Normalize query for cache key
  String _normalizeQuery(String query) {
    return query
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
  
  /// Clear RAG response cache
  static void clearCache() {
    _responseCache.clear();
  }
}

/// Cached response model for RAG
class _CachedResponse {
  final String response;
  final DateTime timestamp;
  
  _CachedResponse({
    required this.response,
    required this.timestamp,
  });
  
  bool get isExpired => 
      DateTime.now().difference(timestamp) > GeminiChatService._cacheExpiry;
}
