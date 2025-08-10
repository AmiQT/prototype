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
import 'services/enhanced_chat_service.dart';
import 'services/firebase_usage_monitor.dart';
import 'config/app_config.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize app configuration
  debugPrint('Main: Initializing app configuration...');
  await AppConfig.initialize();
  debugPrint('Main: App configuration initialized');
  debugPrint('Main: API key configured: ${AppConfig.hasApiKey}');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Failed to initialize Firebase: $e');
  }

  // Initialize services
  final authService = AuthService();
  await authService.initialize();

  final languageService = LanguageService();
  await languageService.initialize();

  // Initialize chat services
  final chatService = EnhancedChatService();
  final usageMonitor = FirebaseUsageMonitor();

  try {
    await usageMonitor.initialize();
    await chatService.initialize();
    debugPrint('Chat services initialized successfully');
  } catch (e) {
    debugPrint('Chat services initialization failed: $e');
    // Continue without chat services - they can be initialized later
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
