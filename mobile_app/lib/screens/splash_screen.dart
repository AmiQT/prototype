import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_auth_service.dart';
import '../models/user_model.dart';
import '../config/supabase_config.dart';
import 'auth/comprehensive_profile_setup_screen.dart';
import 'auth/login_screen.dart';
import 'student/enhanced_student_dashboard.dart';
import 'lecturer/lecturer_dashboard.dart';
import '../../utils/debug_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _disposed = true;
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Check if user is authenticated with Supabase
      final supabaseUser = SupabaseConfig.auth.currentUser;
      DebugConfig.logAuth('Supabase user check: ${supabaseUser?.id}');

      if (supabaseUser != null) {
        // User is authenticated, check if profile is complete
        DebugConfig.logAuth(
            'User authenticated, checking profile completion...');

        // Use a simpler profile check for now
        final hasProfile = await _checkProfileExists(supabaseUser.id);

        if (hasProfile) {
          DebugConfig.logAuth('Profile complete, navigating to dashboard');
          _navigateToDashboard(supabaseUser.id);
        } else {
          DebugConfig.logAuth(
              'Profile incomplete, navigating to profile setup');
          _navigateToProfileSetup(supabaseUser.id);
        }
      } else {
        // For now, just go to login if no Supabase user
        DebugConfig.logAuth('No authenticated user, going to login');
        _navigateToLogin();
      }
    } catch (e) {
      DebugConfig.logError('Error during auth check: $e');
      _navigateToLogin();
    }
  }

  // Simple profile existence check
  Future<bool> _checkProfileExists(String userId) async {
    try {
      // Check if profile exists in Supabase
      final response = await SupabaseConfig.client
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      DebugConfig.logWarning('Error checking profile: $e');
      return false;
    }
  }

  void _navigateBasedOnRole(UserModel user) async {
    // Check if user has completed their profile
    final authService =
        Provider.of<SupabaseAuthService>(context, listen: false);

    // Ensure user has valid uid
    if (user.uid.isEmpty) {
      debugPrint('SplashScreen: User uid is empty, going to login');
      _navigateToLogin();
      return;
    }

    final hasCompletedProfile = await authService.hasCompletedProfile(user.uid);

    if (!hasCompletedProfile) {
      // Redirect to profile setup if profile is not complete
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const ComprehensiveProfileSetupScreen(),
          ),
        );
      }
      return;
    }

    // Profile is complete, navigate to appropriate dashboard
    Widget targetScreen;

    switch (user.role) {
      case UserRole.student:
        targetScreen = const EnhancedStudentDashboard();
        break;
      case UserRole.lecturer:
        targetScreen = const LecturerDashboard();
        break;
      case UserRole.admin:
        // Admin uses same interface as students
        targetScreen = const EnhancedStudentDashboard();
        break;
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => targetScreen),
      );
    }
  }

  void _navigateToDashboard(String userId) {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    }
  }

  void _navigateToProfileSetup(String userId) {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/profile-setup');
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .shadow
                                .withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.school,
                        size: 60,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // App Name
                    Text(
                      'Student Talent',
                      style:
                          Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    Text(
                      'Profiling App',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 48),

                    // Loading indicator
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.onPrimary),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 24),

                    // Subtitle
                    Text(
                      'UTHM FSKTM',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withValues(alpha: 0.8),
                          ),
                    ),

                    // Error message if navigation fails
                    if (!_disposed && !mounted)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Text(
                          'An error occurred. Please restart the app.',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 16),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
