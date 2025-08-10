import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class SettingsService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  /// Change user password
  /// Requires current password for security verification
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      debugPrint('SettingsService: Password updated successfully');
    } on FirebaseAuthException catch (e) {
      debugPrint(
          'SettingsService: Firebase Auth error changing password: ${e.code} - ${e.message}');

      switch (e.code) {
        case 'wrong-password':
          throw Exception('Current password is incorrect');
        case 'weak-password':
          throw Exception(
              'New password is too weak. Please choose a stronger password');
        case 'requires-recent-login':
          throw Exception(
              'Please log out and log back in before changing your password');
        default:
          throw Exception('Failed to change password: ${e.message}');
      }
    } catch (e) {
      debugPrint('SettingsService: Unexpected error changing password: $e');
      throw Exception('Failed to change password: ${e.toString()}');
    }
  }

  /// Update user email
  /// Requires current password for security verification
  Future<void> updateEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update email using the new recommended method
      await user.verifyBeforeUpdateEmail(newEmail);

      // Update email in Firestore user document
      await _firestore.collection('users').doc(user.uid).update({
        'email': newEmail,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      debugPrint('SettingsService: Email updated successfully');
    } on FirebaseAuthException catch (e) {
      debugPrint(
          'SettingsService: Firebase Auth error updating email: ${e.code} - ${e.message}');

      switch (e.code) {
        case 'wrong-password':
          throw Exception('Current password is incorrect');
        case 'email-already-in-use':
          throw Exception('This email is already in use by another account');
        case 'invalid-email':
          throw Exception('Please enter a valid email address');
        case 'requires-recent-login':
          throw Exception(
              'Please log out and log back in before changing your email');
        default:
          throw Exception('Failed to update email: ${e.message}');
      }
    } catch (e) {
      debugPrint('SettingsService: Unexpected error updating email: $e');
      throw Exception('Failed to update email: ${e.toString()}');
    }
  }

  /// Update user display name
  Future<void> updateDisplayName(String newName) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      // Update display name in Firebase Auth
      await user.updateDisplayName(newName);

      // Update name in Firestore user document
      await _firestore.collection('users').doc(user.uid).update({
        'name': newName,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      debugPrint('SettingsService: Display name updated successfully');
    } catch (e) {
      debugPrint('SettingsService: Error updating display name: $e');
      throw Exception('Failed to update name: ${e.toString()}');
    }
  }

  /// Update user profile information in Firestore
  Future<void> updateUserProfile({
    String? name,
    String? department,
    String? studentId,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      final Map<String, dynamic> updates = {
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name;
      if (department != null) updates['department'] = department;
      if (studentId != null) updates['studentId'] = studentId;

      await _firestore.collection('users').doc(user.uid).update(updates);

      // Also update display name in Firebase Auth if name is provided
      if (name != null) {
        await user.updateDisplayName(name);
      }

      debugPrint('SettingsService: User profile updated successfully');
    } catch (e) {
      debugPrint('SettingsService: Error updating user profile: $e');
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  /// Get user data from Firestore
  Future<UserModel?> getUserData() async {
    try {
      final user = currentUser;
      if (user == null) {
        return null;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('SettingsService: Error fetching user data: $e');
      return null;
    }
  }

  /// Delete user account
  /// Requires current password for security verification
  Future<void> deleteAccount(String currentPassword) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Delete user data from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete user profile if exists
      final profileQuery = await _firestore
          .collection('profiles')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (final doc in profileQuery.docs) {
        await doc.reference.delete();
      }

      // Delete Firebase Auth account
      await user.delete();

      debugPrint('SettingsService: Account deleted successfully');
    } on FirebaseAuthException catch (e) {
      debugPrint(
          'SettingsService: Firebase Auth error deleting account: ${e.code} - ${e.message}');

      switch (e.code) {
        case 'wrong-password':
          throw Exception('Current password is incorrect');
        case 'requires-recent-login':
          throw Exception(
              'Please log out and log back in before deleting your account');
        default:
          throw Exception('Failed to delete account: ${e.message}');
      }
    } catch (e) {
      debugPrint('SettingsService: Unexpected error deleting account: $e');
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('SettingsService: Password reset email sent successfully');
    } on FirebaseAuthException catch (e) {
      debugPrint(
          'SettingsService: Firebase Auth error sending password reset: ${e.code} - ${e.message}');

      switch (e.code) {
        case 'user-not-found':
          throw Exception('No account found with this email address');
        case 'invalid-email':
          throw Exception('Please enter a valid email address');
        default:
          throw Exception('Failed to send password reset email: ${e.message}');
      }
    } catch (e) {
      debugPrint(
          'SettingsService: Unexpected error sending password reset: $e');
      throw Exception('Failed to send password reset email: ${e.toString()}');
    }
  }
}
