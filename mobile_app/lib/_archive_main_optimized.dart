import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_initialization_service.dart';
import 'services/supabase_auth_service.dart';
import 'services/profile_service.dart';
import 'services/achievement_service.dart';
import 'providers/settings_provider.dart';
import 'screens/splash_screen.dart';
import 'widgets/network_aware_image.dart';
import 'utils/app_theme.dart';
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Supabase
    await SupabaseConfig.initialize();

    // Initialize optimization services
    await AppInitializationService().initialize();

    runApp(const OptimizedStudentTalentApp());
  } catch (e) {
    debugPrint('❌ App startup failed: $e');
    runApp(const ErrorApp());
  }
}

class OptimizedStudentTalentApp extends StatelessWidget {
  const OptimizedStudentTalentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SupabaseAuthService>(create: (_) => SupabaseAuthService()),
        Provider<ProfileService>(create: (_) => ProfileService()),
        Provider<AchievementService>(create: (_) => AchievementService()),
        ChangeNotifierProvider<SettingsProvider>(
            create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: 'Student Talent Profiling',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            locale: const Locale('en'),
            home: const AppWrapper(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          // Network status indicator
          NetworkStatusIndicator(),

          // Main app content
          Expanded(
            child: SplashScreen(),
          ),
        ],
      ),
    );
  }
}

// Error app for initialization failures
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Talent Profiling',
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'App Initialization Failed',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Restart app
                  main();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
