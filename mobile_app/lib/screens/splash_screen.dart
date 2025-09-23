import 'package:flutter/material.dart';
import '../config/supabase_config.dart';
// import 'auth/login_screen.dart'; // Unused import removed
// Removed debug config for production

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
      duration:
          const Duration(milliseconds: 200), // ULTRA FAST: Reduced to 0.2s
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut, // FAST: Changed from easeIn
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8, // MINIMAL: Start closer to final size
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut, // FAST: Removed slow elasticOut
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
      debugPrint('Supabase user check: ${supabaseUser?.id}');

      if (supabaseUser != null) {
        // User is authenticated, check if profile is complete
        debugPrint('User authenticated, checking profile completion...');

        // Use a simpler profile check for now
        final hasProfile = await _checkProfileExists(supabaseUser.id);

        if (hasProfile) {
          debugPrint('Profile complete, navigating to dashboard');
          _navigateToDashboard(supabaseUser.id);
        } else {
          debugPrint('Profile incomplete, navigating to profile setup');
          _navigateToProfileSetup(supabaseUser.id);
        }
      } else {
        // For now, just go to login if no Supabase user
        debugPrint('No authenticated user, going to login');
        _navigateToLogin();
      }
    } catch (e) {
      debugPrint('Error during auth check: $e');
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
      debugPrint('Error checking profile: $e');
      return false;
    }
  }

  void _navigateToDashboard(String userId) {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/dashboard');
        }
      });
    }
  }

  void _navigateToProfileSetup(String userId) {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/profile-setup');
        }
      });
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      });
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
