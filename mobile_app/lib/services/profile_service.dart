import '../models/profile_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileService {
  final List<ProfileModel> _mockProfiles = [
    ProfileModel(
      id: 'p1',
      userId: '1',
      fullName: 'Ali Bin Ahmad',
      studentId: 'A123456',
      department: 'Computer Science',
      program: 'Software Engineering',
      semester: 6,
      phoneNumber: '+60123456789',
      address: 'No. 123, Jalan Universiti, 86400 Parit Raja, Johor',
      profileImageUrl: '',
      bio: 'Enthusiastic student at UTHM.',
      skills: ['Flutter', 'Dart', 'Firebase', 'UI/UX Design'],
      interests: ['Mobile Development', 'AI', 'Web Development'],
      createdAt: DateTime(2023, 1, 1),
      updatedAt: DateTime(2023, 1, 1),
    ),
    ProfileModel(
      id: 'p2',
      userId: '2',
      fullName: 'Dr. Siti Aminah',
      studentId: 'LEC001',
      department: 'Computer Science',
      program: 'Lecturer',
      semester: 0,
      phoneNumber: '+60123456788',
      address: 'Faculty of Computer Science, UTHM',
      profileImageUrl: '',
      bio: 'Lecturer at UTHM.',
      skills: ['Machine Learning', 'Python', 'Research', 'Teaching'],
      interests: ['AI', 'Data Science', 'Academic Research'],
      createdAt: DateTime(2023, 1, 1),
      updatedAt: DateTime(2023, 1, 1),
    ),
  ];

  Future<void> saveProfile(ProfileModel profile) async {
    final idx = _mockProfiles.indexWhere((p) => p.id == profile.id);
    if (idx != -1) {
      _mockProfiles[idx] = profile;
    } else {
      _mockProfiles.add(profile);
    }
  }

  Future<ProfileModel?> getProfileByUserId(String userId) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('profiles')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return ProfileModel.fromJson(query.docs.first.data());
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<ProfileModel?> getProfileById(String profileId) async {
    try {
      return _mockProfiles.firstWhere((p) => p.id == profileId,
          orElse: () => throw Exception('Profile not found'));
    } catch (e) {
      return null;
    }
  }

  Future<List<ProfileModel>> getAllProfiles() async {
    return List<ProfileModel>.from(_mockProfiles);
  }

  Future<List<ProfileModel>> getProfilesByDepartment(String department) async {
    return _mockProfiles.where((p) => p.department == department).toList();
  }

  Future<List<ProfileModel>> searchProfiles(String query) async {
    final q = query.toLowerCase();
    return _mockProfiles
        .where((p) =>
            p.fullName.toLowerCase().contains(q) ||
            (p.studentId.toLowerCase().contains(q) ?? false))
        .toList();
  }

  Future<String> uploadProfileImage(String userId, dynamic imageFile) async {
    return '';
  }

  Future<void> deleteProfileImage(String imageUrl) async {}

  Future<void> updateProfileImageUrl(String profileId, String imageUrl) async {
    final idx = _mockProfiles.indexWhere((p) => p.id == profileId);
    if (idx != -1) {
      final profile = _mockProfiles[idx];
      _mockProfiles[idx] = profile.copyWith(
          profileImageUrl: imageUrl, updatedAt: DateTime.now());
    }
  }

  Future<void> deleteProfile(String profileId) async {
    _mockProfiles.removeWhere((p) => p.id == profileId);
  }

  Future<Map<String, dynamic>> getProfileStatistics() async {
    return {
      'totalProfiles': _mockProfiles.length,
      'departmentCount': {
        for (var p in _mockProfiles) p.department: 1,
      },
      'programCount': {
        for (var p in _mockProfiles) p.program: 1,
      },
    };
  }

  // Validate profile data
  bool validateProfile(ProfileModel profile) {
    return profile.fullName.isNotEmpty &&
        profile.studentId.isNotEmpty &&
        profile.program.isNotEmpty &&
        profile.department.isNotEmpty &&
        profile.semester > 0 &&
        profile.semester <= 8;
  }

  // Get available departments
  List<String> getAvailableDepartments() {
    return [
      'Computer Science',
      'Information Technology',
      'Software Engineering',
      'Data Science',
      'Cybersecurity',
      'Artificial Intelligence',
      'Computer Engineering',
      'Electrical Engineering',
      'Mechanical Engineering',
      'Civil Engineering',
    ];
  }

  // Get available programs
  List<String> getAvailablePrograms() {
    return [
      'Bachelor of Computer Science',
      'Bachelor of Information Technology',
      'Bachelor of Software Engineering',
      'Bachelor of Data Science',
      'Bachelor of Cybersecurity',
      'Bachelor of Artificial Intelligence',
      'Bachelor of Computer Engineering',
      'Bachelor of Electrical Engineering',
      'Bachelor of Mechanical Engineering',
      'Bachelor of Civil Engineering',
    ];
  }

  // Create demo profiles for testing
  Future<void> createDemoProfiles() async {
    // This method is not needed in the mock implementation
  }
}
