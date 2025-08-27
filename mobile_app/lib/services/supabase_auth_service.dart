import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../config/supabase_config.dart';

class SupabaseAuthService {
  static const String baseUrl =
      'https://prototype-348e.onrender.com'; // Render backend

  UserModel? _currentUser;

  // Getters
  UserModel? get currentUser => _currentUser;
  User? get supabaseUser => SupabaseConfig.auth.currentUser;
  String? get currentUserId => supabaseUser?.id;

  // Get Supabase auth token for backend API calls
  Future<String?> getAuthToken() async {
    try {
      final session = SupabaseConfig.auth.currentSession;
      if (session?.accessToken != null) {
        debugPrint(
            'SupabaseAuthService: Got auth token for user: ${session!.user.id}');
        return session.accessToken;
      } else {
        debugPrint('SupabaseAuthService: No active session found');
        return null;
      }
    } catch (e) {
      debugPrint('SupabaseAuthService: Error getting auth token: $e');
      return null;
    }
  }

  // Initialize service and restore session
  Future<void> initialize() async {
    try {
      debugPrint('SupabaseAuthService: Initializing...');

      // Check if user is already signed in
      final session = SupabaseConfig.auth.currentSession;
      if (session != null) {
        debugPrint(
            'SupabaseAuthService: Found existing session for user: ${session.user.id}');
        debugPrint(
            'SupabaseAuthService: Session expires at: ${session.expiresAt}');
        debugPrint(
            'SupabaseAuthService: Session is valid: ${!session.isExpired}');

        // Only load profile if session is valid
        if (!session.isExpired) {
          await _loadUserProfile(session.user.id);
          debugPrint(
              'SupabaseAuthService: Session restored successfully for user: ${session.user.id}');
        } else {
          debugPrint(
              'SupabaseAuthService: Session expired, clearing user data');
          _currentUser = null;
        }
      } else {
        debugPrint('SupabaseAuthService: No existing session found');
      }

      // Listen to auth state changes
      SupabaseConfig.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;

        debugPrint('SupabaseAuthService: Auth state changed: $event');

        switch (event) {
          case AuthChangeEvent.signedIn:
            if (session?.user != null) {
              debugPrint(
                  'SupabaseAuthService: User signed in: ${session!.user.id}');
              _loadUserProfile(session.user.id);
            }
            break;
          case AuthChangeEvent.signedOut:
            debugPrint('SupabaseAuthService: User signed out');
            _currentUser = null;
            break;
          case AuthChangeEvent.tokenRefreshed:
            debugPrint('SupabaseAuthService: Token refreshed');
            break;
          case AuthChangeEvent.initialSession:
            if (session?.user != null) {
              debugPrint(
                  'SupabaseAuthService: Initial session restored: ${session!.user.id}');
              _loadUserProfile(session.user.id);
            }
            break;
          default:
            debugPrint('SupabaseAuthService: Unhandled auth event: $event');
            break;
        }
      });
    } catch (e) {
      debugPrint('SupabaseAuthService: Error during initialization: $e');
    }
  }

  // Sign in with email and password
  Future<UserModel> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      debugPrint(
          'SupabaseAuthService: Attempting to sign in with email: $email');

      final response = await SupabaseConfig.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        debugPrint(
            'SupabaseAuthService: Sign in successful for user: ${response.user!.id}');

        // Load user profile from your backend or Supabase
        await _loadUserProfile(response.user!.id);

        if (_currentUser != null) {
          return _currentUser!;
        } else {
          // Create basic user model if profile doesn't exist
          _currentUser = UserModel(
            id: response.user!.id,
            uid: response.user!.id,
            email: response.user!.email ?? email,
            name: response.user!.email?.split('@')[0] ?? 'User',
            role: UserRole.student,
            createdAt: DateTime.now(),
            isActive: true,
            profileCompleted: false, // New users don't have completed profiles
          );

          // Ensure user exists in Supabase
          await _ensureUserInSupabase(
            response.user!.id,
            response.user!.email ?? email,
            response.user!.email?.split('@')[0] ?? 'User',
            UserRole.student,
          );
        }

        return _currentUser!;
      } else {
        throw Exception('Sign in failed: No user returned');
      }
    } catch (e) {
      debugPrint('SupabaseAuthService: Sign in error: $e');
      rethrow;
    }
  }

  // Register with email and password
  Future<UserModel> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    UserRole role, {
    String? studentId,
    String? department,
  }) async {
    try {
      debugPrint('SupabaseAuthService: Attempting to register user: $email');

      final response = await SupabaseConfig.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': role.toString().split('.').last,
          'student_id': studentId,
          'department': department,
        },
      );

      if (response.user != null) {
        debugPrint(
            'SupabaseAuthService: Registration successful for user: ${response.user!.id}');

        // Create user profile in your backend
        final userModel = UserModel(
          id: response.user!.id,
          uid: response.user!.id,
          email: email,
          name: name,
          role: role,
          studentId: studentId,
          department: department,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          isActive: true,
          profileCompleted:
              false, // Newly registered users don't have completed profiles
        );

        // Save to backend if needed
        await _createUserInBackend(userModel);

        // Also create user in Supabase
        await _ensureUserInSupabase(response.user!.id, email, name, role);

        _currentUser = userModel;
        return userModel;
      } else {
        throw Exception('Registration failed: No user returned');
      }
    } catch (e) {
      debugPrint('SupabaseAuthService: Registration error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await SupabaseConfig.auth.signOut();
      _currentUser = null;
      debugPrint('SupabaseAuthService: User signed out successfully');
    } catch (e) {
      debugPrint('SupabaseAuthService: Sign out error: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await SupabaseConfig.auth.resetPasswordForEmail(email);
      debugPrint('SupabaseAuthService: Password reset email sent to: $email');
    } catch (e) {
      debugPrint('SupabaseAuthService: Password reset error: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      await SupabaseConfig.auth.updateUser(
        UserAttributes(
          data: updates,
        ),
      );

      // Update profile completion status in Supabase if provided
      if (updates.containsKey('profileCompleted')) {
        final userId = currentUserId;
        if (userId != null) {
          try {
            // Update users table
            await SupabaseConfig.client.from('users').upsert({
              'id': userId,
              'profile_completed': updates['profileCompleted'],
              'updated_at': DateTime.now().toIso8601String(),
            });

            // Update profiles table if it exists
            try {
              await SupabaseConfig.client.from('profiles').upsert({
                'user_id': userId,
                'is_profile_complete': updates['profileCompleted'],
                'updated_at': DateTime.now().toIso8601String(),
              });
            } catch (e) {
              debugPrint(
                  'SupabaseAuthService: Profiles table update failed: $e');
            }
          } catch (e) {
            debugPrint('SupabaseAuthService: Supabase update failed: $e');
          }
        }
      }

      // Reload user profile
      if (currentUserId != null) {
        await _loadUserProfile(currentUserId!);
      }

      debugPrint('SupabaseAuthService: User profile updated successfully');
    } catch (e) {
      debugPrint('SupabaseAuthService: Profile update error: $e');
      rethrow;
    }
  }

  // Load user profile from backend or Supabase
  Future<void> _loadUserProfile(String userId) async {
    try {
      // Option 1: Load from your backend
      final userData = await _getUserFromBackend(userId);
      if (userData != null) {
        _currentUser = userData;
        return;
      }

      // Option 2: Load from Supabase user metadata and check profile completion
      final supabaseUser = SupabaseConfig.auth.currentUser;
      if (supabaseUser != null) {
        // Check if user has a profile in Supabase
        bool profileCompleted = false;

        // Try to check profile completion from profiles table
        try {
          final profileResponse = await SupabaseConfig.client
              .from('profiles')
              .select('is_profile_complete')
              .eq('user_id', userId)
              .single();

          if (profileResponse['is_profile_complete'] != null) {
            profileCompleted = profileResponse['is_profile_complete'] as bool;
            debugPrint(
                'SupabaseAuthService: Profile completion from profiles table: $profileCompleted');
          }
        } catch (e) {
          debugPrint('SupabaseAuthService: Cannot access profiles table: $e');

          // If permission denied or table access issue, assume profile incomplete
          if (e.toString().contains('permission denied') ||
              e.toString().contains('42501')) {
            debugPrint(
                'SupabaseAuthService: Permission issue with profiles table, assuming profile incomplete');
            profileCompleted = false;
          }
        }

        // Also try to check users table if profile not found
        if (!profileCompleted) {
          try {
            final userResponse = await SupabaseConfig.client
                .from('users')
                .select('profile_completed')
                .eq('id', userId)
                .single();

            if (userResponse['profile_completed'] != null) {
              profileCompleted = userResponse['profile_completed'] as bool;
              debugPrint(
                  'SupabaseAuthService: Profile completion from users table: $profileCompleted');
            }
          } catch (e) {
            debugPrint('SupabaseAuthService: Cannot access users table: $e');

            // If permission denied, assume profile incomplete and continue
            if (e.toString().contains('permission denied') ||
                e.toString().contains('42501')) {
              debugPrint(
                  'SupabaseAuthService: Permission issue with users table, assuming profile incomplete');
              profileCompleted = false;
            }
          }
        }

        _currentUser = UserModel(
          id: supabaseUser.id,
          uid: supabaseUser.id,
          email: supabaseUser.email ?? '',
          name: supabaseUser.userMetadata?['name'] ?? 'User',
          role: _parseUserRole(supabaseUser.userMetadata?['role']),
          studentId: supabaseUser.userMetadata?['student_id'],
          department: supabaseUser.userMetadata?['department'],
          createdAt: DateTime.parse(supabaseUser.createdAt.toString()),
          lastLoginAt: DateTime.now(),
          isActive: true,
          profileCompleted: profileCompleted,
        );
      }
    } catch (e) {
      debugPrint('SupabaseAuthService: Error loading user profile: $e');
    }
  }

  // Get user from your backend
  Future<UserModel?> _getUserFromBackend(String userId) async {
    try {
      final token = await getAuthToken();
      if (token == null) return null;

      // Get user data directly from users table
      final response = await SupabaseConfig.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      if (response != null) {
        return UserModel.fromJson(response);
      }
    } catch (e) {
      debugPrint('SupabaseAuthService: Error getting user from backend: $e');
    }
    return null;
  }

  // Create user in your backend
  Future<void> _createUserInBackend(UserModel user) async {
    try {
      final token = await getAuthToken();
      if (token == null) return;

      // Create user in your backend database
      await SupabaseConfig.client.functions.invoke(
        'create-user',
        body: user.toJson(),
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint('SupabaseAuthService: User created in backend successfully');
    } catch (e) {
      debugPrint('SupabaseAuthService: Error creating user in backend: $e');
    }
  }

  // Create user in Supabase if they don't exist
  Future<void> _ensureUserInSupabase(
      String userId, String email, String name, UserRole role) async {
    try {
      // Check if user exists in users table
      try {
        await SupabaseConfig.client
            .from('users')
            .select('id')
            .eq('id', userId)
            .single();
        // User exists, no need to create
        debugPrint(
            'SupabaseAuthService: User already exists in Supabase: $userId');
        return;
      } catch (e) {
        debugPrint('SupabaseAuthService: User check error: $e');

        // If permission denied, skip user creation for now
        if (e.toString().contains('permission denied') ||
            e.toString().contains('42501')) {
          debugPrint(
              'SupabaseAuthService: Permission denied for user check, skipping user creation');
          return;
        }

        // User doesn't exist, create them
        debugPrint(
            'SupabaseAuthService: Creating new user in Supabase: $userId');
      }

      // Create user in users table
      try {
        await SupabaseConfig.client.from('users').insert({
          'id': userId,
          'email': email,
          'name': name,
          'role': role.toString().split('.').last,
          'is_active': true,
          'profile_completed': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        debugPrint(
            'SupabaseAuthService: User created successfully in Supabase');
      } catch (e) {
        debugPrint('SupabaseAuthService: Error creating user in Supabase: $e');

        // If permission denied, just log and continue
        if (e.toString().contains('permission denied') ||
            e.toString().contains('42501')) {
          debugPrint(
              'SupabaseAuthService: Permission denied for user creation, continuing without Supabase user record');
        }
      }

      debugPrint('SupabaseAuthService: User created in Supabase successfully');
    } catch (e) {
      debugPrint('SupabaseAuthService: Error creating user in Supabase: $e');
    }
  }

  // Validate SMAP credentials (keep your existing logic)
  Future<bool> validateSMAPCredentials(
      String studentId, String password) async {
    try {
      debugPrint(
          'SupabaseAuthService: Validating SMAP credentials for: $studentId');

      // Your existing SMAP validation logic
      if (!_isValidStudentIdFormat(studentId)) {
        return false;
      }

      if (password.isEmpty || password.length < 6) {
        return false;
      }

      await Future.delayed(const Duration(seconds: 1));
      return _validateStudentIdPattern(studentId);
    } catch (e) {
      debugPrint('SupabaseAuthService: SMAP validation error: $e');
      return false;
    }
  }

  // Helper methods (keep your existing logic)
  bool _isValidStudentIdFormat(String studentId) {
    final regex = RegExp(r'^[A-Z]{2}\d{7}$');
    return regex.hasMatch(studentId.toUpperCase());
  }

  bool _validateStudentIdPattern(String studentId) {
    final validFacultyCodes = ['CI', 'EE', 'ME', 'CE', 'BA', 'ED', 'SC', 'AR'];
    final facultyCode = studentId.substring(0, 2).toUpperCase();
    return validFacultyCodes.contains(facultyCode);
  }

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

  // Check if user has completed profile
  Future<bool> hasCompletedProfile(String userId) async {
    try {
      // Check if current user has a completed profile
      if (_currentUser != null && _currentUser!.uid == userId) {
        return _currentUser!.profileCompleted;
      }

      // Try to get profile from Supabase profiles table
      try {
        final response = await SupabaseConfig.client
            .from('profiles')
            .select('is_profile_complete')
            .eq('user_id', userId)
            .single();

        if (response['is_profile_complete'] != null) {
          return response['is_profile_complete'] as bool;
        }
      } catch (e) {
        debugPrint('SupabaseAuthService: No profile found in Supabase: $e');
      }

      // Try to get user from Supabase users table
      try {
        final response = await SupabaseConfig.client
            .from('users')
            .select('profile_completed')
            .eq('id', userId)
            .single();

        if (response['profile_completed'] != null) {
          return response['profile_completed'] as bool;
        }
      } catch (e) {
        debugPrint('SupabaseAuthService: No user found in Supabase: $e');
      }

      // If we can't get user data, assume profile is not complete
      return false;
    } catch (e) {
      debugPrint('SupabaseAuthService: Error checking profile completion: $e');
      return false;
    }
  }

  // Get all users (admin function)
  Future<List<UserModel>> getAllUsers() async {
    try {
      debugPrint('SupabaseAuthService: Getting all users');

      // This would typically fetch from your backend or Supabase users table
      // For now, return empty list as a placeholder
      return [];
    } catch (e) {
      debugPrint('SupabaseAuthService: Error getting all users: $e');
      return [];
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      debugPrint('SupabaseAuthService: Getting user by ID: $userId');

      // This would typically fetch from your backend or Supabase users table
      // For now, return null as a placeholder
      return null;
    } catch (e) {
      debugPrint('SupabaseAuthService: Error getting user by ID: $e');
      return null;
    }
  }

  // Get user data (alias for getUserById for compatibility)
  Future<UserModel?> getUserData(String uid) async {
    return await getUserById(uid);
  }

  // Check if user should stay logged in
  bool get shouldStayLoggedIn {
    final session = SupabaseConfig.auth.currentSession;
    if (session == null) return false;

    // Check if session is expired
    if (session.isExpired) return false;

    // Check if we have user data
    if (_currentUser == null) return false;

    return true;
  }

  // Get current session info for debugging
  Map<String, dynamic> get sessionInfo {
    final session = SupabaseConfig.auth.currentSession;
    if (session == null) {
      return {'status': 'no_session'};
    }

    return {
      'status': 'active',
      'user_id': session.user.id,
      'expires_at': session.expiresAt?.toString(),
      'is_expired': session.isExpired,
      'has_user_data': _currentUser != null,
      'current_user_id': _currentUser?.id,
    };
  }
}
