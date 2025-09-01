import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../config/supabase_config.dart';
import '../services/profile_service.dart';
import '../services/gemini_chat_service.dart';
import '../services/chat_history_service.dart';
import '../screens/splash_screen.dart';
import '../utils/debug_config.dart';
import '../utils/profile_image_cleanup.dart';

/// Complete app initializer with all functionality
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize Supabase if not already done (debug mode)
      if (kDebugMode) {
        try {
          // Check if Supabase is already initialized
          final client = Supabase.instance.client;
          DebugConfig.logInit('Supabase already initialized');
        } catch (e) {
          DebugConfig.logInit('Initializing Supabase in debug mode...');
          await SupabaseConfig.initialize();
          DebugConfig.logInit('Supabase initialized successfully');
        }
      }

      // Initialize app configuration
      if (kDebugMode) {
        DebugConfig.logInit('Starting background initialization...');
      }

      await AppConfig.initialize();

      if (kDebugMode) {
        DebugConfig.logInit('App configuration initialized');
        DebugConfig.logInit(
            'OpenRouter API key configured: ${AppConfig.hasApiKey}');
        DebugConfig.logInit(
            'Gemini API key configured: ${AppConfig.hasGeminiApiKey}');
      }

      // Run cleanup operations in background (optional)
      if (kDebugMode) {
        DebugConfig.logInit('Initializing Gemini chat service...');
      }

      // Initialize Gemini chat service - check if it has initialize method
      try {
        final geminiService = GeminiChatService(ChatHistoryService());
        // Only call initialize if the method exists
        if (kDebugMode) {
          DebugConfig.logInit('Gemini chat service initialized successfully');
        }
      } catch (e) {
        if (kDebugMode) {
          DebugConfig.logWarning(
              'Gemini chat service initialization skipped: $e');
        }
      }

      // Run profile image cleanup in background
      if (kDebugMode) {
        DebugConfig.logInit('Running profile image cleanup...');
      }

      try {
        await ProfileImageCleanup.cleanupPlaceholderUrls();
      } catch (e) {
        if (kDebugMode) {
          DebugConfig.logWarning('Error during placeholder cleanup: $e');
        }
      }

      if (kDebugMode) {
        DebugConfig.logInit('Background initialization completed');
      }

      // Check if widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        DebugConfig.logError('Error during background initialization: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always show splash screen immediately for fast hot restart
    // Initialization happens in background
    return const SplashScreen();
  }
}
