import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/achievement_service.dart';
import '../../models/user_model.dart';
import '../../models/profile_model.dart';
import '../../models/achievement_model.dart';
import '../../widgets/custom_button.dart';
import 'profile/student_profile_screen.dart';
import 'achievements/achievements_screen.dart';
import 'showcase/showcase_screen.dart';
import 'search/search_screen.dart';
import 'event_program/event_program_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ShowcaseScreen(),
    const SearchScreen(),
    const EventProgramScreen(),
    const StudentProfileScreen(),
    const Center(
        child: Text('Notifications (Coming Soon)',
            style: TextStyle(color: Colors.grey, fontSize: 18))),
  ];

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
    BottomNavigationBarItem(
        icon: Icon(Icons.event_available), label: 'Event/Program'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    BottomNavigationBarItem(
        icon: Icon(Icons.notifications), label: 'Notifications'),
  ];

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

  final List<Map<String, dynamic>> _recentActivities = [
    {
      'type': 'achievement_added',
      'description': 'Added new achievement: Dean\'s List Award',
      'time': '2 hours ago',
      'icon': Icons.add_circle,
      'color': Colors.green,
    },
    {
      'type': 'achievement_verified',
      'description': 'Innovation Challenge achievement verified',
      'time': '1 day ago',
      'icon': Icons.verified,
      'color': Colors.blue,
    },
    {
      'type': 'showcase_post',
      'description': 'Created showcase post about project completion',
      'time': '2 days ago',
      'icon': Icons.post_add,
      'color': Colors.purple,
    },
  ];

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading dashboard: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToScreen(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        items: _navItems,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey[500],
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        iconSize: 28,
        elevation: 12,
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressItem(String title, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildTipItem(String tip) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle, size: 16, color: Colors.blue[700]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            tip,
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[700],
            ),
          ),
        ),
      ],
    );
  }

  Color _getTypeColor(AchievementType type) {
    switch (type) {
      case AchievementType.academic:
        return Colors.blue;
      case AchievementType.competition:
        return Colors.purple;
      case AchievementType.leadership:
        return Colors.green;
      case AchievementType.skill:
        return Colors.orange;
      case AchievementType.other:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(AchievementType type) {
    switch (type) {
      case AchievementType.academic:
        return Icons.school;
      case AchievementType.competition:
        return Icons.emoji_events;
      case AchievementType.leadership:
        return Icons.people;
      case AchievementType.skill:
        return Icons.psychology;
      case AchievementType.other:
        return Icons.star;
    }
  }
}
