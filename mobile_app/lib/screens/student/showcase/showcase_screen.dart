import 'package:flutter/material.dart';
import 'post_creation_screen.dart';
import 'showcase_feed_screen.dart';
import '../../../widgets/modern/modern_home_header.dart';
import '../../../utils/app_theme.dart';

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
            onNotificationTap: () {
              // Handle notification tap
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications coming soon!'),
                  backgroundColor: AppTheme.infoColor,
                ),
              );
            },
            onProfileTap: () {
              // Navigate to profile tab
              _navigateToProfile(context);
            },
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
