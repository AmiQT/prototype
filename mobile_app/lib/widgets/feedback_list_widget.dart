import 'package:flutter/material.dart';

class FeedbackListWidget extends StatelessWidget {
  final List<String> mockFeedback = [
    'Excellent presentation skills!',
    'Needs improvement in time management.',
    'Very creative project!',
  ];

  FeedbackListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: mockFeedback.length,
      itemBuilder: (ctx, index) => Card(
        child: ListTile(
          title: Text(mockFeedback[index]),
          subtitle: const Text('Lecturer Feedback'),
        ),
      ),
    );
  }
}
