import '../models/profile_model.dart';
import '../utils/error_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ProfileService {
  final CollectionReference profilesCollection =
      FirebaseFirestore.instance.collection('profiles');

  Future<void> saveProfile(ProfileModel profile) async {
    try {
      debugPrint(
          'ProfileService: Saving profile for userId: ${profile.userId}');
      debugPrint(
          'ProfileService: Profile image URL type: ${profile.profileImageUrl?.runtimeType}');
      if (profile.profileImageUrl != null) {
        debugPrint(
            'ProfileService: Profile image URL length: ${profile.profileImageUrl!.length}');
        debugPrint(
            'ProfileService: Profile image URL starts with: ${profile.profileImageUrl!.substring(0, profile.profileImageUrl!.length > 50 ? 50 : profile.profileImageUrl!.length)}');
      }

      // Validate profile data before saving
      if (profile.userId.isEmpty || profile.fullName.isEmpty) {
        throw Exception(
            'Profile data is incomplete. User ID and full name are required.');
      }

      // Check if profile already exists
      final existingProfile = await getProfileByUserId(profile.userId);

      if (existingProfile != null) {
        debugPrint(
            'ProfileService: Updating existing profile with userId: ${profile.userId}');
        // Update existing profile using the userId as document ID
        await profilesCollection
            .doc(profile.userId)
            .set(profile.copyWith(id: profile.userId).toJson());
      } else {
        debugPrint(
            'ProfileService: Creating new profile with userId: ${profile.userId}');
        // Create new profile using userId as document ID
        await profilesCollection
            .doc(profile.userId)
            .set(profile.copyWith(id: profile.userId).toJson());
      }

      debugPrint('ProfileService: Profile saved successfully to Firestore');
    } on FirebaseException catch (e) {
      debugPrint(
          'ProfileService: Firebase error saving profile: ${e.code} - ${e.message}');
      throw Exception(
          'Failed to save profile: ${ErrorHandler.getFirestoreErrorMessage(e)}');
    } catch (e) {
      debugPrint('ProfileService: Unexpected error saving profile: $e');
      throw Exception('Failed to save profile: ${e.toString()}');
    }
  }

  Future<ProfileModel?> getProfileByUserId(String userId) async {
    try {
      if (userId.isEmpty) {
        throw Exception('User ID cannot be empty');
      }

      debugPrint('ProfileService: Fetching profile for userId: $userId');

      // Get profile directly by document ID (which is now the userId)
      final doc = await profilesCollection.doc(userId).get();

      debugPrint('ProfileService: Document exists: ${doc.exists}');

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('ProfileService: Found profile for userId: $userId');
        return ProfileModel.fromJson(data);
      } else {
        debugPrint('ProfileService: No profile found for userId: $userId');
        return null;
      }
    } on FirebaseException catch (e) {
      debugPrint(
          'ProfileService: Firebase error fetching profile: ${e.code} - ${e.message}');
      throw Exception(
          'Failed to fetch profile: ${ErrorHandler.getFirestoreErrorMessage(e)}');
    } catch (e) {
      debugPrint('ProfileService: Unexpected error fetching profile: $e');
      throw Exception('Failed to fetch profile: ${e.toString()}');
    }
  }

  Future<ProfileModel?> getProfileById(String profileId) async {
    try {
      final doc = await profilesCollection.doc(profileId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return ProfileModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching profile by ID: $e');
      return null;
    }
  }

  Future<List<ProfileModel>> getAllProfiles() async {
    try {
      debugPrint('ProfileService: Fetching all profiles');

      final querySnapshot = await profilesCollection.get();
      final profiles = querySnapshot.docs
          .map((doc) =>
              ProfileModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      debugPrint('ProfileService: Found ${profiles.length} profiles');
      return profiles;
    } on FirebaseException catch (e) {
      debugPrint(
          'ProfileService: Firebase error fetching all profiles: ${e.code} - ${e.message}');
      throw Exception(
          'Failed to fetch profiles: ${ErrorHandler.getFirestoreErrorMessage(e)}');
    } catch (e) {
      debugPrint('ProfileService: Unexpected error fetching all profiles: $e');
      throw Exception('Failed to fetch profiles: ${e.toString()}');
    }
  }

  Future<List<ProfileModel>> getProfilesByDepartment(String department) async {
    try {
      final querySnapshot = await profilesCollection
          .where('department', isEqualTo: department)
          .get();
      return querySnapshot.docs
          .map((doc) =>
              ProfileModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching profiles by department: $e');
      return [];
    }
  }

  Future<List<ProfileModel>> searchProfiles(String query) async {
    try {
      final q = query.toLowerCase();
      final allProfiles = await getAllProfiles();
      return allProfiles
          .where((profile) =>
              profile.fullName.toLowerCase().contains(q) ||
              profile.studentId.toLowerCase().contains(q) ||
              profile.department.toLowerCase().contains(q) ||
              profile.program.toLowerCase().contains(q) ||
              profile.skills.any((skill) => skill.toLowerCase().contains(q)) ||
              profile.interests
                  .any((interest) => interest.toLowerCase().contains(q)))
          .toList();
    } catch (e) {
      debugPrint('Error searching profiles: $e');
      return [];
    }
  }

  Future<void> updateProfile(ProfileModel profile) async {
    try {
      await profilesCollection.doc(profile.userId).update(profile.toJson());
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  Future<void> deleteProfile(String profileId) async {
    try {
      await profilesCollection.doc(profileId).delete();
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
        departmentCounts[profile.department] =
            (departmentCounts[profile.department] ?? 0) + 1;
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
    return profilesCollection.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => ProfileModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList());
  }

  Stream<ProfileModel?> streamProfileByUserId(String userId) {
    return profilesCollection.doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        return ProfileModel.fromJson(data);
      }
      return null;
    });
  }
}
