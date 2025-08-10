import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/achievement_service.dart';
import '../../models/user_model.dart';
import '../../models/profile_model.dart';
import '../../models/achievement_model.dart';
import 'profile/student_profile_screen.dart';
import 'showcase/showcase_screen.dart';
import 'search/enhanced_search_screen.dart';
import 'event_program/event_program_screen.dart';
import '../chat/chat_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ShowcaseScreen(),
    const EnhancedSearchScreen(),
    const EventProgramScreen(),
    const StudentProfileScreen(),
  ];

  List<BottomNavigationBarItem> _getNavItems(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      BottomNavigationBarItem(icon: const Icon(Icons.home), label: l10n.home),
      BottomNavigationBarItem(
          icon: const Icon(Icons.search), label: l10n.discover),
      BottomNavigationBarItem(
          icon: const Icon(Icons.event_available), label: l10n.eventProgram),
      BottomNavigationBarItem(
          icon: const Icon(Icons.person), label: l10n.profile),
    ];
  }

  UserModel? _currentUser;
  ProfileModel? _currentProfile;
  List<AchievementModel> _recentAchievements = [];
  List<AchievementModel> _allAchievements = [];
  bool _isLoading = true;
  Map<String, dynamic> _stats = {
    'totalAchievements': 0,
    'verifiedAchievements': 0,
    'pendingVerifications': 0,
    'totalPoints': 0,
    'rank': 0,
    'departmentRank': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final profileService =
          Provider.of<ProfileService>(context, listen: false);
      final achievementService =
          Provider.of<AchievementService>(context, listen: false);

      final user = authService.currentUser;
      if (user != null) {
        _currentUser = await authService.getUserData(user.uid);
        _currentProfile = await profileService.getProfileByUserId(user.uid);

        final achievements =
            await achievementService.getAchievementsByUserId(user.uid);
        _allAchievements = achievements;
        _recentAchievements = achievements.take(3).toList();

        int total = achievements.length;
        int verified = achievements.where((a) => a.isVerified).length;
        int pending = total - verified;
        int points = achievements
            .where((a) => a.isVerified)
            .fold(0, (sum, a) => sum + (a.points ?? 0));

        setState(() {
          _stats = {
            'totalAchievements': total,
            'verifiedAchievements': verified,
            'pendingVerifications': pending,
            'totalPoints': points,
            'rank': 0, // Placeholder, implement if you have ranking logic
            'departmentRank':
                0, // Placeholder, implement if you have ranking logic
          };
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userRole = authService.currentUser?.role;
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: _getNavItems(context),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey[500],
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        iconSize: 28,
        elevation: 12,
      ),
      floatingActionButton:
          (userRole == UserRole.student || userRole == UserRole.lecturer)
              ? FloatingActionButton(
                  heroTag: "student_dashboard_chat_fab",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatScreen()),
                    );
                  },
                  tooltip: 'Chatbot',
                  child: const Icon(Icons.chat),
                )
              : null,
    );
  }
}
