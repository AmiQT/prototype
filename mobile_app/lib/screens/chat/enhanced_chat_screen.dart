import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/enhanced_chat_service.dart';
import '../../services/gemini_chat_service.dart';
import '../../services/chat_history_service.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_usage_monitor.dart';
import '../../models/chat_models.dart';
import '../../utils/app_theme.dart';
import '../../widgets/chat/chat_message_bubble.dart';
import '../../widgets/chat/typing_indicator.dart';
import '../../widgets/chat/chat_input_field.dart';
import '../../widgets/chat/usage_warning_banner.dart';
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

  late EnhancedChatService _chatService;
  late GeminiChatService _geminiService;
  late ChatHistoryService _historyService;
  late FirebaseUsageMonitor _usageMonitor;

  bool _isLoading = false;
  bool _isTyping = false;
  bool _showUsageWarning = false;
  bool _useGemini = false; // Will be set based on API availability
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
    _chatService = EnhancedChatService();
    _usageMonitor = FirebaseUsageMonitor();

    try {
      setState(() => _isLoading = true);

      debugPrint('EnhancedChatScreen: Starting service initialization...');

      // Initialize usage monitor first (non-blocking)
      debugPrint('EnhancedChatScreen: Initializing usage monitor...');
      try {
        await _usageMonitor.initialize();
        debugPrint(
            'EnhancedChatScreen: Usage monitor initialized successfully');
      } catch (e) {
        debugPrint(
            'EnhancedChatScreen: Usage monitor failed, continuing without it: $e');
      }

      // Initialize chat services
      debugPrint('EnhancedChatScreen: Initializing chat services...');

      // Debug API key detection
      final hasGeminiKey = AppConfig.hasGeminiApiKey;
      final hasOpenRouterKey = AppConfig.hasApiKey;
      debugPrint('EnhancedChatScreen: Gemini API key available: $hasGeminiKey');
      debugPrint(
          'EnhancedChatScreen: OpenRouter API key available: $hasOpenRouterKey');
      debugPrint(
          'EnhancedChatScreen: GeminiService hasApiKey: ${_geminiService.hasApiKey}');

      // Check if Gemini API is available
      if (_geminiService.hasApiKey) {
        debugPrint('EnhancedChatScreen: Using Gemini API service');
        _useGemini = true;
      } else {
        debugPrint('EnhancedChatScreen: Falling back to OpenRouter service');
        _useGemini = false;
        if (!_chatService.isInitialized) {
          await _chatService.initialize();
        }
      }

      debugPrint('EnhancedChatScreen: Chat service initialized successfully');
      debugPrint(
          'EnhancedChatScreen: Using ${_useGemini ? "Gemini" : "OpenRouter"} service');

      // Set up usage monitoring callbacks (if available)
      try {
        _usageMonitor.addWarningCallback(_onUsageWarning);
        _usageMonitor.addLimitCallback(_onUsageLimit);

        // Check current usage
        final usage = await _usageMonitor.getTodayUsage();
        debugPrint(
            'EnhancedChatScreen: Current usage - Reads: ${usage.dailyReads}, Writes: ${usage.dailyWrites}');
        if (usage.isNearLimit) {
          setState(() => _showUsageWarning = true);
        }
      } catch (e) {
        debugPrint('EnhancedChatScreen: Usage monitoring setup failed: $e');
      }

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
        _showApiKeyDialog();
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

    final authService = Provider.of<AuthService>(context, listen: false);
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
      late ChatMessage aiMessage;

      if (_useGemini) {
        // Send message through Gemini service with file attachments
        aiMessage = await _geminiService.sendMessage(
          conversationId: _currentConversationId!,
          content: content,
          userId: userId,
          attachments: _selectedFiles.isNotEmpty ? _selectedFiles : null,
        );
      } else {
        // Send message through OpenRouter service (fallback)
        aiMessage = await _chatService.sendMessage(
          conversationId: _currentConversationId!,
          content: content,
          userId: userId,
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
        _showApiKeyDialog();
      } else if (e.toString().contains('usage limit')) {
        setState(() => _showUsageWarning = true);
        _showError('Daily usage limit reached. Please try again tomorrow.');
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

  void _onUsageWarning() {
    if (mounted) {
      setState(() => _showUsageWarning = true);
    }
  }

  void _onUsageLimit() {
    if (mounted) {
      _showError(
          'Daily Firebase usage limit reached. Chat functionality is temporarily limited.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showApiKeyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('API Key Issue'),
        content: const Text(
          'There\'s an issue with the OpenRouter API key. Please check your configuration:\n\n'
          '1. Ensure your .env file contains OPENROUTER_API_KEY\n'
          '2. Verify the API key is valid\n'
          '3. Check your OpenRouter account status',
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

  String _getApiKeyStatus() {
    return AppConfig.hasApiKey ? "Yes" : "No";
  }

  String? _getApiKeyPreview() {
    return AppConfig.getApiKeyPreview();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('STAP UTHM Advisor'),
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.textPrimaryColor,
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
          if (_showUsageWarning)
            UsageWarningBanner(
              onDismiss: () => setState(() => _showUsageWarning = false),
            ),

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
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Chat Unavailable',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
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
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Start a Conversation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask me anything about your studies, career, or skills!',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
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
              ] else ...[
                Text('Chat Service Initialized: ${_chatService.isInitialized}'),
                Text(
                    'Current AI Model: ${_chatService.isInitialized ? _chatService.currentModel : "Not initialized"}'),
              ],
              Text('Error Message: ${_errorMessage ?? "None"}'),
              const SizedBox(height: 16),
              Text('Environment:',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_useGemini) ...[
                Text('Gemini API Key Present: ${AppConfig.hasGeminiApiKey}'),
                if (AppConfig.getGeminiApiKeyPreview() != null)
                  Text(
                      'API Key Preview: ${AppConfig.getGeminiApiKeyPreview()}'),
              ] else ...[
                Text('OpenRouter API Key Present: ${_getApiKeyStatus()}'),
                if (_getApiKeyPreview() != null)
                  Text('API Key Preview: ${_getApiKeyPreview()}'),
              ],
              const SizedBox(height: 16),
              Text('Available Models:',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_useGemini) ...[
                const Text('• gemini-2.5-flash (Current)'),
                const Text('• gemini-1.5-pro'),
                const Text('• gemini-1.5-flash'),
              ] else ...[
                const Text('• qwen/qwen-2.5-coder-32b-instruct:free (Current)'),
                const Text('• qwen/qwen-2-72b-instruct:free'),
                const Text('• meta-llama/llama-3.1-8b-instruct:free'),
                const Text('• microsoft/phi-3-medium-128k-instruct:free'),
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

  void _showUsageInfo() async {
    final usage = await _usageMonitor.getTodayUsage();
    final report = _usageMonitor.getUsageReport();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Firebase Usage'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Today\'s Usage:',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                  'Reads: ${usage.dailyReads} / 50,000 (${usage.readUsagePercentage.toStringAsFixed(1)}%)'),
              Text(
                  'Writes: ${usage.dailyWrites} / 20,000 (${usage.writeUsagePercentage.toStringAsFixed(1)}%)'),
              Text(
                  'Deletes: ${usage.dailyDeletes} / 20,000 (${usage.deleteUsagePercentage.toStringAsFixed(1)}%)'),
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
    _usageMonitor.removeWarningCallback(_onUsageWarning);
    _usageMonitor.removeLimitCallback(_onUsageLimit);
    super.dispose();
  }
}
