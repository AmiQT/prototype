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
import 'l10n/generated/app_localizations.dart';
import 'utils/app_theme.dart';
import 'utils/debug_config.dart';
import 'providers/theme_provider.dart';
import 'widgets/app_initializer.dart';
import 'screens/auth/login_screen.dart';
import 'screens/student/student_dashboard.dart';
import 'screens/auth/profile_setup_screen.dart';

// Override debugPrint for complete silence
void _silentDebugPrint(String? message, {int? wrapWidth}) {
  // Do nothing - complete silence
}

void main() async {
  // Override debugPrint globally
  debugPrint = _silentDebugPrint;

  WidgetsFlutterBinding.ensureInitialized();

  // Always initialize Supabase to prevent initialization errors
  try {
    await SupabaseConfig.initialize();
    // Skip success logging for clean terminal
  } catch (e) {
    DebugConfig.logCritical('Failed to initialize Supabase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Simplified provider chain for better hot restart
        Provider<SupabaseAuthService>(
          create: (_) => SupabaseAuthService(),
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
          create: (_) => LanguageService(),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: Consumer2<LanguageService, ThemeProvider>(
        builder: (context, languageService, themeProvider, child) {
          return MaterialApp(
            title: 'Student Talent Profiling App',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.materialThemeMode,
            debugShowCheckedModeBanner: false,
            locale: languageService.currentLocale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: LanguageService.supportedLocales,
            home: const AppInitializer(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/dashboard': (context) => const StudentDashboard(),
              '/profile-setup': (context) => const ProfileSetupScreen(),
            },
            onUnknownRoute: (settings) {
              // Fallback for unknown routes
              DebugConfig.logWarning('Unknown route: ${settings.name}');
              return MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              );
            },
          );
        },
      ),
    );
  }
}
