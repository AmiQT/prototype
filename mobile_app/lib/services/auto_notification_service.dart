import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';
import '../models/notification_model.dart';

/// Service for automatically creating notifications based on user actions
/// This provides free-tier alternatives to Cloud Functions
class AutoNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final NotificationService _notificationService = NotificationService();

  /// Initialize the auto notification service
  static Future<void> initialize(String userId) async {
    await _notificationService.initialize(userId);
  }

  /// Create notification when user adds event to favorites
  static Future<void> onEventFavorited({
    required String userId,
    required String eventTitle,
    required String eventId,
  }) async {
    try {
      await _notificationService.createNotification(
        title: 'Event Added to Favorites',
        message: 'You\'ve added "$eventTitle" to your favorites. We\'ll notify you of any updates!',
        type: NotificationType.event,
        userId: userId,
        data: {
          'eventId': eventId,
          'eventTitle': eventTitle,
          'action': 'favorited',
        },
        actionUrl: '/event/$eventId',
      );
      
      debugPrint('AutoNotificationService: Created favorite notification for event $eventTitle');
    } catch (e) {
      debugPrint('AutoNotificationService: Error creating favorite notification: $e');
    }
  }

  /// Create notification when user achieves a milestone
  static Future<void> onMilestoneAchieved({
    required String userId,
    required String milestoneTitle,
    required String description,
  }) async {
    try {
      await _notificationService.createNotification(
        title: 'Milestone Achieved! 🎉',
        message: 'Congratulations! You\'ve achieved: $milestoneTitle',
        type: NotificationType.achievement,
        userId: userId,
        data: {
          'milestoneTitle': milestoneTitle,
          'description': description,
          'achievedAt': DateTime.now().toIso8601String(),
        },
      );
      
      debugPrint('AutoNotificationService: Created milestone notification for $milestoneTitle');
    } catch (e) {
      debugPrint('AutoNotificationService: Error creating milestone notification: $e');
    }
  }

  /// Create notification when user completes profile
  static Future<void> onProfileCompleted({
    required String userId,
    required String userName,
  }) async {
    try {
      await _notificationService.createNotification(
        title: 'Profile Complete! ✅',
        message: 'Great job, $userName! Your profile is now complete and visible to others.',
        type: NotificationType.system,
        userId: userId,
        data: {
          'action': 'profile_completed',
          'completedAt': DateTime.now().toIso8601String(),
        },
        actionUrl: '/profile',
      );
      
      debugPrint('AutoNotificationService: Created profile completion notification');
    } catch (e) {
      debugPrint('AutoNotificationService: Error creating profile completion notification: $e');
    }
  }

  /// Create notification when user posts content
  static Future<void> onContentPosted({
    required String userId,
    required String contentType,
    required String contentTitle,
    String? postId,
  }) async {
    try {
      await _notificationService.createNotification(
        title: 'Content Posted Successfully! 📝',
        message: 'Your $contentType "$contentTitle" has been posted and is now visible to others.',
        type: NotificationType.social,
        userId: userId,
        data: {
          'contentType': contentType,
          'contentTitle': contentTitle,
          'postId': postId,
          'postedAt': DateTime.now().toIso8601String(),
        },
        actionUrl: postId != null ? '/post/$postId' : null,
      );
      
      debugPrint('AutoNotificationService: Created content posted notification');
    } catch (e) {
      debugPrint('AutoNotificationService: Error creating content posted notification: $e');
    }
  }

  /// Create welcome notification for new users
  static Future<void> onUserWelcome({
    required String userId,
    required String userName,
  }) async {
    try {
      await _notificationService.createNotification(
        title: 'Welcome to UTHM Talent! 👋',
        message: 'Hi $userName! Welcome to the Student Talent Profiling app. Start by completing your profile and exploring events.',
        type: NotificationType.system,
        userId: userId,
        data: {
          'action': 'welcome',
          'joinedAt': DateTime.now().toIso8601String(),
        },
        actionUrl: '/profile',
      );
      
      debugPrint('AutoNotificationService: Created welcome notification');
    } catch (e) {
      debugPrint('AutoNotificationService: Error creating welcome notification: $e');
    }
  }

  /// Create reminder notification for incomplete profiles
  static Future<void> onProfileReminder({
    required String userId,
    required String userName,
  }) async {
    try {
      await _notificationService.createNotification(
        title: 'Complete Your Profile 📋',
        message: 'Hi $userName! Don\'t forget to complete your profile to get the most out of the app.',
        type: NotificationType.reminder,
        userId: userId,
        data: {
          'action': 'profile_reminder',
          'reminderAt': DateTime.now().toIso8601String(),
        },
        actionUrl: '/profile',
      );
      
      debugPrint('AutoNotificationService: Created profile reminder notification');
    } catch (e) {
      debugPrint('AutoNotificationService: Error creating profile reminder notification: $e');
    }
  }

  /// Create notification when user receives likes/comments
  static Future<void> onSocialInteraction({
    required String userId,
    required String interactionType, // 'like', 'comment', 'share'
    required String fromUserName,
    required String contentTitle,
    String? postId,
  }) async {
    try {
      String title = '';
      String message = '';
      
      switch (interactionType) {
        case 'like':
          title = 'Someone liked your post! ❤️';
          message = '$fromUserName liked your post "$contentTitle"';
          break;
        case 'comment':
          title = 'New comment on your post! 💬';
          message = '$fromUserName commented on your post "$contentTitle"';
          break;
        case 'share':
          title = 'Your post was shared! 🔄';
          message = '$fromUserName shared your post "$contentTitle"';
          break;
        default:
          title = 'New interaction! 👋';
          message = '$fromUserName interacted with your post "$contentTitle"';
      }
      
      await _notificationService.createNotification(
        title: title,
        message: message,
        type: NotificationType.social,
        userId: userId,
        data: {
          'interactionType': interactionType,
          'fromUserName': fromUserName,
          'contentTitle': contentTitle,
          'postId': postId,
          'interactionAt': DateTime.now().toIso8601String(),
        },
        actionUrl: postId != null ? '/post/$postId' : null,
      );
      
      debugPrint('AutoNotificationService: Created social interaction notification');
    } catch (e) {
      debugPrint('AutoNotificationService: Error creating social interaction notification: $e');
    }
  }

  /// Create notification for system announcements
  static Future<void> createSystemAnnouncement({
    required String title,
    required String message,
    List<String>? targetUserIds,
    String? actionUrl,
  }) async {
    try {
      List<String> userIds = targetUserIds ?? [];
      
      // If no specific users, get all active users
      if (userIds.isEmpty) {
        final usersSnapshot = await _firestore
            .collection('users')
            .where('isActive', isEqualTo: true)
            .get();
        
        userIds = usersSnapshot.docs.map((doc) => doc.data()['uid'] as String).toList();
      }
      
      // Create notifications for all target users
      final batch = _firestore.batch();
      
      for (final userId in userIds) {
        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, {
          'userId': userId,
          'title': title,
          'message': message,
          'type': 'system',
          'isRead': false,
          'createdAt': DateTime.now().toIso8601String(),
          'data': {
            'announcement': true,
            'createdAt': DateTime.now().toIso8601String(),
          },
          'actionUrl': actionUrl,
        });
      }
      
      await batch.commit();
      debugPrint('AutoNotificationService: Created system announcement for ${userIds.length} users');
      
    } catch (e) {
      debugPrint('AutoNotificationService: Error creating system announcement: $e');
    }
  }
}
