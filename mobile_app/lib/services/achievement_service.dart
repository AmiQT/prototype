import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/achievement_model.dart';
import '../utils/error_handler.dart';
import 'auto_notification_service.dart';
import 'dart:io';

class AchievementService {
  final CollectionReference achievementsCollection =
      FirebaseFirestore.instance.collection('achievements');

  Stream<List<AchievementModel>> streamAllAchievements() {
    return achievementsCollection.snapshots().map((snapshot) => snapshot.docs
        .map((doc) =>
            AchievementModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList());
  }

  Future<List<AchievementModel>> getAllAchievements() async {
    try {
      debugPrint('AchievementService: Fetching all achievements');

      final querySnapshot = await achievementsCollection.get();
      final achievements = querySnapshot.docs
          .map((doc) =>
              AchievementModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      debugPrint(
          'AchievementService: Found ${achievements.length} achievements');
      return achievements;
    } on FirebaseException catch (e) {
      debugPrint(
          'AchievementService: Firebase error fetching achievements: ${e.code} - ${e.message}');
      throw Exception(
          'Failed to fetch achievements: ${ErrorHandler.getFirestoreErrorMessage(e)}');
    } catch (e) {
      debugPrint(
          'AchievementService: Unexpected error fetching achievements: $e');
      throw Exception('Failed to fetch achievements: ${e.toString()}');
    }
  }

  Future<List<AchievementModel>> getAchievementsByUserId(String userId) async {
    try {
      final querySnapshot =
          await achievementsCollection.where('userId', isEqualTo: userId).get();
      return querySnapshot.docs
          .map((doc) =>
              AchievementModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching achievements by user ID: $e');
      return [];
    }
  }

  Future<void> createAchievement(AchievementModel achievement) async {
    try {
      // Validate achievement data
      if (achievement.title.isEmpty || achievement.userId.isEmpty) {
        throw Exception('Achievement title and user ID are required');
      }

      debugPrint(
          'AchievementService: Creating achievement: ${achievement.title}');

      await achievementsCollection
          .doc(achievement.id)
          .set(achievement.toJson());

      // Create notification for achievement submission
      await AutoNotificationService.onMilestoneAchieved(
        userId: achievement.userId,
        milestoneTitle: 'Achievement Submitted',
        description:
            'Your achievement "${achievement.title}" has been submitted for verification.',
      );

      debugPrint('AchievementService: Achievement created successfully');
    } on FirebaseException catch (e) {
      debugPrint(
          'AchievementService: Firebase error creating achievement: ${e.code} - ${e.message}');
      throw Exception(
          'Failed to create achievement: ${ErrorHandler.getFirestoreErrorMessage(e)}');
    } catch (e) {
      debugPrint(
          'AchievementService: Unexpected error creating achievement: $e');
      throw Exception('Failed to create achievement: ${e.toString()}');
    }
  }

  Future<void> updateAchievement(AchievementModel achievement) async {
    try {
      await achievementsCollection
          .doc(achievement.id)
          .update(achievement.toJson());
    } catch (e) {
      debugPrint('Error updating achievement: $e');
      rethrow;
    }
  }

  Future<void> deleteAchievement(String achievementId) async {
    try {
      await achievementsCollection.doc(achievementId).delete();
    } catch (e) {
      debugPrint('Error deleting achievement: $e');
      rethrow;
    }
  }

  Future<AchievementModel?> getAchievementById(String achievementId) async {
    try {
      final doc = await achievementsCollection.doc(achievementId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return AchievementModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching achievement by ID: $e');
      return null;
    }
  }

  Future<List<AchievementModel>> getAchievementsByType(
      AchievementType type) async {
    try {
      final querySnapshot = await achievementsCollection
          .where('type', isEqualTo: type.toString().split('.').last)
          .get();
      return querySnapshot.docs
          .map((doc) =>
              AchievementModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching achievements by type: $e');
      return [];
    }
  }

  Future<List<AchievementModel>> searchAchievements(String query) async {
    try {
      final q = query.toLowerCase();
      final allAchievements = await getAllAchievements();
      return allAchievements
          .where((a) =>
              a.title.toLowerCase().contains(q) ||
              a.description.toLowerCase().contains(q) ||
              (a.organization?.toLowerCase().contains(q) ?? false))
          .toList();
    } catch (e) {
      debugPrint('Error searching achievements: $e');
      return [];
    }
  }

  Future<List<AchievementModel>> getPendingVerifications() async {
    try {
      final querySnapshot = await achievementsCollection
          .where('isVerified', isEqualTo: false)
          .get();
      return querySnapshot.docs
          .map((doc) =>
              AchievementModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching pending verifications: $e');
      return [];
    }
  }

  Future<void> verifyAchievement(
      String achievementId, String verifiedBy) async {
    try {
      // Get achievement details first
      final achievementDoc =
          await achievementsCollection.doc(achievementId).get();
      if (!achievementDoc.exists) {
        throw Exception('Achievement not found');
      }

      final achievementData = achievementDoc.data() as Map<String, dynamic>;
      final achievement = AchievementModel.fromJson(achievementData);

      await achievementsCollection.doc(achievementId).update({
        'isVerified': true,
        'verifiedBy': verifiedBy,
        'verifiedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Create notification for achievement verification
      await AutoNotificationService.onMilestoneAchieved(
        userId: achievement.userId,
        milestoneTitle: 'Achievement Verified! 🎉',
        description:
            'Your achievement "${achievement.title}" has been verified by $verifiedBy.',
      );

      // Check for milestone achievements
      await _checkForMilestones(achievement.userId);
    } catch (e) {
      debugPrint('Error verifying achievement: $e');
      rethrow;
    }
  }

  Future<void> rejectAchievement(
      String achievementId, String rejectedBy, String reason) async {
    try {
      await achievementsCollection.doc(achievementId).update({
        'isVerified': false,
        'rejectedBy': rejectedBy,
        'rejectedAt': DateTime.now().toIso8601String(),
        'rejectionReason': reason,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error rejecting achievement: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAchievementStats() async {
    try {
      final allAchievements = await getAllAchievements();

      // Count by type
      final typeCounts = <String, int>{};
      for (var achievement in allAchievements) {
        final type = achievement.type.toString().split('.').last;
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      }

      // Count verified vs unverified
      final verifiedCount = allAchievements.where((a) => a.isVerified).length;
      final unverifiedCount = allAchievements.length - verifiedCount;

      // Total points
      final totalPoints = allAchievements
          .where((a) => a.isVerified)
          .fold(0, (accumulator, a) => accumulator + (a.points ?? 0));

      return {
        'totalAchievements': allAchievements.length,
        'verifiedAchievements': verifiedCount,
        'unverifiedAchievements': unverifiedCount,
        'totalPoints': totalPoints,
        'typeCounts': typeCounts,
      };
    } catch (e) {
      debugPrint('Error getting achievement stats: $e');
      return {
        'totalAchievements': 0,
        'verifiedAchievements': 0,
        'unverifiedAchievements': 0,
        'totalPoints': 0,
        'typeCounts': {},
      };
    }
  }

  Stream<List<AchievementModel>> streamAchievementsByUserId(String userId) {
    return achievementsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                AchievementModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Stream<List<AchievementModel>> streamPendingVerifications() {
    return achievementsCollection
        .where('isVerified', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                AchievementModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Upload certificate file
  Future<String> uploadCertificate(String userId, File file) async {
    try {
      debugPrint(
          'AchievementService: Uploading certificate for user $userId from: ${file.path}');

      // Create a unique filename
      final fileName =
          'certificates/${userId}_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = await ref.putFile(file);

      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      debugPrint(
          'AchievementService: Certificate uploaded successfully: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      debugPrint('AchievementService: Error uploading certificate: $e');
      rethrow;
    }
  }

  /// Upload achievement image
  Future<String> uploadAchievementImage(String userId, File file) async {
    try {
      debugPrint(
          'AchievementService: Uploading achievement image for user $userId from: ${file.path}');

      // Create a unique filename
      final fileName =
          'achievement_images/${userId}_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = await ref.putFile(file);

      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      debugPrint(
          'AchievementService: Achievement image uploaded successfully: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      debugPrint('AchievementService: Error uploading achievement image: $e');
      rethrow;
    }
  }

  /// Get default points for achievement type
  int getDefaultPoints(AchievementType type) {
    switch (type) {
      case AchievementType.academic:
        return 10;
      case AchievementType.competition:
        return 15;
      case AchievementType.leadership:
        return 12;
      case AchievementType.skill:
        return 8;
      case AchievementType.other:
        return 5;
    }
  }

  /// Check for milestone achievements and create notifications
  Future<void> _checkForMilestones(String userId) async {
    try {
      final userAchievements = await getAchievementsByUserId(userId);
      final verifiedAchievements =
          userAchievements.where((a) => a.isVerified).toList();

      final totalPoints =
          verifiedAchievements.fold(0, (total, a) => total + (a.points ?? 0));
      final achievementCount = verifiedAchievements.length;

      // Check for point milestones
      final pointMilestones = [50, 100, 200, 500, 1000];
      for (final milestone in pointMilestones) {
        if (totalPoints >= milestone &&
            totalPoints - (verifiedAchievements.last.points ?? 0) < milestone) {
          await AutoNotificationService.onMilestoneAchieved(
            userId: userId,
            milestoneTitle: 'Points Milestone Reached! 🌟',
            description:
                'Congratulations! You\'ve earned $milestone points total!',
          );
        }
      }

      // Check for achievement count milestones
      final countMilestones = [5, 10, 25, 50];
      for (final milestone in countMilestones) {
        if (achievementCount >= milestone && achievementCount - 1 < milestone) {
          await AutoNotificationService.onMilestoneAchieved(
            userId: userId,
            milestoneTitle: 'Achievement Milestone! 🏆',
            description:
                'Amazing! You\'ve earned $milestone verified achievements!',
          );
        }
      }

      // Check for category diversity (achievements in multiple categories)
      final categories = verifiedAchievements.map((a) => a.type).toSet();
      if (categories.length >= 3 && verifiedAchievements.length >= 3) {
        // Check if this is the first time reaching 3+ categories
        final previousCount = verifiedAchievements.length - 1;
        if (previousCount < 3) {
          await AutoNotificationService.onMilestoneAchieved(
            userId: userId,
            milestoneTitle: 'Well-Rounded Achiever! 🎯',
            description:
                'Excellent! You\'ve earned achievements in multiple categories!',
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking for milestones: $e');
    }
  }
}
