import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';
import '../config/backend_config.dart';

class SyncService {
  static const String baseUrl = BackendConfig.baseUrl; // Use stable backend URL

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

  // Get sync status from backend (test version)
  static Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/sync-test/status'), // Using test endpoint
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get sync status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Sync status error: $e');
    }
  }

  // Create test data in backend (test version)
  static Future<Map<String, dynamic>> createTestData() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/sync-test/test-data'), // Using test endpoint
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create test data: ${response.body}');
      }
    } catch (e) {
      throw Exception('Test data creation error: $e');
    }
  }

  // Get current user info from backend
  static Future<Map<String, dynamic>> getCurrentUserInfo() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/sync-test/user-info'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get user info: ${response.body}');
      }
    } catch (e) {
      throw Exception('User info error: $e');
    }
  }

  // Sync users from Firebase to backend (simplified for testing)
  static Future<Map<String, dynamic>> syncUsersToBackend() async {
    try {
      // For now, just return a message that this feature needs admin access
      return {
        'status': 'info',
        'message':
            'Firebase sync requires admin setup. Use "Create Test Data" instead to see sync functionality.',
        'synced_count': 0,
        'updated_count': 0,
        'note':
            'This demonstrates the sync concept without requiring Firebase admin setup'
      };
    } catch (e) {
      throw Exception('User sync error: $e');
    }
  }

  // Sync profiles from Firebase to backend (simplified for testing)
  static Future<Map<String, dynamic>> syncProfilesToBackend() async {
    try {
      // For now, just return a message that this feature needs admin setup
      return {
        'status': 'info',
        'message':
            'Profile sync requires admin setup. Use "Create Test Data" to see sync functionality.',
        'synced_count': 0,
        'updated_count': 0,
        'note':
            'This demonstrates the sync concept without requiring Firebase admin setup'
      };
    } catch (e) {
      throw Exception('Profile sync error: $e');
    }
  }
}
