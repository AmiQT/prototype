import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/profile_model.dart';
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
    } catch (e) {
      debugPrint('ProfileService: Error getting profile from Supabase: $e');
      return null;
    }
  }

  // Get all profiles
  Future<List<ProfileModel>> getAllProfiles() async {
    try {
      final response = await SupabaseConfig.client
          .from('profiles')
          .select('*')
          .order('created_at', ascending: false);

      return response.map((data) => ProfileModel(
        id: data['id'] ?? '',
        userId: data['user_id'] ?? '',
        fullName: data['full_name'] ?? '',
        headline: data['headline'],
        bio: data['bio'],
        profileImageUrl: data['profile_image_url'],
        academicInfo: data['academic_info'] != null
            ? AcademicInfoModel.fromJson(data['academic_info'])
            : null,
        skills: List<String>.from(data['skills'] ?? []),
        interests: List<String>.from(data['interests'] ?? []),
        experiences: [], // TODO: Add experiences support
        projects: [], // TODO: Add projects support
        isProfileComplete: data['is_profile_complete'] ?? false,
        completedSections: ['basic'], // Default sections
        createdAt: data['created_at'] != null
            ? DateTime.parse(data['created_at'])
            : DateTime.now(),
        updatedAt: data['updated_at'] != null
            ? DateTime.parse(data['updated_at'])
            : DateTime.now(),
      )).toList();
    } catch (e) {
      debugPrint('ProfileService: Error getting all profiles: $e');
      return [];
    }
  }

  // Get profile by ID
  Future<ProfileModel?> getProfileById(String profileId) async {
    try {
      final response = await SupabaseConfig.client
          .from('profiles')
          .select('*')
          .eq('id', profileId)
          .single();

      return ProfileModel(
        id: response['id'] ?? '',
        userId: response['user_id'] ?? '',
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
    } catch (e) {
      debugPrint('ProfileService: Error getting profile from Supabase: $e');
      return null;
    }
  }

}
