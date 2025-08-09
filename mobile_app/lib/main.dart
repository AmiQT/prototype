import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'services/achievement_service.dart';
import 'services/showcase_service.dart';
import 'services/search_service.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load();
  } catch (e) {
    debugPrint('Failed to load .env: $e');
  }
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Failed to initialize Firebase: $e');
  }

  // Initialize AuthService to restore user session
  final authService = AuthService();
  await authService.initialize();

  runApp(MyApp(authService: authService));
}

class MyApp extends StatelessWidget {
  final AuthService authService;

  const MyApp({super.key, required this.authService});

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
      ],
      child: MaterialApp(
        title: 'Student Talent Profiling App',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}
