import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../widgets/settings_widgets.dart';
import '../../widgets/settings/language_selector.dart';
import '../../l10n/generated/app_localizations.dart';
import 'account_settings_screen.dart';
import 'security_settings_screen.dart';
import 'notification_settings_screen.dart';

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

  void _navigateToNotificationSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsScreen(),
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

    if (confirmed == true && mounted) {
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
                                  .withValues(alpha: 0.1),
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
                                          .withValues(alpha: 0.1),
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
                  SettingsSectionHeader(
                    title: AppLocalizations.of(context).account,
                    subtitle: AppLocalizations.of(context).manageYourAccount,
                  ),
                  SettingsCard(
                    child: Column(
                      children: [
                        SettingsItem(
                          icon: Icons.person,
                          title:
                              AppLocalizations.of(context).accountInformation,
                          subtitle: AppLocalizations.of(context)
                              .updatePersonalDetails,
                          onTap: _navigateToAccountSettings,
                        ),
                        SettingsItem(
                          icon: Icons.security,
                          title: AppLocalizations.of(context).security,
                          subtitle:
                              AppLocalizations.of(context).passwordAndSecurity,
                          onTap: _navigateToSecuritySettings,
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),

                  // Preferences Section
                  SettingsSectionHeader(
                    title: AppLocalizations.of(context).preferences,
                    subtitle:
                        AppLocalizations.of(context).customizeYourExperience,
                  ),
                  SettingsCard(
                    child: Column(
                      children: [
                        SettingsItem(
                          icon: Icons.notifications,
                          title: AppLocalizations.of(context).notifications,
                          subtitle: AppLocalizations.of(context)
                              .manageNotificationPreferences,
                          onTap: _navigateToNotificationSettings,
                        ),
                        const LanguageSelector(),
                      ],
                    ),
                  ),

                  // Support Section
                  SettingsSectionHeader(
                    title: AppLocalizations.of(context).support,
                    subtitle:
                        AppLocalizations.of(context).getHelpAndInformation,
                  ),
                  SettingsCard(
                    child: Column(
                      children: [
                        SettingsItem(
                          icon: Icons.help,
                          title: AppLocalizations.of(context).helpSupport,
                          subtitle: AppLocalizations.of(context).getHelpWithApp,
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
                          title: AppLocalizations.of(context).about,
                          subtitle: AppLocalizations.of(context)
                              .appVersionAndInformation,
                          onTap: _showAboutDialog,
                        ),
                        SettingsItem(
                          icon: Icons.privacy_tip,
                          title: AppLocalizations.of(context).privacyPolicy,
                          subtitle:
                              AppLocalizations.of(context).readPrivacyPolicy,
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
                    text: AppLocalizations.of(context).logout,
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
