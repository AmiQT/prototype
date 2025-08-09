import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/services/settings_service.dart';

// Generate mocks
@GenerateMocks([FirebaseAuth, FirebaseFirestore, User, UserCredential])
import 'settings_service_test.mocks.dart';

void main() {
  group('SettingsService Tests', () {
    late SettingsService settingsService;
    late MockFirebaseAuth mockAuth;
    late MockFirebaseFirestore mockFirestore;
    late MockUser mockUser;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = MockFirebaseFirestore();
      mockUser = MockUser();
      settingsService = SettingsService();
    });

    group('Password Change Tests', () {
      test('should change password successfully', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.email).thenReturn('test@example.com');

        // Mock re-authentication
        final mockCredential = MockUserCredential();
        when(mockUser.reauthenticateWithCredential(any))
            .thenAnswer((_) async => mockCredential);

        // Mock password update
        when(mockUser.updatePassword(any)).thenAnswer((_) async {});

        // Act & Assert
        expect(
          () => settingsService.changePassword(
            currentPassword: 'oldPassword123',
            newPassword: 'newPassword123',
          ),
          returnsNormally,
        );
      });

      test('should throw exception when user is not signed in', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);

        // Act & Assert
        expect(
          () => settingsService.changePassword(
            currentPassword: 'oldPassword123',
            newPassword: 'newPassword123',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle wrong password error', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.email).thenReturn('test@example.com');
        when(mockUser.reauthenticateWithCredential(any))
            .thenThrow(FirebaseAuthException(code: 'wrong-password'));

        // Act & Assert
        expect(
          () => settingsService.changePassword(
            currentPassword: 'wrongPassword',
            newPassword: 'newPassword123',
          ),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('Current password is incorrect'))),
        );
      });

      test('should handle weak password error', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.email).thenReturn('test@example.com');

        final mockCredential = MockUserCredential();
        when(mockUser.reauthenticateWithCredential(any))
            .thenAnswer((_) async => mockCredential);

        when(mockUser.updatePassword(any))
            .thenThrow(FirebaseAuthException(code: 'weak-password'));

        // Act & Assert
        expect(
          () => settingsService.changePassword(
            currentPassword: 'oldPassword123',
            newPassword: '123',
          ),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('New password is too weak'))),
        );
      });
    });

    group('Email Update Tests', () {
      test('should update email successfully', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.email).thenReturn('old@example.com');

        final mockCredential = MockUserCredential();
        when(mockUser.reauthenticateWithCredential(any))
            .thenAnswer((_) async => mockCredential);

        when(mockUser.updateEmail(any)).thenAnswer((_) async {});
        when(mockUser.uid).thenReturn('test-uid');

        // Act & Assert
        expect(
          () => settingsService.updateEmail(
            newEmail: 'new@example.com',
            currentPassword: 'password123',
          ),
          returnsNormally,
        );
      });

      test('should handle email already in use error', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.email).thenReturn('old@example.com');

        final mockCredential = MockUserCredential();
        when(mockUser.reauthenticateWithCredential(any))
            .thenAnswer((_) async => mockCredential);

        when(mockUser.updateEmail(any))
            .thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

        // Act & Assert
        expect(
          () => settingsService.updateEmail(
            newEmail: 'existing@example.com',
            currentPassword: 'password123',
          ),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('This email is already in use'))),
        );
      });
    });

    group('Display Name Update Tests', () {
      test('should update display name successfully', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.updateDisplayName(any)).thenAnswer((_) async {});
        when(mockUser.uid).thenReturn('test-uid');

        // Act & Assert
        expect(
          () => settingsService.updateDisplayName('New Name'),
          returnsNormally,
        );
      });

      test('should throw exception when user is not signed in', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);

        // Act & Assert
        expect(
          () => settingsService.updateDisplayName('New Name'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Password Reset Tests', () {
      test('should send password reset email successfully', () async {
        // Arrange
        when(mockAuth.sendPasswordResetEmail(email: any))
            .thenAnswer((_) async {});

        // Act & Assert
        expect(
          () => settingsService.sendPasswordResetEmail('test@example.com'),
          returnsNormally,
        );
      });

      test('should handle user not found error', () async {
        // Arrange
        when(mockAuth.sendPasswordResetEmail(email: any))
            .thenThrow(FirebaseAuthException(code: 'user-not-found'));

        // Act & Assert
        expect(
          () =>
              settingsService.sendPasswordResetEmail('nonexistent@example.com'),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('No account found with this email'))),
        );
      });

      test('should handle invalid email error', () async {
        // Arrange
        when(mockAuth.sendPasswordResetEmail(email: any))
            .thenThrow(FirebaseAuthException(code: 'invalid-email'));

        // Act & Assert
        expect(
          () => settingsService.sendPasswordResetEmail('invalid-email'),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('Please enter a valid email address'))),
        );
      });
    });
  });
}
