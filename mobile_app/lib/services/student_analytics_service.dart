import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';
import '../config/backend_config.dart';

class StudentAnalyticsService {
  static const String baseUrl =
      BackendConfig.baseUrl; // Use stable cloud backend

  // Get Supabase auth token for authentication
  static Future<String?> _getAuthToken() async {
    try {
      final session = SupabaseConfig.auth.currentSession;
      if (session?.accessToken != null) {
        return session!.accessToken;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get personalized dashboard data for current student
  static Future<Map<String, dynamic>> getStudentDashboard() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/student/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get dashboard: ${response.body}');
      }
    } catch (e) {
      throw Exception('Dashboard error: $e');
    }
  }

  // Get personalized recommendations for current student
  static Future<Map<String, dynamic>> getStudentRecommendations() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/student/recommendations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get recommendations: ${response.body}');
      }
    } catch (e) {
      throw Exception('Recommendations error: $e');
    }
  }

  // Get student progress analytics over time
  static Future<Map<String, dynamic>> getStudentProgress() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/student/progress'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get progress: ${response.body}');
      }
    } catch (e) {
      throw Exception('Progress error: $e');
    }
  }

  // Helper method to get user stats summary
  static Future<Map<String, dynamic>> getUserStatsSummary() async {
    try {
      final dashboard = await getStudentDashboard();
      final stats = dashboard['stats'] ?? {};

      return {
        'total_achievements': stats['achievements']?['total'] ?? 0,
        'total_events': stats['events']?['total'] ?? 0,
        'total_posts': stats['showcase']?['total_posts'] ?? 0,
        'total_likes': stats['showcase']?['total_likes'] ?? 0,
        'profile_completion':
            dashboard['user_info']?['profile_completion'] ?? 0,
        'engagement_score': dashboard['insights']?['engagement_score'] ?? 0,
        'activity_level': dashboard['insights']?['activity_level'] ?? 'Low',
      };
    } catch (e) {
      throw Exception('Stats summary error: $e');
    }
  }

  // Helper method to get recent activity
  static Future<List<Map<String, dynamic>>> getRecentActivity() async {
    try {
      final dashboard = await getStudentDashboard();
      final stats = dashboard['stats'] ?? {};

      List<Map<String, dynamic>> activities = [];

      // Add recent achievements
      final recentAchievements = stats['achievements']?['recent'] ?? [];
      for (var achievement in recentAchievements) {
        activities.add({
          'type': 'achievement',
          'title': achievement['title'] ?? 'Achievement',
          'subtitle': achievement['category'] ?? 'General',
          'date': achievement['date'],
          'icon': '🏆',
        });
      }

      // Add recent events
      final recentEvents = stats['events']?['recent'] ?? [];
      for (var event in recentEvents) {
        activities.add({
          'type': 'event',
          'title': event['event_title'] ?? 'Event',
          'subtitle': 'Event Participation',
          'date': event['date'],
          'icon': '📅',
        });
      }

      // Sort by date (most recent first)
      activities.sort((a, b) {
        final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(1970);
        final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });

      return activities.take(5).toList(); // Return top 5 recent activities
    } catch (e) {
      throw Exception('Recent activity error: $e');
    }
  }

  // Helper method to get top recommendations
  static Future<List<Map<String, dynamic>>> getTopRecommendations(
      {int limit = 3}) async {
    try {
      final recommendations = await getStudentRecommendations();
      final recList = recommendations['recommendations'] ?? [];

      // Sort by priority (high, medium, low)
      recList.sort((a, b) {
        final priorityOrder = {'high': 3, 'medium': 2, 'low': 1};
        final priorityA = priorityOrder[a['priority']] ?? 0;
        final priorityB = priorityOrder[b['priority']] ?? 0;
        return priorityB.compareTo(priorityA);
      });

      return List<Map<String, dynamic>>.from(recList.take(limit));
    } catch (e) {
      throw Exception('Top recommendations error: $e');
    }
  }
}
