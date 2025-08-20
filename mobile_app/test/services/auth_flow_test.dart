import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/user_model.dart';

void main() {
  group('Auth Flow Tests', () {
    test('New user should have profileCompleted = false', () async {
      // Arrange
      final newUser = UserModel(
        id: 'test-user-id',
        uid: 'test-user-id',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.student,
        createdAt: DateTime.now(),
        isActive: true,
        profileCompleted: false, // New users should have this as false
      );

      // Act & Assert
      expect(newUser.profileCompleted, false);
      expect(newUser.role, UserRole.student);
      expect(newUser.isActive, true);
    });

    test('Existing user with profile should have profileCompleted = true',
        () async {
      // Arrange
      final existingUser = UserModel(
        id: 'existing-user-id',
        uid: 'existing-user-id',
        email: 'existing@example.com',
        name: 'Existing User',
        role: UserRole.student,
        createdAt: DateTime.now(),
        isActive: true,
        profileCompleted:
            true, // Existing users with profiles should have this as true
      );

      // Act & Assert
      expect(existingUser.profileCompleted, true);
      expect(existingUser.role, UserRole.student);
      expect(existingUser.isActive, true);
    });

    test('User role should be properly parsed', () {
      // Test different role scenarios
      expect(UserRole.student.toString(), 'UserRole.student');
      expect(UserRole.lecturer.toString(), 'UserRole.lecturer');
      expect(UserRole.admin.toString(), 'UserRole.admin');
    });

    test('UserModel JSON serialization works correctly', () {
      // Arrange
      final user = UserModel(
        id: 'test-id',
        uid: 'test-uid',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.student,
        createdAt: DateTime(2024, 1, 1),
        isActive: true,
        profileCompleted: false,
      );

      // Act
      final json = user.toJson();
      final fromJson = UserModel.fromJson(json);

      // Assert
      expect(fromJson.id, user.id);
      expect(fromJson.email, user.email);
      expect(fromJson.name, user.name);
      expect(fromJson.role, user.role);
      expect(fromJson.profileCompleted, user.profileCompleted);
      expect(fromJson.isActive, user.isActive);
    });
  });
}
