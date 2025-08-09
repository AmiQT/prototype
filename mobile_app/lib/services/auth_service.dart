import '../models/user_model.dart';
import '../services/profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  // Get the current Firebase Auth user
  User? get firebaseCurrentUser => FirebaseAuth.instance.currentUser;

  // Get current user ID from Firebase Auth
  String? get currentUserId {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('AuthService: Firebase Auth current user ID: $uid');
    return uid;
  }

  Future<void> initialize() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        debugPrint(
            'AuthService: Restoring user session for UID: ${firebaseUser.uid}');
        final userData = await getUserData(firebaseUser.uid);
        if (userData != null) {
          _currentUser = userData;
          debugPrint('AuthService: User session restored: ${userData.name}');
        } else {
          debugPrint(
              'AuthService: User data not found in Firestore for UID: ${firebaseUser.uid}');
          // Try to create user document from Firebase Auth data
          await _createUserDocumentFromFirebaseAuth(firebaseUser);
          // Try to get user data again
          final retryUserData = await getUserData(firebaseUser.uid);
          if (retryUserData != null) {
            _currentUser = retryUserData;
            debugPrint(
                'AuthService: User document created and session restored: ${retryUserData.name}');
          }
        }
      } else {
        debugPrint('AuthService: No authenticated user found');
      }
    } catch (e) {
      debugPrint('AuthService: Error initializing user session: $e');
    }
  }

  Future<UserModel> signInWithEmailAndPassword(
      String email, String password) async {
    debugPrint('AuthService: Attempting to sign in with email: $email');

    // Sign in with Firebase Auth
    final userCredential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = userCredential.user;
    debugPrint(
        'AuthService: Firebase Auth sign in successful, user ID: ${user!.uid}');

    // Fetch user data from Firestore
    final userData = await getUserData(user.uid);
    if (userData != null) {
      _currentUser = userData;
      debugPrint(
          'AuthService: User data fetched from Firestore: ${userData.name}');
      return userData;
    } else {
      debugPrint(
          'AuthService: No user data found in Firestore, creating basic user');
      // Create basic user data if Firestore data not found
      final loggedInUser = UserModel(
        id: user.uid,
        uid: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? 'New User',
        role: UserRole.student,
        studentId: '',
        department: '',
        createdAt: user.metadata.creationTime ?? DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      _currentUser = loggedInUser;
      return loggedInUser;
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
    // Create user in Firebase Auth
    final userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = userCredential.user;

    // Create user model
    final userModel = UserModel(
      id: user!.uid,
      uid: user.uid,
      email: email,
      name: name,
      role: role,
      studentId: studentId,
      department: department,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    // Save user data to Firestore (without password for security)
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'id': user.uid,
      'uid': user.uid,
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'studentId': studentId,
      'department': department,
      'createdAt': DateTime.now().toIso8601String(),
      'lastLoginAt': DateTime.now().toIso8601String(),
      'isActive': true,
      'profileCompleted': false,
    });

    _currentUser = userModel;
    return userModel;
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
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
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'profileCompleted': isComplete});
    } catch (e) {
      debugPrint('Error updating profile completion status: $e');
    }
  }

  Future<void> _createUserDocumentFromFirebaseAuth(User firebaseUser) async {
    try {
      debugPrint(
          'AuthService: Creating user document for UID: ${firebaseUser.uid}');

      // Create a basic user document with available Firebase Auth data
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .set({
        'id': firebaseUser.uid,
        'uid': firebaseUser.uid,
        'email': firebaseUser.email ?? '',
        'name': firebaseUser.displayName?.isNotEmpty == true
            ? firebaseUser.displayName!
            : firebaseUser.email?.split('@')[0] ?? 'User',
        'role': 'student', // Default role
        'studentId': '',
        'department': '',
        'createdAt': DateTime.now().toIso8601String(),
        'lastLoginAt': DateTime.now().toIso8601String(),
        'isActive': true,
        'profileCompleted': false,
      });

      debugPrint('AuthService: User document created successfully');
    } catch (e) {
      debugPrint('AuthService: Error creating user document: $e');
    }
  }

  Future<void> _fixEmptyUserName(
      String uid, Map<String, dynamic> userData) async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser?.uid != uid) {
        debugPrint('AuthService: Firebase user mismatch, cannot fix name');
        return;
      }

      String newName = 'User';

      // Try to get name from Firebase Auth display name
      if (firebaseUser!.displayName?.isNotEmpty == true) {
        newName = firebaseUser.displayName!;
      }
      // Try to extract from email
      else if (firebaseUser.email?.isNotEmpty == true) {
        newName = firebaseUser.email!.split('@')[0];
      }
      // Try to extract from existing email in userData
      else if (userData['email']?.toString().isNotEmpty == true) {
        newName = userData['email'].toString().split('@')[0];
      }

      debugPrint('AuthService: Updating user name to: $newName');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'name': newName});

      debugPrint('AuthService: User name updated successfully');
    } catch (e) {
      debugPrint('AuthService: Error fixing empty user name: $e');
    }
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      debugPrint('AuthService: Attempting to fetch user data for UID: $uid');
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      debugPrint('AuthService: Document exists: ${doc.exists}');
      if (doc.exists) {
        final data = doc.data()!;
        debugPrint('AuthService: User document data: $data');

        // Check if name is empty and fix it
        if (data['name'] == null || data['name'].toString().trim().isEmpty) {
          debugPrint('AuthService: Fixing empty name for user: $uid');
          await _fixEmptyUserName(uid, data);
          // Fetch the updated document
          final updatedDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();
          if (updatedDoc.exists) {
            final updatedData = updatedDoc.data()!;
            debugPrint('AuthService: Updated user document data: $updatedData');
            return UserModel.fromJson(updatedData);
          }
        }

        return UserModel.fromJson(data);
      } else {
        debugPrint('AuthService: No user document found for UID: $uid');
      }
      return null;
    } catch (e) {
      debugPrint('AuthService: Error fetching user data for UID $uid: $e');
      return null;
    }
  }

  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update(data);

      // Update current user if it's the same user
      if (_currentUser?.id == userId) {
        final updatedUser = await getUserData(userId);
        if (updatedUser != null) {
          _currentUser = updatedUser;
        }
      }
    } catch (e) {
      debugPrint('Error updating user data: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();

      // Clear current user if it's the same user
      if (_currentUser?.id == userId) {
        _currentUser = null;
      }
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      return querySnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching all users: $e');
      return [];
    }
  }

  Future<List<UserModel>> getUsersByRole(UserRole role) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: role.toString().split('.').last)
          .get();
      return querySnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();
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

      // In a real implementation, this would make an HTTP request to SMAP API
      // For prototype purposes, we'll validate based on student ID pattern
      // and accept any password that meets basic requirements

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
}
