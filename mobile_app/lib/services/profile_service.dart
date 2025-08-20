import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/profile_model.dart';
import '../models/experience_model.dart';
import '../models/project_model.dart';
import '../models/academic_info_model.dart';
import '../config/supabase_config.dart';

class ProfileService {
  static const String baseUrl =
      'https://c3168f89d034.ngrok-free.app'; // ngrok tunnel

  // Get Supabase auth token for authentication
  static Future<String?> _getAuthToken() async {
    try {
      final session = SupabaseConfig.auth.currentSession;
      if (session?.accessToken != null) {
        return session!.accessToken;
      }
      return null;
    } catch (e) {
      debugPrint('ProfileService: Error getting auth token: $e');
      return null;
    }
  }

  Future<void> saveProfile(ProfileModel profile) async {
    try {
      debugPrint(
          'ProfileService: Saving profile for userId: ${profile.userId}');

      // Validate profile data before saving
      if (profile.userId.isEmpty || profile.fullName.isEmpty) {
        throw Exception(
            'Profile data is incomplete. User ID and full name are required.');
      }

      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      // Try to save to backend first
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/api/profiles'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(profile.toJson()),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          debugPrint('ProfileService: Profile saved successfully to backend');
        } else {
          debugPrint(
              'ProfileService: Failed to save profile to backend: ${response.body}');
          throw Exception('Backend offline, trying Supabase fallback');
        }
      } catch (e) {
        debugPrint(
            'ProfileService: Backend save failed, using Supabase fallback: $e');

        // Fallback: Save to Supabase
        await _saveProfileToSupabase(profile);
        return;
      }

