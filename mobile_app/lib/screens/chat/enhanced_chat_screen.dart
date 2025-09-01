import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Removed OpenRouter service; Gemini-only
import '../../services/gemini_chat_service.dart';
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
  bool _useGemini = true; // Gemini only
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
      _useGemini = true;

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
      // Gemini-only send
      final aiMessage = await _geminiService.sendMessage(
        conversationId: _currentConversationId!,
        content: content,
        userId: userId,
        attachments: _selectedFiles.isNotEmpty ? _selectedFiles : null,
      );

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

  void _onFilesSelected(List<File> files) {
    setState(() {
      _selectedFiles = files;
    });
  }

  Future<void> _testGeminiApi() async {
    if (!_geminiService.hasApiKey) {
      _showError('Gemini API key not configured');
      return;
    }

    setState(() => _isTyping = true);

    try {
      final testMessage = await _geminiService.sendMessage(
        conversationId: 'test_${DateTime.now().millisecondsSinceEpoch}',
        content:
            'Hello! Please respond with a **bold** greeting and tell me about UTHM.',
        userId: 'test_user',
      );

      setState(() {
        _messages.add(testMessage);
        _isTyping = false;
      });

      _scrollToBottom();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Gemini API test successful!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isTyping = false);
      _showError('Gemini API test failed: $e');
    }
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
          // Debug button to test Gemini API
          if (_useGemini)
            IconButton(
              icon: const Icon(Icons.science),
              tooltip: 'Test Gemini API',
              onPressed: _testGeminiApi,
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showDebugInfo,
          ),
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

  void _showDebugInfo() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat Debug Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Service Status:',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                  'Using Service: ${_useGemini ? "Gemini API" : "OpenRouter"}'),
              if (_useGemini) ...[
                Text('Gemini Service Available: ${_geminiService.hasApiKey}'),
                const Text('Current AI Model: gemini-2.5-flash'),
              ],
              Text('Error Message: ${_errorMessage ?? "None"}'),
              const SizedBox(height: 16),
              Text('Environment:',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('Gemini API Key Present: ${AppConfig.hasGeminiApiKey}'),
              if (AppConfig.getGeminiApiKeyPreview() != null)
                Text('API Key Preview: ${AppConfig.getGeminiApiKeyPreview()}'),
              const SizedBox(height: 16),
              Text('Available Models:',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const Text('• gemini-2.5-flash (Current)'),
              const Text('• gemini-1.5-pro'),
              const Text('• gemini-1.5-flash'),
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

  void _showUsageInfo() async {
    // Usage monitoring removed with Firebase removal
    final report = {}; // Placeholder for future usage reporting

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
              if (report['suggestions'].isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Optimization Tips:',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...report['suggestions'].map<Widget>(
                  (suggestion) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $suggestion',
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
