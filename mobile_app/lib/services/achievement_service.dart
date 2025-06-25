import '../models/achievement_model.dart';

class AchievementService {
  final List<AchievementModel> _mockAchievements = [
    AchievementModel(
      id: 'a1',
      userId: '1',
      title: "Dean's List",
      description: 'Awarded for academic excellence in 2023.',
      type: AchievementType.academic,
      organization: 'UTHM',
      dateAchieved: DateTime(2023, 6, 1),
      certificateUrl: '',
      imageUrl: '',
      points: 100,
      isVerified: true,
      verifiedBy: 'Dr. Siti Aminah',
      verifiedAt: DateTime(2023, 6, 5),
      createdAt: DateTime(2023, 6, 2),
      updatedAt: DateTime(2023, 6, 2),
    ),
    AchievementModel(
      id: 'a2',
      userId: '1',
      title: 'Hackathon Winner',
      description: 'Won 1st place in UTHM Hackathon 2023.',
      type: AchievementType.competition,
      organization: 'UTHM',
      dateAchieved: DateTime(2023, 8, 15),
      certificateUrl: '',
      imageUrl: '',
      points: 150,
      isVerified: false,
      createdAt: DateTime(2023, 8, 16),
      updatedAt: DateTime(2023, 8, 16),
    ),
  ];

  Future<void> createAchievement(AchievementModel achievement) async {
    _mockAchievements.add(achievement);
  }

  Future<void> updateAchievement(AchievementModel achievement) async {
    final idx = _mockAchievements.indexWhere((a) => a.id == achievement.id);
    if (idx != -1) {
      _mockAchievements[idx] = achievement;
    }
  }

  Future<AchievementModel?> getAchievementById(String achievementId) async {
    try {
      return _mockAchievements.firstWhere((a) => a.id == achievementId,
          orElse: () => throw Exception('Achievement not found'));
    } catch (e) {
      return null;
    }
  }

  Future<List<AchievementModel>> getAchievementsByUserId(String userId) async {
    return _mockAchievements.where((a) => a.userId == userId).toList();
  }

  Future<List<AchievementModel>> getAllAchievements() async {
    return List<AchievementModel>.from(_mockAchievements);
  }

  Future<List<AchievementModel>> getAchievementsByType(
      AchievementType type) async {
    return _mockAchievements.where((a) => a.type == type).toList();
  }

  Future<List<AchievementModel>> searchAchievements(String query) async {
    final q = query.toLowerCase();
    return _mockAchievements
        .where((a) =>
            a.title.toLowerCase().contains(q) ||
            a.description.toLowerCase().contains(q) ||
            (a.organization?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  Future<String> uploadCertificate(String userId, dynamic file) async {
    return '';
  }

  Future<String> uploadAchievementImage(
      String userId, dynamic imageFile) async {
    return '';
  }

  Future<void> deleteAchievementFile(String fileUrl) async {}

  // Get achievement statistics (for admin dashboard)
  Future<Map<String, dynamic>> getAchievementStatistics() async {
    try {
      final allAchievements = await getAllAchievements();

      int totalAchievements = allAchievements.length;
      int verifiedAchievements =
          allAchievements.where((a) => a.isVerified).length;
      int pendingAchievements = totalAchievements - verifiedAchievements;

      Map<String, int> typeCount = {};
      Map<String, int> userCount = {};

      for (var achievement in allAchievements) {
        // Count by type
        String typeName = achievement.type.toString().split('.').last;
        typeCount[typeName] = (typeCount[typeName] ?? 0) + 1;

        // Count by user
        userCount[achievement.userId] =
            (userCount[achievement.userId] ?? 0) + 1;
      }

      return {
        'totalAchievements': totalAchievements,
        'verifiedAchievements': verifiedAchievements,
        'pendingAchievements': pendingAchievements,
        'typeCount': typeCount,
        'userCount': userCount,
      };
    } catch (e) {
      throw Exception('Failed to get achievement statistics: $e');
    }
  }

  // Create demo achievements for testing
  Future<void> createDemoAchievements() async {
    // This method is not needed in the mock implementation
  }

  // Get user's total points
  Future<int> getUserTotalPoints(String userId) async {
    try {
      final allAchievements = await getAllAchievements();
      int totalPoints = 0;

      for (var achievement in allAchievements) {
        if (achievement.userId == userId && achievement.isVerified) {
          totalPoints += achievement.points ?? 0;
        }
      }

      return totalPoints;
    } catch (e) {
      throw Exception('Failed to get user total points: $e');
    }
  }

  // Validate achievement data
  bool validateAchievement(AchievementModel achievement) {
    return achievement.title.isNotEmpty &&
        achievement.description.isNotEmpty &&
        achievement.userId.isNotEmpty;
  }

  // Get default points for achievement type
  int getDefaultPoints(AchievementType type) {
    switch (type) {
      case AchievementType.academic:
        return 50;
      case AchievementType.competition:
        return 100;
      case AchievementType.leadership:
        return 75;
      case AchievementType.skill:
        return 25;
      case AchievementType.other:
        return 10;
    }
  }

  Future<void> deleteAchievement(String achievementId) async {
    _mockAchievements.removeWhere((a) => a.id == achievementId);
  }
}
