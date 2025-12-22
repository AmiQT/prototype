import 'package:flutter/foundation.dart';
import '../services/settings_service.dart';
import '../models/user_model.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsService _settingsService = SettingsService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  // Clear messages
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String error) {
    _errorMessage = error;
    _successMessage = null;
    notifyListeners();
  }

  // Set success message
  void _setSuccess(String message) {
    _successMessage = message;
    _errorMessage = null;
    notifyListeners();
  }

  // Load user data
  Future<void> loadUserData() async {
    _setLoading(true);
    try {
      final userData = await _settingsService.getUserData();
      _currentUser = userData;
      clearMessages();
    } catch (e) {
      _setError('Failed to load user data: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    try {
      await _settingsService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _setSuccess('Password changed successfully');
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update email
  Future<bool> updateEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    _setLoading(true);
    try {
      await _settingsService.updateEmail(
        newEmail: newEmail,
        currentPassword: currentPassword,
      );
      
      // Reload user data to reflect changes
      await loadUserData();
      _setSuccess('Email updated successfully');
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update display name
  Future<bool> updateDisplayName(String newName) async {
    _setLoading(true);
    try {
      await _settingsService.updateDisplayName(newName);
      
      // Reload user data to reflect changes
      await loadUserData();
      _setSuccess('Name updated successfully');
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    String? name,
    String? department,
    String? studentId,
  }) async {
    _setLoading(true);
    try {
      await _settingsService.updateUserProfile(
        name: name,
        department: department,
        studentId: studentId,
      );
      
      // Reload user data to reflect changes
      await loadUserData();
      _setSuccess('Profile updated successfully');
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    try {
      await _settingsService.sendPasswordResetEmail(email);
      _setSuccess('Password reset email sent successfully');
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete account
  Future<bool> deleteAccount(String currentPassword) async {
    _setLoading(true);
    try {
      await _settingsService.deleteAccount(currentPassword);
      _setSuccess('Account deleted successfully');
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
