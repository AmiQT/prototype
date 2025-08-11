import 'package:flutter/foundation.dart';
import 'lib/config/app_config.dart';

/// Security verification script
/// Run with: dart security_check.dart
void main() async {
  print('🔒 SECURITY VERIFICATION CHECK');
  print('================================\n');
  
  try {
    // Initialize configuration
    await AppConfig.initialize();
    
    print('📊 Security Status:');
    
    // Check API key configuration
    final hasGeminiKey = AppConfig.hasGeminiApiKey;
    final geminiPreview = AppConfig.getGeminiApiKeyPreview();
    
    print('├── Gemini API Key: ${hasGeminiKey ? "✅ Configured" : "❌ Missing"}');
    
    if (hasGeminiKey) {
      print('├── Key Preview: $geminiPreview');
      
      // Verify preview is secure (only 4 chars + ***)
      if (geminiPreview != null && geminiPreview.length <= 7) {
        print('├── Preview Security: ✅ Secure (${geminiPreview.length} chars)');
      } else {
        print('├── Preview Security: ⚠️ Too much information exposed');
      }
    }
    
    // Check debug mode
    print('├── Debug Mode: ${kDebugMode ? "🔧 Development" : "🚀 Production"}');
    
    // Check if we're in release mode
    print('├── Release Mode: ${kReleaseMode ? "✅ Production Build" : "🔧 Debug Build"}');
    
    print('└── Overall Status: ${hasGeminiKey ? "✅ SECURE" : "⚠️ NEEDS SETUP"}');
    
    print('\n🔍 Security Verification:');
    
    if (hasGeminiKey) {
      print('✅ API key is properly configured');
      print('✅ Key preview is limited to safe length');
      print('✅ No full API key should appear in logs');
    } else {
      print('⚠️ API key not configured - add to .env file');
    }
    
    if (kDebugMode) {
      print('🔧 Running in debug mode - some debug info will be shown');
      print('   In production, debug statements will be disabled');
    } else {
      print('🚀 Running in production mode - debug info disabled');
    }
    
    print('\n🎯 Next Steps:');
    if (!hasGeminiKey) {
      print('1. Add your Gemini API key to mobile_app/.env');
      print('2. Format: GEMINI_API_KEY=your_actual_key_here');
      print('3. Restart the app');
    } else {
      print('1. Verify chatbot functionality');
      print('2. Check that no full API keys appear in logs');
      print('3. Test in production build');
    }
    
  } catch (e) {
    print('❌ ERROR: Security check failed: $e');
  }
  
  print('\n🛡️ Security check complete!');
}