      // Also save to Supabase for redundancy
      await _saveProfileToSupabase(profile);
    } catch (e) {
      debugPrint('ProfileService: Error saving profile: $e');
      rethrow;
    }
  }

  // Save profile to Supabase as fallback
  Future<void> _saveProfileToSupabase(ProfileModel profile) async {
    try {
      debugPrint(
          'ProfileService: Saving profile to Supabase for userId: ${profile.userId}');

      // Save to profiles table
      await SupabaseConfig.client.from('profiles').upsert({
        'user_id': profile.userId,
        'full_name': profile.fullName,
        'headline': profile.headline ?? '',
        'bio': profile.bio ?? '',
        'profile_image_url': profile.profileImageUrl ?? '',
        'academic_info': profile.academicInfo?.toJson(),
        'skills': profile.skills,
        'interests': profile.interests,
        'is_profile_complete': profile.isProfileComplete,
        'created_at': profile.createdAt.toIso8601String(),
        'updated_at': profile.updatedAt.toIso8601String(),
      });

      // Update users table profile completion status
      await SupabaseConfig.client.from('users').upsert({
        'id': profile.userId,
        'profile_completed': profile.isProfileComplete,
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('ProfileService: Profile saved to Supabase successfully');
    } catch (e) {
      debugPrint('ProfileService: Error saving profile to Supabase: $e');
      rethrow;
    }
  }

  Future<ProfileModel?> getProfileByUserId(String userId) async {
    try {
      debugPrint('ProfileService: Getting profile for userId: $userId');

      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      // Try to get from backend first
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/api/profiles/$userId'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          debugPrint(
              'ProfileService: Profile retrieved successfully from backend');
          return ProfileModel.fromJson(data);
        } else if (response.statusCode == 404) {
          debugPrint(
              'ProfileService: Profile not found in backend for userId: $userId');
        } else {
          debugPrint(
              'ProfileService: Failed to get profile from backend: ${response.body}');
          throw Exception('Backend offline, trying Supabase fallback');
        }
      } catch (e) {
        debugPrint(
            'ProfileService: Backend retrieval failed, using Supabase fallback: $e');

        // Fallback: Get from Supabase
        return await _getProfileFromSupabase(userId);
      }

      // Also try Supabase as backup
      return await _getProfileFromSupabase(userId);
    } catch (e) {
      debugPrint('ProfileService: Error getting profile: $e');
      return null;
    }
  }

  // Get profile from Supabase as fallback
  Future<ProfileModel?> _getProfileFromSupabase(String userId) async {
    try {
      debugPrint(
          'ProfileService: Getting profile from Supabase for userId: $userId');

      final response = await SupabaseConfig.client
          .from('profiles')
          .select('*')
          .eq('user_id', userId)
          .single();

      // Convert Supabase response to ProfileModel
      return ProfileModel(
          id: response['id'] ?? '',
          userId: response['user_id'] ?? userId,
          fullName: response['full_name'] ?? '',
          headline: response['headline'],
          bio: response['bio'],
          profileImageUrl: response['profile_image_url'],
          academicInfo: response['academic_info'] != null
              ? AcademicInfoModel.fromJson(response['academic_info'])
              : null,
          skills: List<String>.from(response['skills'] ?? []),
          interests: List<String>.from(response['interests'] ?? []),
          experiences: [], // TODO: Add experiences support
          projects: [], // TODO: Add projects support
          isProfileComplete: response['is_profile_complete'] ?? false,
          completedSections: ['basic'], // Default sections
          createdAt: response['created_at'] != null
              ? DateTime.parse(response['created_at'])
              : DateTime.now(),
          updatedAt: response['updated_at'] != null
              ? DateTime.parse(response['updated_at'])
              : DateTime.now(),
        );
      }

      return null;
    } catch (e) {
      debugPrint('ProfileService: Error getting profile from Supabase: $e');
      return null;
    }
  }

  Future<List<ProfileModel>> getAllProfiles() async {
    try {
      debugPrint('ProfileService: Getting all profiles');

      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/profiles'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final profiles = <ProfileModel>[];

        for (var profileData in data) {
          final profile = ProfileModel(
            id: profileData['id'] ?? '',
            userId: profileData['user_id'] ?? '',
            fullName: profileData['full_name'] ?? '',
            phoneNumber: profileData['phone_number'],
            address: profileData['address'],
            bio: profileData['bio'],
            headline: profileData['headline'],
            profileImageUrl: profileData['profile_image_url'],
            academicInfo: null, // Will be populated from individual fields
            skills: List<String>.from(profileData['skills'] ?? []),
            interests: List<String>.from(profileData['interests'] ?? []),
            experiences: (profileData['experiences'] as List<dynamic>?)
                    ?.map((e) =>
                        ExperienceModel.fromJson(e as Map<String, dynamic>))
                    .toList() ??
                [],
            projects: (profileData['projects'] as List<dynamic>?)
                    ?.map(
                        (p) => ProjectModel.fromJson(p as Map<String, dynamic>))
                    .toList() ??
                [],
            achievements: [], // Will be populated separately
            linkedinUrl: profileData['linkedin_url'],
            githubUrl: profileData['github_url'],
            portfolioUrl: profileData['portfolio_url'],
            phone: profileData['phone'],
            studentId: profileData['student_id'],
            department: profileData['department'],
            faculty: profileData['faculty'],
            yearOfStudy: profileData['year_of_study'],
            cgpa: profileData['cgpa'],
            languages: List<String>.from(profileData['languages'] ?? []),
            createdAt: profileData['created_at'] != null
                ? DateTime.parse(profileData['created_at'])
                : DateTime.now(),
            updatedAt: profileData['updated_at'] != null
                ? DateTime.parse(profileData['updated_at'])
                : DateTime.now(),
          );
          profiles.add(profile);
        }

        debugPrint('ProfileService: Retrieved ${profiles.length} profiles');
        return profiles;
      } else {
        debugPrint('ProfileService: Failed to get profiles: ${response.body}');
        throw Exception('Failed to get profiles: ${response.body}');
      }
    } catch (e) {
      debugPrint('ProfileService: Error getting profiles: $e');
      return [];
    }
  }

  Future<List<ProfileModel>> searchProfiles(String query) async {
    try {
      debugPrint('ProfileService: Searching profiles with query: $query');

      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/profiles/search?q=${Uri.encodeComponent(query)}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final profiles = <ProfileModel>[];

        for (var profileData in data) {
          final profile = ProfileModel(
            id: profileData['id'] ?? '',
            userId: profileData['user_id'] ?? '',
            fullName: profileData['full_name'] ?? '',
            phoneNumber: profileData['phone_number'],
            address: profileData['address'],
            bio: profileData['bio'],
            headline: profileData['headline'],
            profileImageUrl: profileData['profile_image_url'],
            academicInfo: null,
            skills: List<String>.from(profileData['skills'] ?? []),
            interests: List<String>.from(profileData['interests'] ?? []),
            experiences: (profileData['experiences'] as List<dynamic>?)
                    ?.map((e) =>
                        ExperienceModel.fromJson(e as Map<String, dynamic>))
                    .toList() ??
                [],
            projects: (profileData['projects'] as List<dynamic>?)
                    ?.map(
                        (p) => ProjectModel.fromJson(p as Map<String, dynamic>))
                    .toList() ??
                [],
            achievements: [],
            linkedinUrl: profileData['linkedin_url'],
            githubUrl: profileData['github_url'],
            portfolioUrl: profileData['portfolio_url'],
            phone: profileData['phone'],
            studentId: profileData['student_id'],
            department: profileData['department'],
            faculty: profileData['faculty'],
            yearOfStudy: profileData['year_of_study'],
            cgpa: profileData['cgpa'],
            languages: List<String>.from(profileData['languages'] ?? []),
            createdAt: profileData['created_at'] != null
                ? DateTime.parse(profileData['created_at'])
                : DateTime.now(),
            updatedAt: profileData['updated_at'] != null
                ? DateTime.parse(profileData['updated_at'])
                : DateTime.now(),
          );
          profiles.add(profile);
        }

        debugPrint(
            'ProfileService: Found ${profiles.length} profiles matching query');
        return profiles;
      } else {
        debugPrint(
            'ProfileService: Failed to search profiles: ${response.body}');
        throw Exception('Failed to search profiles: ${response.body}');
      }
    } catch (e) {
      debugPrint('ProfileService: Error searching profiles: $e');
      return [];
    }
  }

  Future<void> updateProfile(ProfileModel profile) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/profiles/${profile.userId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(profile.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  Future<void> deleteProfile(String profileId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/profiles/$profileId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete profile: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error deleting profile: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProfileStats() async {
    try {
      final allProfiles = await getAllProfiles();

      // Count by department
      final departmentCounts = <String, int>{};
      for (var profile in allProfiles) {
        final dept = profile.department ?? 'Unknown';
        departmentCounts[dept] = (departmentCounts[dept] ?? 0) + 1;
      }

      // Count by program
      final programCounts = <String, int>{};
      for (var profile in allProfiles) {
        programCounts[profile.program] =
            (programCounts[profile.program] ?? 0) + 1;
      }

      return {
        'totalProfiles': allProfiles.length,
        'departmentCounts': departmentCounts,
        'programCounts': programCounts,
      };
    } catch (e) {
      debugPrint('Error getting profile stats: $e');
      return {
        'totalProfiles': 0,
        'departmentCounts': {},
        'programCounts': {},
      };
    }
  }

  Stream<List<ProfileModel>> streamAllProfiles() {
    // For HTTP backend, we'll need to implement polling or use WebSocket
    // For now, return an empty stream
    return Stream.value([]);
  }

  Stream<ProfileModel?> streamProfileByUserId(String userId) {
    // For HTTP backend, we'll need to implement polling or use WebSocket
    // For now, return an empty stream
    return Stream.value(null);
  }

  // Add missing getProfileById method
  Future<ProfileModel?> getProfileById(String profileId) async {
    try {
      debugPrint('ProfileService: Getting profile by ID: $profileId');

      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/profiles/by-id/$profileId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('ProfileService: Profile retrieved successfully by ID');
        return ProfileModel.fromJson(data);
      } else if (response.statusCode == 404) {
        debugPrint('ProfileService: Profile not found for ID: $profileId');
        return null;
      } else {
        debugPrint(
            'ProfileService: Failed to get profile by ID: ${response.body}');
        throw Exception('Failed to get profile by ID: ${response.body}');
      }
    } catch (e) {
      debugPrint('ProfileService: Error getting profile by ID: $e');
      return null;
    }
  }
}
