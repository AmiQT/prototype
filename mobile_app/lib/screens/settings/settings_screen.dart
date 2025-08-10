import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../widgets/settings_widgets.dart';
import 'account_settings_screen.dart';
import 'security_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser != null && mounted) {
        setState(() {
          _currentUser = currentUser;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('No user data found. Please try logging out and back in.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToAccountSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AccountSettingsScreen(),
      ),
    );
  }

  void _navigateToSecuritySettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SecuritySettingsScreen(),
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Student Talent Profiling',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.school, size: 48),
      children: [
        const Text(
          'A comprehensive platform for managing student profiles, achievements, and talent development.',
        ),
      ],
    );
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Provider.of<AuthService>(context, listen: false).signOut();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // User Profile Header
                  if (_currentUser != null)
                    SettingsCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              child: Text(
                                _currentUser!.name.isNotEmpty
                                    ? _currentUser!.name[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currentUser!.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _currentUser!.email,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _currentUser!.role
                                          .toString()
                                          .split('.')
                                          .last
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Account Section
                  const SettingsSectionHeader(
                    title: 'Account',
                    subtitle: 'Manage your account information',
                  ),
                  SettingsCard(
                    child: Column(
                      children: [
                        SettingsItem(
                          icon: Icons.person,
                          title: 'Account Information',
                          subtitle: 'Update your personal details',
                          onTap: _navigateToAccountSettings,
                        ),
                        SettingsItem(
                          icon: Icons.security,
                          title: 'Security',
                          subtitle: 'Password and security settings',
                          onTap: _navigateToSecuritySettings,
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),

                  // Preferences Section
                  const SettingsSectionHeader(
                    title: 'Preferences',
                    subtitle: 'Customize your app experience',
                  ),
                  SettingsCard(
                    child: Column(
                      children: [
                        SettingsItem(
                          icon: Icons.notifications,
                          title: 'Notifications',
                          subtitle: 'Manage notification preferences',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Notification settings coming soon!'),
                              ),
                            );
                          },
                        ),
                        SettingsItem(
                          icon: Icons.language,
                          title: 'Language',
                          subtitle: 'English',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Language settings coming soon!'),
                              ),
                            );
                          },
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),

                  // Support Section
                  const SettingsSectionHeader(
                    title: 'Support',
                    subtitle: 'Get help and information',
                  ),
                  SettingsCard(
                    child: Column(
                      children: [
                        SettingsItem(
                          icon: Icons.help,
                          title: 'Help & Support',
                          subtitle: 'Get help with the app',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Help & Support coming soon!'),
                              ),
                            );
                          },
                        ),
                        SettingsItem(
                          icon: Icons.info,
                          title: 'About',
                          subtitle: 'App version and information',
                          onTap: _showAboutDialog,
                        ),
                        SettingsItem(
                          icon: Icons.privacy_tip,
                          title: 'Privacy Policy',
                          subtitle: 'Read our privacy policy',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Privacy Policy coming soon!'),
                              ),
                            );
                          },
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),

                  // Sign Out
                  const SizedBox(height: 16),
                  SettingsActionButton(
                    text: 'Sign Out',
                    icon: Icons.logout,
                    onPressed: _handleSignOut,
                    isDestructive: true,
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
