import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';
import '../config/backend_config.dart';

class BackendService {
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

  // Test backend connection
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Backend connection failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Backend connection error: $e');
    }
  }

  // Test auth bypass (without external auth)
  static Future<Map<String, dynamic>> testAuthBypass() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/test/auth-bypass'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Auth bypass failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Auth bypass error: $e');
    }
  }

  // Verify authentication with backend
  static Future<Map<String, dynamic>> verifyAuth() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Auth verification failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Auth verification error: $e');
    }
  }

  // Get user profile from backend
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get profile: ${response.body}');
      }
    } catch (e) {
      throw Exception('Profile fetch error: $e');
    }
  }

  // Search users (example of advanced feature)
  static Future<Map<String, dynamic>> searchUsers({
    String? query,
    String? role,
    String? department,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      // Build query parameters
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }
      if (role != null && role.isNotEmpty) {
        queryParams['role'] = role;
      }
      if (department != null && department.isNotEmpty) {
        queryParams['department'] = department;
      }

      final uri = Uri.parse('$baseUrl/api/users/search').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Search failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Search error: $e');
    }
  }
}
