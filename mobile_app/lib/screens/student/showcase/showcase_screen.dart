import 'package:flutter/material.dart';
import 'post_creation_screen.dart';
import 'showcase_feed_screen.dart';
import '../../../widgets/modern/modern_home_header.dart';
import '../../../utils/app_theme.dart';
import '../../shared/notifications_screen.dart';
// import '../../debug/simple_backend_test.dart'; // Debug screen removed

class ShowcaseScreen extends StatefulWidget {
  const ShowcaseScreen({super.key});

  @override
  State<ShowcaseScreen> createState() => _ShowcaseScreenState();
}

class _ShowcaseScreenState extends State<ShowcaseScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          ModernHomeHeader(
            onCreatePost: () => _navigateToCreatePost(context),
            onNotificationTap: () => _navigateToNotifications(context),
            onProfileTap: () {
              // Navigate to profile tab
              _navigateToProfile(context);
            },
          ),
          // Backend Test Button (temporary for testing)
          Container(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Scaffold(body: Center(child: Text('Debug screen removed'))),
                  ),
                );
              },
              icon: const Icon(Icons.api),
              label: const Text('Test Backend'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const Expanded(
            child: ShowcaseFeedScreen(),
          ),
        ],
      ),
    );
  }

  void _navigateToCreatePost(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PostCreationScreen(),
      ),
    );
  }

  void _navigateToNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
  }

  void _navigateToProfile(BuildContext context) {
    // Find the parent dashboard and switch to profile tab
    final dashboardContext = context.findAncestorStateOfType<State>();
    if (dashboardContext != null) {
      // Try to access the dashboard's setState to change tab
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Tap the Profile tab at the bottom to view your profile'),
          backgroundColor: AppTheme.infoColor,
        ),
      );
    }
  }
}
