import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import 'showcase/showcase_screen.dart';
import 'search/enhanced_search_screen.dart';
import 'event_program/event_program_screen.dart';
import 'profile/student_profile_screen.dart';
import '../chat/chat_screen.dart';

class EnhancedStudentDashboard extends StatefulWidget {
  const EnhancedStudentDashboard({super.key});

  @override
  State<EnhancedStudentDashboard> createState() =>
      _EnhancedStudentDashboardState();
}

class _EnhancedStudentDashboardState extends State<EnhancedStudentDashboard>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isLoading = true;

  final List<Widget> _pages = [
    const ShowcaseScreen(),
    const EnhancedSearchScreen(),
    const EventProgramScreen(),
    const StudentProfileScreen(),
  ];

  final List<NavigationItem> _navItems = [
    NavigationItem(
      icon: Icons.home_rounded,
      activeIcon: Icons.home,
      label: 'Home',
      color: AppTheme.primaryColor,
    ),
    NavigationItem(
      icon: Icons.search_rounded,
      activeIcon: Icons.search,
      label: 'Discover',
      color: AppTheme.successColor,
    ),
    NavigationItem(
      icon: Icons.event_rounded,
      activeIcon: Icons.event,
      label: 'Events',
      color: AppTheme.warningColor,
    ),
    NavigationItem(
      icon: Icons.person_rounded,
      activeIcon: Icons.person,
      label: 'Profile',
      color: AppTheme.secondaryColor,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final profileService =
          Provider.of<ProfileService>(context, listen: false);

      final user = authService.currentUser;
      if (user != null) {
        // Load user data if needed in the future
        await authService.getUserData(user.uid);
        await profileService.getProfileByUserId(user.uid);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dashboard: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  void _onNavItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });

      // Add haptic feedback
      // HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceLg),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
              const SizedBox(height: AppTheme.spaceLg),
              Text(
                'Loading your dashboard...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
        ),
      ),
      bottomNavigationBar: _buildModernBottomNav(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildModernBottomNav() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onNavItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: _navItems[_selectedIndex].color,
          unselectedItemColor: AppTheme.textSecondaryColor,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          items: _navItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = _selectedIndex == index;

            return BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(AppTheme.spaceXs),
                decoration: BoxDecoration(
                  color: isSelected
                      ? item.color.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: 24,
                ),
              ),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userRole = authService.currentUser?.role;

    if ((userRole == UserRole.student || userRole == UserRole.lecturer)) {
      return Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: "enhanced_dashboard_chat_fab",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatScreen()),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          tooltip: 'STAP UTHM Advisor',
          child: const Icon(
            Icons.smart_toy_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      );
    }
    return null;
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}
