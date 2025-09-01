import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';

/// Service to handle database connection issues and provide fallback mechanisms
class DatabaseFixService {
  static final DatabaseFixService _instance = DatabaseFixService._internal();
  factory DatabaseFixService() => _instance;
  DatabaseFixService._internal();

  /// Check if the database schema is compatible with the app
  Future<Map<String, bool>> checkDatabaseCompatibility() async {
    try {
      debugPrint('DatabaseFixService: Checking database compatibility...');

      final results = <String, bool>{};

      // Check profiles table
      try {
        final profilesResponse = await SupabaseConfig.client
            .from('profiles')
            .select('full_name, profile_image_url, student_id, cgpa')
            .limit(1);

        results['profiles_table'] = true;
        results['profiles_full_name'] = profilesResponse.isNotEmpty;
        results['profiles_profile_image_url'] = profilesResponse.isNotEmpty;
        results['profiles_student_id'] = profilesResponse.isNotEmpty;
        results['profiles_cgpa'] = profilesResponse.isNotEmpty;

        debugPrint('DatabaseFixService: Profiles table check passed');
      } catch (e) {
        debugPrint('DatabaseFixService: Profiles table check failed: $e');
        results['profiles_table'] = false;
        results['profiles_full_name'] = false;
        results['profiles_profile_image_url'] = false;
        results['profiles_student_id'] = false;
        results['profiles_cgpa'] = false;
      }

      // Check showcase_posts table
      try {
        final showcaseResponse = await SupabaseConfig.client
            .from('showcase_posts')
            .select('id, user_id, content, created_at')
            .limit(1);

        results['showcase_table'] = true;
        results['showcase_basic_columns'] = showcaseResponse.isNotEmpty;

        debugPrint('DatabaseFixService: Showcase table check passed');
      } catch (e) {
        debugPrint('DatabaseFixService: Showcase table check failed: $e');
        results['showcase_table'] = false;
        results['showcase_basic_columns'] = false;
      }

      // Check users table
      try {
        final usersResponse = await SupabaseConfig.client
            .from('users')
            .select('id, email, name, role')
            .limit(1);

        results['users_table'] = true;
        results['users_basic_columns'] = usersResponse.isNotEmpty;

        debugPrint('DatabaseFixService: Users table check passed');
      } catch (e) {
        debugPrint('DatabaseFixService: Users table check failed: $e');
        results['users_table'] = false;
        results['users_basic_columns'] = false;
      }

      debugPrint('DatabaseFixService: Compatibility check completed: $results');
      return results;
    } catch (e) {
      debugPrint('DatabaseFixService: Error checking compatibility: $e');
      return {
        'profiles_table': false,
        'showcase_table': false,
        'users_table': false,
        'profiles_full_name': false,
        'profiles_profile_image_url': false,
        'profiles_student_id': false,
        'profiles_cgpa': false,
        'showcase_basic_columns': false,
        'users_basic_columns': false,
      };
    }
  }

  /// Get a safe query string based on available columns
  String getSafeProfilesQuery(Map<String, bool> compatibility) {
    if (compatibility['profiles_full_name'] == true) {
      return '''
        profiles:user_id (
          full_name,
          profile_image_url
        )
      ''';
    } else if (compatibility['profiles_table'] == true) {
      // Fallback to basic columns
      return '''
        profiles:user_id (
          id,
          user_id
        )
      ''';
    } else {
      // No profiles table, return empty
      return '';
    }
  }

  /// Get safe user data query
  String getSafeUsersQuery(Map<String, bool> compatibility) {
    if (compatibility['users_basic_columns'] == true) {
      return '''
        users:user_id (
          id,
          name,
          email,
          role
        )
      ''';
    } else {
      return '';
    }
  }

  /// Check if we should use fallback mode
  bool shouldUseFallbackMode(Map<String, bool> compatibility) {
    return compatibility['profiles_table'] == false ||
        compatibility['showcase_table'] == false ||
        compatibility['users_table'] == false;
  }

  /// Get fallback data structure
  Map<String, dynamic> getFallbackUserData(String userId) {
    return {
      'id': userId,
      'name': 'User',
      'email': '',
      'role': 'student',
      'profile_image_url': null,
    };
  }

  /// Log database issues for debugging
  void logDatabaseIssues(Map<String, bool> compatibility) {
    final issues = <String>[];

    if (compatibility['profiles_table'] == false) {
      issues.add('Profiles table missing or inaccessible');
    }
    if (compatibility['showcase_table'] == false) {
      issues.add('Showcase posts table missing or inaccessible');
    }
    if (compatibility['users_table'] == false) {
      issues.add('Users table missing or inaccessible');
    }

    if (issues.isNotEmpty) {
      debugPrint('DatabaseFixService: Database issues detected:');
      for (final issue in issues) {
        debugPrint('  - $issue');
      }
    } else {
      debugPrint('DatabaseFixService: No database issues detected');
    }
  }
}
