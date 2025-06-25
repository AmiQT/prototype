import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  UserModel? _currentUser;

  // Hardcoded mock users
  final List<UserModel> _mockUsers = [
    UserModel(
      id: '1',
      uid: '1',
      email: 'student@uthm.edu.my',
      password: 'student123',
      name: 'Ali Bin Ahmad',
      role: UserRole.student,
      studentId: 'A123456',
      department: 'Computer Science',
      createdAt: DateTime(2023, 1, 1),
      lastLoginAt: DateTime.now(),
    ),
    UserModel(
      id: '2',
      uid: '2',
      email: 'lecturer@uthm.edu.my',
      password: 'lecturer123',
      name: 'Dr. Siti Aminah',
      role: UserRole.lecturer,
      department: 'Computer Science',
      createdAt: DateTime(2023, 1, 1),
      lastLoginAt: DateTime.now(),
    ),
  ];

  UserModel? get currentUser => _currentUser;

  Future<void> initialize() async {}

  Future<UserModel> signInWithEmailAndPassword(
      String email, String password) async {
    // Sign in with Firebase Auth
    final userCredential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = userCredential.user;
    // Optionally, fetch additional user info from Firestore here
    final loggedInUser = UserModel(
      id: user!.uid,
      uid: user.uid,
      email: user.email ?? '',
      password: password,
      name: user.displayName ?? '',
      role: UserRole
          .student, // You may want to fetch the real role from Firestore
      studentId: '', // Fetch from Firestore if needed
      department: '', // Fetch from Firestore if needed
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
    _currentUser = loggedInUser;
    return loggedInUser;
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
    // Save user data to Firestore
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
      'id': user.uid,
      'uid': user.uid,
      'email': email,
      'password': password,
      'name': name,
      'role': role.toString().split('.').last,
      'studentId': studentId,
      'department': department,
      'createdAt': DateTime.now().toIso8601String(),
      'lastLoginAt': DateTime.now().toIso8601String(),
      'isActive': true,
    });
    final newUser = UserModel(
      id: user.uid,
      uid: user.uid,
      email: email,
      password: password,
      name: name,
      role: role,
      studentId: studentId,
      department: department,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
    _currentUser = newUser;
    return newUser;
  }

  Future<void> signOut() async {
    _currentUser = null;
  }

  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> data) async {
    final idx = _mockUsers.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final user = _mockUsers[idx];
      _mockUsers[idx] = user.copyWith(
        name: data['name'] ?? user.name,
        department: data['department'] ?? user.department,
        studentId: data['studentId'] ?? user.studentId,
      );
      if (_currentUser?.id == userId) {
        _currentUser = _mockUsers[idx];
      }
    }
  }

  Future<void> resetPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<bool> validateSMAPCredentials(
      String studentId, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }
}
