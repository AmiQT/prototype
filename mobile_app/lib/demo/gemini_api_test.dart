import 'package:flutter/material.dart';
import '../services/gemini_chat_service.dart';
import '../services/chat_history_service.dart';
import '../config/app_config.dart';
import '../utils/app_theme.dart';

/// Test screen to verify Gemini API integration
class GeminiApiTest extends StatefulWidget {
  const GeminiApiTest({super.key});

  @override
  State<GeminiApiTest> createState() => _GeminiApiTestState();
}

class _GeminiApiTestState extends State<GeminiApiTest> {
  late GeminiChatService _geminiService;
  late ChatHistoryService _historyService;

  String _status = 'Initializing...';
  String? _response;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      _historyService = ChatHistoryService();
      await _historyService.initialize();

      _geminiService = GeminiChatService(_historyService);

      // Debug API key detection
      final hasGeminiKey = AppConfig.hasGeminiApiKey;
      final geminiKey = AppConfig.getGeminiApiKey();
      final hasOpenRouterKey = AppConfig.hasApiKey;

      debugPrint('=== API KEY DEBUG ===');
      debugPrint('Gemini API Key Available: $hasGeminiKey');
      debugPrint('Gemini API Key: ${geminiKey?.substring(0, 10)}...');
      debugPrint('OpenRouter API Key Available: $hasOpenRouterKey');
      debugPrint('Service hasApiKey: ${_geminiService.hasApiKey}');
      debugPrint('====================');

      setState(() {
        _status = _geminiService.hasApiKey
            ? 'Ready - Using Gemini API: ${AppConfig.getGeminiApiKeyPreview()}'
            : 'Error - No Gemini API Key Found (falling back to OpenRouter)';
      });
    } catch (e) {
      setState(() {
        _status = 'Error initializing services: $e';
      });
    }
  }

  Future<void> _testGeminiApi() async {
    if (!_geminiService.hasApiKey) {
      setState(() {
        _status = 'Error: No API key configured';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Testing Gemini API...';
      _response = null;
    });

    try {
      final testMessage = await _geminiService.sendMessage(
        conversationId:
            'test_conversation_${DateTime.now().millisecondsSinceEpoch}',
        content:
            'Hello! Please respond with a **bold** greeting and tell me about UTHM in *italics*.',
        userId: 'test_user',
      );

      setState(() {
        _status = 'Success! ✅';
        _response = testMessage.content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini API Test'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'API Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    const SizedBox(height: 16),

                    // Test Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testGeminiApi,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Testing...'),
                                ],
                              )
                            : const Text('Test Gemini API'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Response Card
            if (_response != null)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'API Response',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(
                                _response!,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Info Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Gemini API Features',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('✅ Rich text formatting (bold, italics, lists)'),
                    const Text('✅ Image upload and analysis'),
                    const Text('✅ PDF document processing'),
                    const Text('✅ Audio and video support'),
                    const Text('✅ 1M token context window'),
                    const Text('✅ Completely FREE for <50 users'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
