import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';

/// Utility class for testing notification synchronization
class TestNotificationSync {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Test creating a notification and verify it syncs to Firestore
  static Future<void> testNotificationCreation(String userId) async {
    debugPrint('🧪 Testing notification creation and sync...');
    
    try {
      final notificationService = NotificationService();
      await notificationService.initialize(userId);
      
      // Create a test notification
      await notificationService.createNotification(
        title: 'Test Notification',
        message: 'This is a test notification to verify sync functionality',
        type: NotificationType.system,
        userId: userId,
        data: {'test': true},
      );
      
      // Wait a moment for Firestore write
      await Future.delayed(const Duration(seconds: 2));
      
      // Check if notification exists in Firestore
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('title', isEqualTo: 'Test Notification')
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        debugPrint('✅ Notification successfully synced to Firestore!');
        debugPrint('📄 Document ID: ${snapshot.docs.first.id}');
        debugPrint('📊 Data: ${snapshot.docs.first.data()}');
        
        // Clean up test notification
        await snapshot.docs.first.reference.delete();
        debugPrint('🧹 Test notification cleaned up');
      } else {
        debugPrint('❌ Notification NOT found in Firestore');
      }
      
    } catch (e) {
      debugPrint('❌ Error testing notification sync: $e');
    }
  }

  /// Test reading notifications from Firestore
  static Future<void> testNotificationReading(String userId) async {
    debugPrint('🧪 Testing notification reading from Firestore...');
    
    try {
      // Create a test notification directly in Firestore
      final testNotificationRef = await _firestore.collection('notifications').add({
        'userId': userId,
        'title': 'Direct Firestore Test',
        'message': 'This notification was created directly in Firestore',
        'type': 'system',
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
        'data': {'directTest': true},
      });
      
      debugPrint('📝 Created test notification in Firestore: ${testNotificationRef.id}');
      
      // Initialize notification service and check if it reads the notification
      final notificationService = NotificationService();
      await notificationService.initialize(userId);
      
      // Wait for real-time listener to pick up the notification
      await Future.delayed(const Duration(seconds: 3));
      
      final notifications = notificationService.notifications;
      final testNotification = notifications.firstWhere(
        (n) => n.title == 'Direct Firestore Test',
        orElse: () => throw Exception('Test notification not found'),
      );
      
      debugPrint('✅ Notification successfully read from Firestore!');
      debugPrint('📄 Local notification ID: ${testNotification.id}');
      debugPrint('📊 Local notification data: ${testNotification.data}');
      
      // Clean up
      await testNotificationRef.delete();
      debugPrint('🧹 Test notification cleaned up');
      
    } catch (e) {
      debugPrint('❌ Error testing notification reading: $e');
    }
  }

  /// Test marking notification as read and verify sync
  static Future<void> testNotificationMarkAsRead(String userId) async {
    debugPrint('🧪 Testing notification mark as read sync...');
    
    try {
      final notificationService = NotificationService();
      await notificationService.initialize(userId);
      
      // Create a test notification
      await notificationService.createNotification(
        title: 'Read Test Notification',
        message: 'This notification will be marked as read',
        type: NotificationType.system,
        userId: userId,
      );
      
      await Future.delayed(const Duration(seconds: 2));
      
      // Find the notification in Firestore
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('title', isEqualTo: 'Read Test Notification')
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final docId = snapshot.docs.first.id;
        debugPrint('📄 Found test notification: $docId');
        
        // Mark as read using the service
        await notificationService.markAsRead(docId);
        
        await Future.delayed(const Duration(seconds: 2));
        
        // Check if it's marked as read in Firestore
        final updatedDoc = await _firestore
            .collection('notifications')
            .doc(docId)
            .get();
        
        if (updatedDoc.exists && updatedDoc.data()!['isRead'] == true) {
          debugPrint('✅ Notification successfully marked as read in Firestore!');
        } else {
          debugPrint('❌ Notification read status NOT synced to Firestore');
        }
        
        // Clean up
        await updatedDoc.reference.delete();
        debugPrint('🧹 Test notification cleaned up');
      } else {
        debugPrint('❌ Test notification not found in Firestore');
      }
      
    } catch (e) {
      debugPrint('❌ Error testing notification mark as read: $e');
    }
  }

  /// Run all notification sync tests
  static Future<void> runAllTests(String userId) async {
    debugPrint('🚀 Starting comprehensive notification sync tests...');
    debugPrint('👤 User ID: $userId');
    debugPrint('=' * 50);
    
    await testNotificationCreation(userId);
    debugPrint('');
    
    await testNotificationReading(userId);
    debugPrint('');
    
    await testNotificationMarkAsRead(userId);
    debugPrint('');
    
    debugPrint('🏁 All notification sync tests completed!');
    debugPrint('=' * 50);
  }
}
