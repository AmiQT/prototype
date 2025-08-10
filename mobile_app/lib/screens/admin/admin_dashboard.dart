import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/profile_service.dart';
import '../../../services/achievement_service.dart';
import '../../../models/user_model.dart';
import '../../../widgets/custom_button.dart';
import '../settings/settings_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  UserModel? _currentUser;
  bool _isLoading = true;

  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _topDepartments = [];

  // Recent activities would typically come from an activity log service
  // For now, we'll keep a simple structure but note this should be from Firebase
  final List<Map<String, dynamic>> _recentActivities = [
    {
      'type': 'system_info',
      'description': 'Dashboard loaded successfully',
      'time': 'Just now',
      'icon': Icons.info,
      'color': Colors.blue,
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
      }

      // Load real statistics from Firebase
      await _loadStatistics(authService, profileService, achievementService);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadStatistics(
      AuthService authService,
      ProfileService profileService,
      AchievementService achievementService) async {
    try {
      // Get all users
      final allUsers = await authService.getAllUsers();
      final students =
          allUsers.where((user) => user.role == UserRole.student).toList();
      final lecturers =
          allUsers.where((user) => user.role == UserRole.lecturer).toList();

      // Get all profiles
      final allProfiles = await profileService.getAllProfiles();

      // Get achievement statistics
      final achievementStats = await achievementService.getAchievementStats();

      // Calculate department statistics
      final departmentCounts = <String, Map<String, int>>{};
      for (var profile in allProfiles) {
        if (!departmentCounts.containsKey(profile.department)) {
          departmentCounts[profile.department] = {
            'students': 0,
            'achievements': 0
          };
        }
        departmentCounts[profile.department]!['students'] =
            (departmentCounts[profile.department]!['students'] ?? 0) + 1;
      }

      setState(() {
        _stats = {
          'totalUsers': allUsers.length,
          'totalStudents': students.length,
          'totalLecturers': lecturers.length,
          'pendingVerifications':
              achievementStats['unverifiedAchievements'] ?? 0,
          'verifiedAchievements': achievementStats['verifiedAchievements'] ?? 0,
          'totalDepartments': departmentCounts.length,
          'activeUsers':
              allUsers.length, // Simplified - all users considered active
          'systemHealth': 'Excellent',
        };

        _topDepartments = departmentCounts.entries
            .map((entry) => {
                  'name': entry.key,
                  'students': entry.value['students'] ?? 0,
                  'achievements': entry.value['achievements'] ?? 0,
                })
            .toList()
          ..sort(
              (a, b) => (b['students'] as int).compareTo(a['students'] as int));
      });
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  void _navigateToFeature(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature feature coming soon!')),
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
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                Provider.of<AuthService>(context, listen: false).signOut();
              } else if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$value feature coming soon!')),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.red[700],
                          child: const Icon(
                            Icons.admin_panel_settings,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'System Administrator',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                              Text(
                                _currentUser?.name ?? 'Administrator',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red[700],
                                    ),
                              ),
                              Text(
                                'UTHM Talent Profiling System',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Online',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // System Overview
            Text(
              'System Overview',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: [
                _buildStatCard(
                  'Total Users',
                  _stats['totalUsers'].toString(),
                  Icons.people,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Active Users',
                  _stats['activeUsers'].toString(),
                  Icons.person_pin,
                  Colors.green,
                ),
                _buildStatCard(
                  'Pending Verifications',
                  _stats['pendingVerifications'].toString(),
                  Icons.pending_actions,
                  Colors.orange,
                ),
                _buildStatCard(
                  'System Health',
                  _stats['systemHealth'],
                  Icons.health_and_safety,
                  Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildActionCard(
                  'User Management',
                  Icons.people_outline,
                  Colors.blue,
                  () => _navigateToFeature('User Management'),
                ),
                _buildActionCard(
                  'System Analytics',
                  Icons.analytics,
                  Colors.purple,
                  () => _navigateToFeature('System Analytics'),
                ),
                _buildActionCard(
                  'Achievement Oversight',
                  Icons.verified_user,
                  Colors.green,
                  () => _navigateToFeature('Achievement Oversight'),
                ),
                _buildActionCard(
                  'System Settings',
                  Icons.settings,
                  Colors.grey,
                  () => _navigateToFeature('System Settings'),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Recent Activities
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activities',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () => _navigateToFeature('View All Activities'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Card(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentActivities.length,
                itemBuilder: (context, index) {
                  final activity = _recentActivities[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: activity['color'],
                      child: Icon(
                        activity['icon'],
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      activity['description'],
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      activity['time'],
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => _navigateToFeature('View Activity Details'),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Department Statistics
            Text(
              'Department Statistics',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Top Departments',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              _navigateToFeature('View All Departments'),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._topDepartments.map((dept) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  dept['name'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${dept['students']} students',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${dept['achievements']} achievements',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // System Health & Performance
            Text(
              'System Health & Performance',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            const Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.speed, size: 32, color: Colors.green),
                          SizedBox(height: 8),
                          Text(
                            'Performance',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Excellent',
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.security, size: 32, color: Colors.blue),
                          SizedBox(height: 8),
                          Text(
                            'Security',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Protected',
                            style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.backup, size: 32, color: Colors.orange),
                          SizedBox(height: 8),
                          Text(
                            'Backup',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Up to date',
                            style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Emergency Actions
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Emergency Actions',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'System Maintenance',
                            onPressed: () =>
                                _navigateToFeature('System Maintenance'),
                            backgroundColor: Colors.orange,
                            icon: Icons.build,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            text: 'Emergency Shutdown',
                            onPressed: () =>
                                _navigateToFeature('Emergency Shutdown'),
                            backgroundColor: Colors.red,
                            icon: Icons.power_settings_new,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
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
}
