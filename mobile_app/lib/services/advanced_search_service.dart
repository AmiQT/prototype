import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';

class AdvancedSearchService {
  static const String baseUrl = 'https://c3168f89d034.ngrok-free.app'; // ngrok tunnel
  
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
  
  // Check if test data exists
  static Future<Map<String, dynamic>> checkTestData() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/search-simple/test-data-check'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to check test data: ${response.body}');
      }
    } catch (e) {
      throw Exception('Test data check error: $e');
    }
  }
  
  // Get search statistics
  static Future<Map<String, dynamic>> getSearchStats() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/search-simple/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get search stats: ${response.body}');
      }
    } catch (e) {
      throw Exception('Search stats error: $e');
    }
  }
  
  // Simplified student search that works reliably
  static Future<Map<String, dynamic>> searchStudents({
    String? query,
    String? name,
    String? email,
    String? studentId,
    String? department,
    String? faculty,
    String? yearOfStudy,
    String? skills,
    String? interests,
    int? minAchievements,
    String? achievementCategory,
    int? minEvents,
    String? eventCategory,
    double? minCgpa,
    double? maxCgpa,
    int limit = 20,
    int offset = 0,
    String sortBy = 'name',
    String sortOrder = 'asc',
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
        'sort_by': sortBy,
        'sort_order': sortOrder,
      };
      
      // Add optional parameters
      if (query != null && query.isNotEmpty) queryParams['q'] = query;
      if (name != null && name.isNotEmpty) queryParams['name'] = name;
      if (email != null && email.isNotEmpty) queryParams['email'] = email;
      if (studentId != null && studentId.isNotEmpty) queryParams['student_id'] = studentId;
      if (department != null && department.isNotEmpty) queryParams['department'] = department;
      if (faculty != null && faculty.isNotEmpty) queryParams['faculty'] = faculty;
      if (yearOfStudy != null && yearOfStudy.isNotEmpty) queryParams['year_of_study'] = yearOfStudy;
      if (skills != null && skills.isNotEmpty) queryParams['skills'] = skills;
      if (interests != null && interests.isNotEmpty) queryParams['interests'] = interests;
      if (minAchievements != null) queryParams['min_achievements'] = minAchievements.toString();
      if (achievementCategory != null && achievementCategory.isNotEmpty) queryParams['achievement_category'] = achievementCategory;
      if (minEvents != null) queryParams['min_events'] = minEvents.toString();
      if (eventCategory != null && eventCategory.isNotEmpty) queryParams['event_category'] = eventCategory;
      if (minCgpa != null) queryParams['min_cgpa'] = minCgpa.toString();
      if (maxCgpa != null) queryParams['max_cgpa'] = maxCgpa.toString();
      
      final uri = Uri.parse('$baseUrl/api/search-simple/students').replace(
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
      throw Exception('Advanced search error: $e');
    }
  }
  
  // Find students similar to a specific student
  static Future<Map<String, dynamic>> findSimilarStudents(
    String studentId, {
    int limit = 10,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }
      
      final uri = Uri.parse('$baseUrl/api/search/similar-students/$studentId').replace(
        queryParameters: {'limit': limit.toString()},
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
        throw Exception('Similar students search failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Similar students error: $e');
    }
  }
  
  // Quick search presets for common use cases (simplified)
  static Future<Map<String, dynamic>> searchByDepartment(String department) async {
    return await searchStudents(
      department: department,
      limit: 20,
    );
  }
  
  static Future<Map<String, dynamic>> searchByName(String name) async {
    return await searchStudents(
      query: name,
      limit: 20,
    );
  }
  
  static Future<Map<String, dynamic>> searchFSKTMStudents() async {
    return await searchStudents(
      department: 'FSKTM',
      limit: 20,
    );
  }
  
  static Future<Map<String, dynamic>> searchAllStudents() async {
    return await searchStudents(
      limit: 20,
    );
  }
}