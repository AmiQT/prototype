import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_auth_service.dart';
import '../models/user_model.dart';
import 'auth/comprehensive_profile_setup_screen.dart';
import 'auth/login_screen.dart';
import 'student/enhanced_student_dashboard.dart';
import 'lecturer/lecturer_dashboard.dart';
import 'admin/admin_dashboard.dart';

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
    _checkAuthState();
  }

  @override
  void dispose() {
    _disposed = true;
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthState() async {
    await Future.delayed(const Duration(seconds: 3));

    if (_disposed || !mounted) return;

    try {
      final authService =
          Provider.of<SupabaseAuthService>(context, listen: false);

      // Initialize auth service
      await authService.initialize();

      if (_disposed || !mounted) return;

      // DEBUG: Force logout to clear any existing sessions
      debugPrint(
          'SplashScreen: Force logging out to clear any existing sessions...');
      await authService.signOut();

      // Check if user is authenticated with Supabase
      final supabaseUser = authService.supabaseUser;
      debugPrint('SplashScreen: Supabase user check: ${supabaseUser?.id}');

      if (supabaseUser != null) {
        // User is authenticated, check profile completion
        debugPrint(
            'SplashScreen: User authenticated, checking profile completion...');
        final hasCompletedProfile =
            await authService.hasCompletedProfile(supabaseUser.id);

        if (hasCompletedProfile) {
          // Profile complete, navigate to dashboard
          debugPrint('SplashScreen: Profile complete, navigating to dashboard');
          final user = authService.currentUser;
          if (user != null) {
            _navigateBasedOnRole(user);
          } else {
            debugPrint('SplashScreen: Current user is null, going to login');
            _navigateToLogin();
          }
        } else {
          // Profile incomplete, go to profile setup
          debugPrint(
              'SplashScreen: Profile incomplete, going to profile setup');
          _navigateToProfileSetup();
        }
      } else {
        // No authenticated user, go to login
        debugPrint('SplashScreen: No authenticated user, going to login');
        _navigateToLogin();
      }
    } catch (e) {
      debugPrint('SplashScreen: Error during auth check: $e');
      if (!_disposed && mounted) {
        _navigateToLogin();
      }
    }
  }

  void _navigateBasedOnRole(UserModel user) async {
    // Check if user has completed their profile
    final authService =
        Provider.of<SupabaseAuthService>(context, listen: false);
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
        targetScreen = const AdminDashboard();
        break;
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => targetScreen),
      );
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _navigateToProfileSetup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
          builder: (context) => const ComprehensiveProfileSetupScreen()),
    );
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
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
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    Text(
                      'Profiling App',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 48),

                    // Loading indicator
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 24),

                    // Subtitle
                    Text(
                      'UTHM FSKTM',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                    ),

                    // Error message if navigation fails
                    if (!_disposed && !mounted)
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Text(
                          'An error occurred. Please restart the app.',
                          style: TextStyle(color: Colors.red, fontSize: 16),
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
