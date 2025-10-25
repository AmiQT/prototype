import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Removed OpenRouter service; Gemini-only
import '../../services/gemini_chat_service.dart';
import '../../services/fsktm_data_service.dart';
import '../../services/chat_history_service.dart';
import '../../services/supabase_auth_service.dart';
import '../../models/chat_models.dart';
import '../../widgets/chat/chat_message_bubble.dart';
import '../../widgets/chat/typing_indicator.dart';
import '../../widgets/chat/chat_input_field.dart';
import '../../config/app_config.dart';

class EnhancedChatScreen extends StatefulWidget {
  final String? conversationId;

  const EnhancedChatScreen({
    super.key,
    this.conversationId,
  });

  @override
  State<EnhancedChatScreen> createState() => _EnhancedChatScreenState();
}

class _EnhancedChatScreenState extends State<EnhancedChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  late GeminiChatService _geminiService;
  late ChatHistoryService _historyService;

  bool _isLoading = false;
  bool _isTyping = false;
  String? _currentConversationId;
  String? _errorMessage;
  List<File> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _historyService = ChatHistoryService();
    await _historyService.initialize();
    _geminiService = GeminiChatService(_historyService);

    try {
      setState(() => _isLoading = true);

      debugPrint('EnhancedChatScreen: Starting service initialization...');

      // Initialize chat services
      debugPrint('EnhancedChatScreen: Initializing chat services...');

      // Gemini only: verify key presence
      final hasGeminiKey = AppConfig.hasGeminiApiKey;
      debugPrint('EnhancedChatScreen: Gemini API key available: $hasGeminiKey');

      debugPrint('EnhancedChatScreen: Chat service initialized (Gemini only)');
      debugPrint('EnhancedChatScreen: Using Gemini service');

      // Load conversation if provided
      if (widget.conversationId != null) {
        _currentConversationId = widget.conversationId;
        await _loadConversationMessages();
      } else {
        _currentConversationId = _generateConversationId();
      }

      setState(() => _isLoading = false);
      debugPrint('EnhancedChatScreen: All services initialized successfully');
    } catch (e) {
      debugPrint('EnhancedChatScreen: Initialization error: $e');
      debugPrint('EnhancedChatScreen: Error type: ${e.runtimeType}');

      setState(() {
        _isLoading = false;
        _errorMessage = 'Initialization failed: ${e.toString()}';
      });

      if (e.toString().contains('API key')) {
        _showGeminiKeyDialog();
      }
    }
  }

  Future<void> _loadConversationMessages() async {
    // Implementation for loading existing messages would go here
    // For now, we'll start with an empty conversation
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isTyping) return;

    final authService =
        Provider.of<SupabaseAuthService>(context, listen: false);
    final userId = authService.currentUserId;

    if (userId == null) {
      _showError('Please log in to send messages');
      return;
    }

    // Clear input and show typing
    _messageController.clear();
    setState(() => _isTyping = true);

    // Add user message to UI immediately
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: _currentConversationId!,
      userId: userId,
      content: content,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
    });

    _scrollToBottom();

    try {
      ChatMessage aiMessage;

      // Intelligent routing: FSKTM vs General AI
      if (_isFSKTMQuestion(content)) {
        // Route to FSKTM local data + Gemini AI

        // Get FSKTM context from local data
        final fsktmContext = await FSKTMDataService.getFSKTMContextForAI();

        // Create enhanced prompt with FSKTM context
        final enhancedPrompt = '''
You are an AI assistant for FSKTM (Fakulti Sains Komputer dan Teknologi Maklumat) UTHM. 
Use the following information to answer questions about FSKTM staff, departments, and faculty.

$fsktmContext

User Question: $content

Please provide a helpful response based on the FSKTM information provided above. If asked about specific staff members, include their contact details. Answer in a friendly and professional manner.
''';

        // Send enhanced prompt to Gemini
        aiMessage = await _geminiService.sendMessage(
          conversationId: _currentConversationId!,
          content: enhancedPrompt,
          userId: userId,
          attachments: _selectedFiles.isNotEmpty ? _selectedFiles : null,
        );
      } else {
        // Route to General AI (Gemini)

        aiMessage = await _geminiService.sendMessage(
          conversationId: _currentConversationId!,
          content: content,
          userId: userId,
          attachments: _selectedFiles.isNotEmpty ? _selectedFiles : null,
        );
      }

      setState(() {
        _messages.add(aiMessage);
        _isTyping = false;
        _selectedFiles.clear(); // Clear files after sending
      });

      _scrollToBottom();
    } catch (e) {
      setState(() => _isTyping = false);

      if (e.toString().contains('API authentication failed') ||
          e.toString().contains('API key')) {
        _showGeminiKeyDialog();
      } else {
        _showError(e.toString());
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Check if question is about FSKTM using local data service
  bool _isFSKTMQuestion(String message) {
    return FSKTMDataService.isFSKTMQuery(message);
  }

  void _onFilesSelected(List<File> files) {
    setState(() {
      _selectedFiles = files;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showGeminiKeyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Gemini API Key Required'),
        content: const Text(
          'There\'s an issue with the Gemini API key. Please check your configuration:\n\n'
          '1. Ensure your assets/.env file contains GEMINI_API_KEY=your-key\n'
          '   (or run with --dart-define=GEMINI_API_KEY=your-key)\n'
          '2. Verify the key is valid in Google AI Studio\n'
          '3. Restart the app after adding the key',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Exit chat screen
            },
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Retry initialization
              await _initializeServices();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _generateConversationId() {
    return 'conv_${DateTime.now().millisecondsSinceEpoch}';
  }

  // OpenRouter API helpers removed (Gemini-only)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('STAP UTHM Advisor'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showUsageInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          // Usage warning banner
          // Removed UsageWarningBanner

          // Messages area
          Expanded(
            child: _buildMessagesArea(),
          ),

          // Typing indicator
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: TypingIndicator(),
            ),

          // Input area
          ChatInputField(
            controller: _messageController,
            onSend: _sendMessage,
            enabled: !_isTyping && _errorMessage == null,
            onFilesSelected: _onFilesSelected,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesArea() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Chat Unavailable',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeServices,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Start a Conversation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask me anything about your studies, career, or skills!',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return ChatMessageBubble(
          message: _messages[index],
          isUser: _messages[index].role == MessageRole.user,
        );
      },
    );
  }

  void _showUsageInfo() async {
    // Usage monitoring removed with Firebase removal
    final Map<String, dynamic> report = {}; // Placeholder for future usage reporting
    final suggestions = List<String>.from(report['suggestions'] ?? const []);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Usage'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Today\'s Usage:',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const Text('Reads: 0 / 50,000 (0%)'),
              const Text('Writes: 0 / 20,000 (0%)'),
              const Text('Deletes: 0 / 20,000 (0%)'),
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Optimization Tips:',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...suggestions.map<Widget>(
                  (suggestion) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('- $suggestion',
                        style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
