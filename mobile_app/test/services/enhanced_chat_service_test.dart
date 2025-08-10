import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:student_talent_profiling_app/services/enhanced_chat_service.dart';
import 'package:student_talent_profiling_app/models/chat_models.dart';

void main() {
  group('EnhancedChatService Tests', () {
    late EnhancedChatService chatService;

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      chatService = EnhancedChatService();
    });

    group('Configuration', () {
      test('should have correct default configuration', () {
        expect(chatService.currentModel, ChatConfig.defaultModel);
        expect(chatService.isInitialized, false);
      });

      test('should handle missing API key gracefully', () async {
        // Clear the API key
        dotenv.testLoad(fileInput: '');

        expect(
          () async => await chatService.initialize(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('OpenRouter API key not configured'),
          )),
        );
      });
    });

    group('User Context', () {
      test('should create minimal context when services fail', () async {
        const userId = 'test_user_123';

        final context = await chatService.getUserContext(userId);

        expect(context.userId, userId);
        expect(context.fullName, 'User');
        expect(context.lastUpdated, isA<DateTime>());
      });

      test('should cache context to avoid repeated calls', () async {
        const userId = 'test_user_123';

        // First call
        final context1 = await chatService.getUserContext(userId);

        // Second call should return cached version
        final context2 = await chatService.getUserContext(userId);

        expect(context1.lastUpdated, context2.lastUpdated);
      });
    });

    group('Cache Management', () {
      test('should clear caches when requested', () {
        // Clear caches
        chatService.clearCaches();

        // This test verifies the method doesn't throw errors
        expect(true, true);
      });
    });
  });

  group('ChatUserContext Tests', () {
    test('should generate proper context string', () {
      final context = ChatUserContext(
        userId: 'test_user',
        fullName: 'John Doe',
        program: 'Computer Science',
        department: 'Engineering',
        skills: ['Flutter', 'Dart', 'Firebase'],
        interests: ['AI', 'Mobile Development'],
        academicLevel: 'Bachelor',
        achievementCount: 5,
        lastUpdated: DateTime.now(),
      );

      final contextString = context.toContextString();

      expect(contextString, contains('John Doe'));
      expect(contextString, contains('Computer Science'));
      expect(contextString, contains('Engineering'));
      expect(contextString, contains('Flutter'));
      expect(contextString, contains('AI'));
      expect(contextString, contains('Bachelor'));
      expect(contextString, contains('5'));
    });

    test('should handle null values gracefully', () {
      final context = ChatUserContext(
        userId: 'test_user',
        fullName: 'John Doe',
        lastUpdated: DateTime.now(),
      );

      final contextString = context.toContextString();

      expect(contextString, contains('John Doe'));
      expect(contextString, isNot(contains('null')));
    });

    test('should serialize and deserialize correctly', () {
      final originalContext = ChatUserContext(
        userId: 'test_user',
        fullName: 'John Doe',
        program: 'Computer Science',
        skills: ['Flutter', 'Dart'],
        interests: ['AI'],
        achievementCount: 3,
        lastUpdated: DateTime.now(),
      );

      final json = originalContext.toJson();
      final deserializedContext = ChatUserContext.fromJson(json);

      expect(deserializedContext.userId, originalContext.userId);
      expect(deserializedContext.fullName, originalContext.fullName);
      expect(deserializedContext.program, originalContext.program);
      expect(deserializedContext.skills, originalContext.skills);
      expect(deserializedContext.interests, originalContext.interests);
      expect(deserializedContext.achievementCount,
          originalContext.achievementCount);
    });
  });

  group('ChatConfig Tests', () {
    test('should have reasonable default values', () {
      expect(ChatConfig.maxMessagesPerConversation, greaterThan(0));
      expect(ChatConfig.maxMessageLength, greaterThan(100));
      expect(ChatConfig.maxConversationsPerUser, greaterThan(0));
      expect(ChatConfig.defaultModel, isNotEmpty);
      expect(ChatConfig.maxTokens, greaterThan(0));
      expect(ChatConfig.temperature, greaterThanOrEqualTo(0.0));
      expect(ChatConfig.temperature, lessThanOrEqualTo(2.0));
    });
  });
}
