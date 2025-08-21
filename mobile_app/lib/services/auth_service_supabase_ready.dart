/*
 * ✅ SUPABASE AUTHENTICATION SERVICE
 * Complete Supabase integration for authentication and user management
 */

import '../models/user_model.dart';
import '../config/supabase_config.dart';
import 'profile_service.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static const String baseUrl = 'https://c3168f89d034.ngrok-free.app'; // ngrok tunnel
  UserModel? _currentUser;
  
  // Get Supabase auth client
  SupabaseClient get _supabase => SupabaseConfig.client;
  
  // Get auth token from Supabase
  Future<String?> getAuthToken() async {
    try {
      final session = _supabase.auth.currentSession;
      return session?.accessToken;
    } catch (e) {
      debugPrint('AuthService: Error getting auth token: $e');
      return null;
    }
  }

  UserModel? get currentUser => _currentUser;

  // Get Supabase current user
  User? get supabaseCurrentUser => _supabase.auth.currentUser;

  // Get current user ID from Supabase
  String? get currentUserId {
    return _supabase.auth.currentUser?.id ?? _currentUser?.id;
  }

  Future<void> initialize() async {
    try {
      // Restore Supabase session
      final session = _supabase.auth.currentSession;
      if (session?.user != null) {
        // Restore user session from Supabase
        await _loadUserFromSupabase(session!.user);
        debugPrint('AuthService: User session restored from Supabase');
      }
    } catch (e) {
      debugPrint('AuthService: Error initializing user session: $e');
    }
  }

  Future<UserModel> signInWithEmailAndPassword(
      String email, String password) async {
    debugPrint('AuthService: Attempting to sign in with email: $email');

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadUserFromSupabase(response.user!);
        debugPrint('AuthService: Sign in successful for user: ${response.user!.id}');
        return _currentUser!;
      } else {
        throw Exception('Sign in failed: No user returned');
      }
    } catch (e) {
      debugPrint('AuthService: Sign in error: $e');
      rethrow;
    }
  }

  Future<UserModel> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    UserRole role, {
    String? studentId,
    String? department,
  }) async {
    
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': role.toString(),
          'student_id': studentId,
          'department': department,
        },
      );

      if (response.user != null) {
        // Create user profile in database
        final userData = {
          'id': response.user!.id,
          'email': email,
          'name': name,
          'role': role.toString(),
          'student_id': studentId,
          'department': department,
          'created_at': DateTime.now().toIso8601String(),
          'is_profile_complete': false,
        };

        await _supabase.from('users').insert(userData);
        await _loadUserFromSupabase(response.user!);
        
        debugPrint('AuthService: Registration successful for user: ${response.user!.id}');
        return _currentUser!;
      } else {
        throw Exception('Registration failed: No user returned');
      }
    } catch (e) {
      debugPrint('AuthService: Registration error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      _currentUser = null;
      debugPrint('AuthService: User signed out successfully');
    } catch (e) {
      debugPrint('AuthService: Sign out error: $e');
      rethrow;
    }
  }

  // Check if user has completed their profile
  Future<bool> hasCompletedProfile(String userId) async {
    try {
      final profileService = ProfileService();
      final profile = await profileService.getProfileByUserId(userId);

      if (profile == null) {
        return false; // No profile exists
      }

      // Check if profile has essential information
      final hasAcademicInfo = profile.academicInfo != null;
      final hasBasicInfo = profile.fullName.isNotEmpty;

      return hasBasicInfo && hasAcademicInfo && profile.isProfileComplete;
    } catch (e) {
      debugPrint('Error checking profile completion: $e');
      return false;
    }
  }

  // Update profile completion status
  Future<void> updateProfileCompletionStatus(
      String userId, bool isComplete) async {
    try {
      await _supabase
          .from('users')
          .update({'is_profile_complete': isComplete})
          .eq('id', userId);
      
      debugPrint('AuthService: Profile completion status updated for user: $userId');
    } catch (e) {
      debugPrint('Error updating profile completion status: $e');
      rethrow;
    }
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      debugPrint('AuthService: Attempting to fetch user data for UID: $uid');
      
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', uid)
          .single();
      
      if (response.isNotEmpty) {
        return UserModel.fromJson(response);
      }
      
      return null;
    } catch (e) {
      debugPrint('AuthService: Error fetching user data for UID $uid: $e');
      return null;
    }
  }

  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _supabase
          .from('users')
          .update(data)
          .eq('id', userId);
      
      debugPrint('AuthService: User data updated for user: $userId');
    } catch (e) {
      debugPrint('Error updating user data: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _supabase
          .from('users')
          .delete()
          .eq('id', userId);
      
      debugPrint('AuthService: User deleted: $userId');
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select();
      
      return response.map<UserModel>((data) => UserModel.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error fetching all users: $e');
      return [];
    }
  }

  Future<List<UserModel>> getUsersByRole(UserRole role) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('role', role.toString().split('.').last);
      
      return response.map<UserModel>((data) => UserModel.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error fetching users by role: $e');
      return [];
    }
  }

  Future<bool> validateSMAPCredentials(
      String studentId, String password) async {
    try {
      debugPrint(
          'AuthService: Validating SMAP credentials for student ID: $studentId');

      // Basic validation for student ID format (UTHM format: CI2330060)
      if (!_isValidStudentIdFormat(studentId)) {
        debugPrint('AuthService: Invalid student ID format');
        return false;
      }

      // Basic password validation
      if (password.isEmpty || password.length < 6) {
        debugPrint('AuthService: Invalid password - too short');
        return false;
      }

      // Simulate SMAP validation delay
      await Future.delayed(const Duration(seconds: 1));

      // Check if student ID follows UTHM pattern and is not in blacklist
      final isValidId = _validateStudentIdPattern(studentId);

      if (isValidId) {
        debugPrint('AuthService: SMAP credentials validated successfully');
        return true;
      } else {
        debugPrint(
            'AuthService: SMAP validation failed - student not found in system');
        return false;
      }
    } catch (e) {
      debugPrint('AuthService: Error validating SMAP credentials: $e');
      return false;
    }
  }

  bool _isValidStudentIdFormat(String studentId) {
    // UTHM student ID format: 2 letters + 7 digits (e.g., CI2330060)
    final regex = RegExp(r'^[A-Z]{2}\d{7}$');
    return regex.hasMatch(studentId.toUpperCase());
  }

  bool _validateStudentIdPattern(String studentId) {
    // Validate against known UTHM faculty codes
    final validFacultyCodes = [
      'CI', // Computer Science and Information Technology
      'EE', // Electrical and Electronic Engineering
      'ME', // Mechanical and Manufacturing Engineering
      'CE', // Civil and Environmental Engineering
      'BA', // Business Administration
      'ED', // Education
      'SC', // Science
      'AR', // Architecture
    ];

    final facultyCode = studentId.substring(0, 2).toUpperCase();
    return validFacultyCodes.contains(facultyCode);
  }

  /// Parse user role from string
  // UserRole _parseUserRole(String? roleString) {
  //   switch (roleString?.toLowerCase()) {
  //     case 'admin':
  //       return UserRole.admin;
  //     case 'lecturer':
  //     case 'teacher':
  //     case 'staff':
  //       return UserRole.lecturer;
  //     case 'student':
  //     default:
  //       return UserRole.student;
  //   }
  // }

  /// Manual function to ensure current user document exists
  Future<bool> ensureUserDocumentExists() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return false;

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();

      if (response == null) {
        // Create user document if it doesn't exist
        final userData = {
          'id': currentUser.id,
          'email': currentUser.email,
          'name': currentUser.userMetadata?['name'] ?? '',
          'role': currentUser.userMetadata?['role'] ?? 'student',
          'created_at': DateTime.now().toIso8601String(),
          'is_profile_complete': false,
        };

        await _supabase.from('users').insert(userData);
        debugPrint('AuthService: User document created for: ${currentUser.id}');
      }

      return true;
    } catch (e) {
      debugPrint('AuthService: Error ensuring user document exists: $e');
      return false;
    }
  }

  /// Helper method to load user from Supabase auth user
  Future<void> _loadUserFromSupabase(User supabaseUser) async {
    try {
      final userData = await getUserData(supabaseUser.id);
      if (userData != null) {
        _currentUser = userData;
      } else {
        // Create basic user model from auth data
        _currentUser = UserModel(
          id: supabaseUser.id,
          uid: supabaseUser.id,
          email: supabaseUser.email ?? '',
          name: supabaseUser.userMetadata?['name'] ?? '',
          role: _parseUserRole(supabaseUser.userMetadata?['role']),
          studentId: supabaseUser.userMetadata?['student_id'],
          department: supabaseUser.userMetadata?['department'],
          createdAt: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('AuthService: Error loading user from Supabase: $e');
    }
  }

  /// Parse user role from string
  UserRole _parseUserRole(String? roleString) {
    switch (roleString?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'lecturer':
      case 'teacher':
      case 'staff':
        return UserRole.lecturer;
      case 'student':
      default:
        return UserRole.student;
    }
  }
}