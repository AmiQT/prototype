import 'package:flutter/material.dart';
import 'post_creation_screen.dart';
import 'showcase_feed_screen.dart';
import '../../../widgets/modern/modern_home_header.dart';
import '../../shared/notifications_screen.dart';

class ShowcaseScreen extends StatefulWidget {
  const ShowcaseScreen({super.key});

  @override
  State<ShowcaseScreen> createState() => _ShowcaseScreenState();
}

class _ShowcaseScreenState extends State<ShowcaseScreen> {
  final GlobalKey<State<ShowcaseFeedScreen>> _feedScreenKey =
      GlobalKey<State<ShowcaseFeedScreen>>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
          Expanded(
            child: ShowcaseFeedScreen(key: _feedScreenKey),
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
    ).then((result) {
      // Trigger refresh if post was created successfully
      if (result == true) {
        debugPrint('ShowcaseScreen: Post created, triggering refresh');
        // Call refresh on the feed screen
        (_feedScreenKey.currentState as dynamic)?.forceRefreshFeed();
      }
    });
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
        SnackBar(
          content: const Text(
              'Tap the Profile tab at the bottom to view your profile'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }
}
