import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Example notifications
    final notifications = [
      {'title': 'Welcome!', 'body': 'Thanks for using the app.'},
      {
        'title': 'Event Reminder',
        'body': 'Don\'t forget to join the upcoming event.'
      },
      {
        'title': 'Profile Update',
        'body': 'Your profile was updated successfully.'
      },
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: notifications.isEmpty
          ? const Center(child: Text('No notifications.'))
          : ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return ListTile(
                  leading: const Icon(Icons.notifications),
                  title: Text(n['title']!),
                  subtitle: Text(n['body']!),
                );
              },
            ),
    );
  }
}
