import 'package:flutter/foundation.dart';
import 'lib/config/app_config.dart';

/// Simple test script to verify API key configuration
/// Run with: dart test_api_config.dart
void main() async {
  print('🔧 Testing API Key Configuration...\n');
  
  try {
    // Initialize configuration
    await AppConfig.initialize();
    
    // Test Gemini API key
    final hasGeminiKey = AppConfig.hasGeminiApiKey;
    final geminiPreview = AppConfig.getGeminiApiKeyPreview();
    
    print('📊 Configuration Results:');
    print('├── Gemini API Key: ${hasGeminiKey ? "✅ Found" : "❌ Not Found"}');
    if (hasGeminiKey) {
      print('├── Key Preview: $geminiPreview');
    }
    
    // Test OpenRouter API key
    final hasOpenRouterKey = AppConfig.hasApiKey;
    final openRouterPreview = AppConfig.getApiKeyPreview();
    
    print('├── OpenRouter API Key: ${hasOpenRouterKey ? "✅ Found" : "❌ Not Found"}');
    if (hasOpenRouterKey) {
      print('├── Key Preview: $openRouterPreview');
    }
    
    print('└── Primary Service: ${hasGeminiKey ? "Gemini" : (hasOpenRouterKey ? "OpenRouter" : "None")}');
    
    // Final status
    if (hasGeminiKey || hasOpenRouterKey) {
      print('\n🎉 SUCCESS: API configuration is working!');
      print('💡 Your chatbot should now function properly.');
    } else {
      print('\n⚠️  WARNING: No API keys found!');
      print('📝 Please add your Gemini API key to:');
      print('   - mobile_app/.env (recommended)');
      print('   - mobile_app/assets/.env (alternative)');
      print('   Format: GEMINI_API_KEY=your_actual_api_key_here');
    }
    
  } catch (e) {
    print('❌ ERROR: Failed to test configuration: $e');
  }
}
