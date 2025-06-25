// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_talent_profiling_app/widgets/feedback_widget.dart';

import 'package:student_talent_profiling_app/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('FeedbackWidget submits feedback', (WidgetTester tester) async {
    bool feedbackSubmitted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeedbackWidget(
            onFeedbackSubmitted: (feedback) {
              feedbackSubmitted = true;
            },
          ),
        ),
      ),
    );

    // Enter feedback
    await tester.enterText(find.byType(TextField), 'Great work!');
    await tester.tap(find.text('Submit Feedback'));
    await tester.pump();

    expect(feedbackSubmitted, true);
    expect(find.text('Feedback submitted!'), findsOneWidget);
  });
}
