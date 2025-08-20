/*
 * 🚧 FIREBASE MIGRATION IN PROGRESS 🚧
 * This service is being migrated from Firebase to Supabase
 * Some functionality may be temporarily disabled
 * TODO: Complete Supabase integration
 */

import '../models/user_model.dart';
import 'profile_service.dart';
// Firebase imports removed - migrating to Supabase
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static const String baseUrl = 'https://c3168f89d034.ngrok-free.app'; // ngrok tunnel
  UserModel? _currentUser;
  
  // Get auth token - will be updated for Supabase
  // Future<String?> _getAuthToken() async {
  //   // TODO: Replace with Supabase auth token
  //   debugPrint('AuthService: Auth token method needs Supabase implementation');
  //   return null;
  // }

  UserModel? get currentUser => _currentUser;

  // TODO: Replace with Supabase auth user
  // User? get firebaseCurrentUser => FirebaseAuth.instance.currentUser;

  // Get current user ID - will be updated for Supabase
  String? get currentUserId {
    // TODO: Replace with Supabase user ID
    debugPrint('AuthService: Current user ID method needs Supabase implementation');
    return _currentUser?.id;
  }

  Future<void> initialize() async {
    try {
      // TODO: Replace with Supabase session restoration
      debugPrint('AuthService: Initialize method needs Supabase implementation');
      
      // Placeholder for Supabase session check
      // final session = Supabase.instance.client.auth.currentSession;
      // if (session != null) {
      //   // Restore user session
      // }
      
    } catch (e) {
      debugPrint('AuthService: Error initializing user session: $e');
    }
  }

  Future<UserModel> signInWithEmailAndPassword(
      String email, String password) async {
    debugPrint('AuthService: Attempting to sign in with email: $email');

    // TODO: Replace with Supabase auth
    /*
    final response = await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    */
    
    throw UnimplementedError('Supabase authentication not yet implemented');
  }

  Future<UserModel> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    UserRole role, {
    String? studentId,
    String? department,
  }) async {
    
    // TODO: Replace with Supabase auth
    /*
    final response = await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
    );
    */
    
    throw UnimplementedError('Supabase registration not yet implemented');
  }

  Future<void> signOut() async {
    // TODO: Replace with Supabase signOut
    // await Supabase.instance.client.auth.signOut();
    _currentUser = null;
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
      // TODO: Replace with Supabase database update
      debugPrint('AuthService: Profile completion update needs Supabase implementation');
    } catch (e) {
      debugPrint('Error updating profile completion status: $e');
    }
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      debugPrint('AuthService: Attempting to fetch user data for UID: $uid');
      
      // TODO: Replace with Supabase database query
      /*
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', uid)
          .single();
      
      if (response != null) {
        return UserModel.fromJson(response);
      }
      */
      
      debugPrint('AuthService: getUserData needs Supabase implementation');
      return null;
    } catch (e) {
      debugPrint('AuthService: Error fetching user data for UID $uid: $e');
      return null;
    }
  }

  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      // TODO: Replace with Supabase database update
      /*
      await Supabase.instance.client
          .from('users')
          .update(data)
          .eq('id', userId);
      */
      
      debugPrint('AuthService: updateUserData needs Supabase implementation');
    } catch (e) {
      debugPrint('Error updating user data: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      // TODO: Replace with Supabase database delete
      /*
      await Supabase.instance.client
          .from('users')
          .delete()
          .eq('id', userId);
      */
      
      debugPrint('AuthService: deleteUser needs Supabase implementation');
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      // TODO: Replace with Supabase database query
      /*
      final response = await Supabase.instance.client
          .from('users')
          .select();
      
      return response.map((data) => UserModel.fromJson(data)).toList();
      */
      
      debugPrint('AuthService: getAllUsers needs Supabase implementation');
      return [];
    } catch (e) {
      debugPrint('Error fetching all users: $e');
      return [];
    }
  }

  Future<List<UserModel>> getUsersByRole(UserRole role) async {
    try {
      // TODO: Replace with Supabase database query
      /*
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('role', role.toString().split('.').last);
      
      return response.map((data) => UserModel.fromJson(data)).toList();
      */
      
      debugPrint('AuthService: getUsersByRole needs Supabase implementation');
      return [];
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
      // TODO: Replace with Supabase user check
      debugPrint('AuthService: ensureUserDocumentExists needs Supabase implementation');
      return true;
    } catch (e) {
      debugPrint('AuthService: Error ensuring user document exists: $e');
      return false;
    }
  }
}