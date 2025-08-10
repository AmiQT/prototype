import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_talent_profiling_app/services/notification_preferences_service.dart';
import 'package:student_talent_profiling_app/models/notification_model.dart';

void main() {
  group('NotificationPreferencesService Tests', () {
    late NotificationPreferencesService service;

    setUp(() async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      service = NotificationPreferencesService();
      await service.initialize();
    });

    test('should initialize with default preferences', () {
      expect(service.globallyEnabled, true);
      expect(service.soundEnabled, true);
      expect(service.vibrationEnabled, true);
      expect(service.quietHoursEnabled, false);
      expect(service.quietHoursStart, '22:00');
      expect(service.quietHoursEnd, '08:00');
      
      // All notification types should be enabled by default
      for (final type in NotificationType.values) {
        expect(service.isTypeEnabled(type), true);
      }
    });

    test('should toggle global notifications', () async {
      expect(service.globallyEnabled, true);
      
      await service.setGloballyEnabled(false);
      expect(service.globallyEnabled, false);
      
      // When globally disabled, all types should return false
      for (final type in NotificationType.values) {
        expect(service.isTypeEnabled(type), false);
      }
    });

    test('should toggle individual notification types', () async {
      await service.setTypeEnabled(NotificationType.achievement, false);
      expect(service.isTypeEnabled(NotificationType.achievement), false);
      expect(service.isTypeEnabled(NotificationType.event), true);
      
      await service.setTypeEnabled(NotificationType.achievement, true);
      expect(service.isTypeEnabled(NotificationType.achievement), true);
    });

    test('should handle quiet hours correctly', () async {
      await service.setQuietHoursEnabled(true);
      await service.setQuietHoursStart('23:00');
      await service.setQuietHoursEnd('07:00');
      
      expect(service.quietHoursEnabled, true);
      expect(service.quietHoursStart, '23:00');
      expect(service.quietHoursEnd, '07:00');
    });

    test('should count enabled/disabled types correctly', () async {
      expect(service.enabledTypesCount, NotificationType.values.length);
      expect(service.disabledTypesCount, 0);
      expect(service.allTypesEnabled, true);
      expect(service.allTypesDisabled, false);
      
      await service.setTypeEnabled(NotificationType.achievement, false);
      expect(service.enabledTypesCount, NotificationType.values.length - 1);
      expect(service.disabledTypesCount, 1);
      expect(service.allTypesEnabled, false);
      expect(service.allTypesDisabled, false);
      
      await service.toggleAllTypes(false);
      expect(service.enabledTypesCount, 0);
      expect(service.disabledTypesCount, NotificationType.values.length);
      expect(service.allTypesEnabled, false);
      expect(service.allTypesDisabled, true);
    });

    test('should reset to defaults', () async {
      // Change some settings
      await service.setGloballyEnabled(false);
      await service.setSoundEnabled(false);
      await service.setTypeEnabled(NotificationType.achievement, false);
      await service.setQuietHoursEnabled(true);
      
      // Reset to defaults
      await service.resetToDefaults();
      
      // Verify all settings are back to defaults
      expect(service.globallyEnabled, true);
      expect(service.soundEnabled, true);
      expect(service.vibrationEnabled, true);
      expect(service.quietHoursEnabled, false);
      expect(service.quietHoursStart, '22:00');
      expect(service.quietHoursEnd, '08:00');
      
      for (final type in NotificationType.values) {
        expect(service.isTypeEnabled(type), true);
      }
    });
  });

  group('NotificationType Extension Tests', () {
    test('should have correct display names', () {
      expect(NotificationType.achievement.displayName, 'Achievement');
      expect(NotificationType.event.displayName, 'Event');
      expect(NotificationType.message.displayName, 'Message');
      expect(NotificationType.system.displayName, 'System');
      expect(NotificationType.reminder.displayName, 'Reminder');
      expect(NotificationType.social.displayName, 'Social');
    });

    test('should have descriptions', () {
      for (final type in NotificationType.values) {
        expect(type.description.isNotEmpty, true);
      }
    });

    test('should have icons and colors', () {
      for (final type in NotificationType.values) {
        expect(type.icon, isNotNull);
        expect(type.color, isNotNull);
      }
    });
  });
}
