import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'services/supabase_auth_service.dart';
import 'config/supabase_config.dart';
import 'services/profile_service.dart';
import 'services/achievement_service.dart';
import 'services/showcase_service.dart';
import 'services/search_service.dart';
import 'services/notification_service.dart';
import 'services/language_service.dart';
// Removed OpenRouter chat service import to use Gemini only
import 'services/gemini_chat_service.dart';
import 'services/chat_history_service.dart';
import 'config/app_config.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';
// Firebase completely removed - using Supabase only

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize app configuration
  if (kDebugMode) {
    debugPrint('Main: Initializing app configuration...');
  }
  await AppConfig.initialize();
  if (kDebugMode) {
    debugPrint('Main: App configuration initialized');
    debugPrint('Main: OpenRouter API key configured: ${AppConfig.hasApiKey}');
    debugPrint('Main: Gemini API key configured: ${AppConfig.hasGeminiApiKey}');
  }
  // Initialize Supabase
  try {
    await SupabaseConfig.initialize();
    if (kDebugMode) {
      debugPrint('Main: Supabase initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Main: Failed to initialize Supabase: $e');
    }
  }

  // Initialize services
  final authService = SupabaseAuthService();
  await authService.initialize();

  final languageService = LanguageService();
  await languageService.initialize();

  // Initialize chat services with Gemini
  if (AppConfig.hasGeminiApiKey) {
    debugPrint('Main: Using Gemini chat service');
    final historyService = ChatHistoryService();
    await historyService.initialize();
    // Instantiate service to ensure eager init
    GeminiChatService(historyService);
    debugPrint('Main: Gemini chat service initialized successfully');
  } else {
    debugPrint(
        'Main: No Gemini API key found. Chat will be unavailable until GEMINI_API_KEY is provided.');
  }

  debugPrint('Main: Chat services check completed');

  runApp(MyApp(
    authService: authService,
    languageService: languageService,
  ));
}

class MyApp extends StatelessWidget {
  final SupabaseAuthService authService;
  final LanguageService languageService;

  const MyApp({
    super.key,
    required this.authService,
    required this.languageService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SupabaseAuthService>(
          create: (_) => authService,
        ),
        Provider<ProfileService>(
          create: (_) => ProfileService(),
        ),
        Provider<AchievementService>(
          create: (_) => AchievementService(),
        ),
        Provider<ShowcaseService>(
          create: (_) => ShowcaseService(),
        ),
        Provider<SearchService>(
          create: (_) => SearchService(),
        ),
        Provider<NotificationService>(
          create: (_) => NotificationService(),
        ),
        ChangeNotifierProvider<LanguageService>(
          create: (_) => languageService,
        ),
      ],
      child: Consumer<LanguageService>(
        builder: (context, languageService, child) {
          return MaterialApp(
            title: 'Student Talent Profiling App',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            debugShowCheckedModeBanner: false,
            locale: languageService.currentLocale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: LanguageService.supportedLocales,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
