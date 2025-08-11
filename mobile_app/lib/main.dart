import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'services/achievement_service.dart';
import 'services/showcase_service.dart';
import 'services/search_service.dart';
import 'services/notification_service.dart';
import 'services/language_service.dart';
// Removed OpenRouter chat service import to use Gemini only
import 'services/gemini_chat_service.dart';
import 'services/chat_history_service.dart';
import 'services/firebase_usage_monitor.dart';
import 'config/app_config.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

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
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Failed to initialize Firebase: $e');
    }
  }

  // Initialize services
  final authService = AuthService();
  await authService.initialize();

  final languageService = LanguageService();
  await languageService.initialize();

  // Initialize usage monitor and ensure Gemini-only chat
  final usageMonitor = FirebaseUsageMonitor();
  try {
    await usageMonitor.initialize();

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
  } catch (e) {
    debugPrint('Chat services initialization failed: $e');
  }

  runApp(MyApp(
    authService: authService,
    languageService: languageService,
  ));
}

class MyApp extends StatelessWidget {
  final AuthService authService;
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
        Provider<AuthService>(
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
