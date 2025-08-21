import 'package:flutter/material.dart';
import '../../services/enhanced_chat_service.dart';
import '../../utils/app_theme.dart';

class ChatSettingsScreen extends StatefulWidget {
  const ChatSettingsScreen({super.key});

  @override
  State<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final EnhancedChatService _chatService = EnhancedChatService();
  
  bool _isLoading = false;
  bool _apiKeyValid = false;
  Map<String, dynamic>? _usageReport;

  @override
  void initState() {
    super.initState();
    _loadUsageReport();
  }

  Future<void> _loadUsageReport() async {
    try {
      final report = <String, dynamic>{}; // Placeholder for future usage reporting
      setState(() {
        _usageReport = report;
        _apiKeyValid = _chatService.isInitialized;
      });
    } catch (e) {
      debugPrint('ChatSettingsScreen: Error loading usage report: $e');
    }
  }

  Future<void> _testApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      _showError('Please enter an API key');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _chatService.updateApiKey(apiKey);
      setState(() => _apiKeyValid = true);
      _showSuccess('API key validated successfully!');
    } catch (e) {
      setState(() => _apiKeyValid = false);
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Chat Settings'),
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // API Configuration Section
            _buildSectionHeader('API Configuration'),
            _buildApiConfigCard(),
            
            const SizedBox(height: 24),
            
            // Usage Monitoring Section
            _buildSectionHeader('Firebase Usage'),
            _buildUsageCard(),
            
            const SizedBox(height: 24),
            
            // Optimization Tips Section
            if (_usageReport?['suggestions']?.isNotEmpty ?? false) ...[
              _buildSectionHeader('Optimization Tips'),
              _buildOptimizationCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimaryColor,
        ),
      ),
    );
  }

  Widget _buildApiConfigCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _apiKeyValid ? Icons.check_circle : Icons.error_outline,
                  color: _apiKeyValid ? AppTheme.successColor : AppTheme.errorColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _apiKeyValid ? 'API Key Valid' : 'API Key Required',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _apiKeyValid ? AppTheme.successColor : AppTheme.errorColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'OpenRouter API Key',
                hintText: 'sk-or-v1-...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () {
                    // Toggle visibility
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testApiKey,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Test API Key'),
              ),
            ),
            
            const SizedBox(height: 12),
            
            const Text(
              'Get your API key from OpenRouter.ai. This key is used to access AI models for chat responses.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageCard() {
    if (_usageReport == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final usage = _usageReport!['usage'] as Map<String, dynamic>;
    final limits = _usageReport!['limits'] as Map<String, dynamic>;
    final percentages = _usageReport!['percentages'] as Map<String, dynamic>;
    final status = _usageReport!['status'] as Map<String, dynamic>;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Usage',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            
            const SizedBox(height: 16),
            
            _buildUsageItem('Reads', usage['reads'], limits['reads'], percentages['reads']),
            const SizedBox(height: 8),
            _buildUsageItem('Writes', usage['writes'], limits['writes'], percentages['writes']),
            const SizedBox(height: 8),
            _buildUsageItem('Deletes', usage['deletes'], limits['deletes'], percentages['deletes']),
            
            const SizedBox(height: 16),
            
            if (status['approaching_limits'] == true)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Approaching daily limits. Consider optimizing usage.',
                        style: TextStyle(color: Colors.orange[700]),
                      ),
                    ),
                  ],
                ),
              ),
            
            if (status['hit_limits'] == true)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error, color: AppTheme.errorColor),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Daily limits reached. Functionality may be limited.',
                        style: TextStyle(color: AppTheme.errorColor),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageItem(String label, int used, int limit, double percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('$used / $limit'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: AppTheme.grayColor.withValues(alpha: 0.3),
          valueColor: AlwaysStoppedAnimation<Color>(
            percentage > 80 ? AppTheme.errorColor : AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildOptimizationCard() {
    final suggestions = _usageReport!['suggestions'] as List<dynamic>;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recommendations',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            ...suggestions.map<Widget>((suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      suggestion.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }
}
