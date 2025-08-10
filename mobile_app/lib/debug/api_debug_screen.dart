import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/gemini_chat_service.dart';
import '../services/chat_history_service.dart';

class ApiDebugScreen extends StatefulWidget {
  const ApiDebugScreen({super.key});

  @override
  State<ApiDebugScreen> createState() => _ApiDebugScreenState();
}

class _ApiDebugScreenState extends State<ApiDebugScreen> {
  late GeminiChatService _geminiService;
  late ChatHistoryService _historyService;
  String _debugInfo = 'Loading...';

  @override
  void initState() {
    super.initState();
    _initializeAndTest();
  }

  Future<void> _initializeAndTest() async {
    try {
      _historyService = ChatHistoryService();
      await _historyService.initialize();
      _geminiService = GeminiChatService(_historyService);

      final hasGeminiKey = AppConfig.hasGeminiApiKey;
      final geminiKey = AppConfig.getGeminiApiKey();
      final hasOpenRouterKey = AppConfig.hasApiKey;
      final openRouterKey = AppConfig.getOpenRouterApiKey();

      setState(() {
        _debugInfo = '''
=== API KEY DEBUG INFO ===

Gemini API:
- Key Available: $hasGeminiKey
- Key Preview: ${geminiKey?.substring(0, 20)}...
- Service hasApiKey: ${_geminiService.hasApiKey}

OpenRouter API:
- Key Available: $hasOpenRouterKey  
- Key Preview: ${openRouterKey?.substring(0, 20)}...

Current Selection:
- Will use: ${hasGeminiKey ? 'Gemini' : 'OpenRouter'}

========================
        ''';
      });
    } catch (e) {
      setState(() {
        _debugInfo = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Debug'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'API Configuration Debug',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    _debugInfo,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _initializeAndTest,
                child: const Text('Refresh Debug Info'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
