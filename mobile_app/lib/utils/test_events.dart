import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class TestEvents {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> addTestEvents() async {
    try {
      final batch = _firestore.batch();

      // Test Event 1
      final event1Ref = _firestore.collection('events').doc('test_event_001');
      batch.set(event1Ref, {
        'title': 'RISE UTHM',
        'description':
            'Research, Innovation, and Startup Ecosystem at UTHM. Join us for an exciting event showcasing the latest research and innovation projects.',
        'imageUrl':
            'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800&h=400&fit=crop',
        'category': 'Research',
        'favoriteUserIds': [],
        'registerUrl': 'https://example.com/register/rise-uthm',
        'createdAt':
            DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'updatedAt':
            DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      });

      // Test Event 2
      final event2Ref = _firestore.collection('events').doc('test_event_002');
      batch.set(event2Ref, {
        'title': 'Tech Innovation Summit',
        'description':
            'Discover the latest technological innovations and network with industry leaders in this comprehensive summit.',
        'imageUrl':
            'https://images.unsplash.com/photo-1559136555-9303baea8ebd?w=800&h=400&fit=crop',
        'category': 'Technology',
        'favoriteUserIds': [],
        'registerUrl': 'https://example.com/register/tech-summit',
        'createdAt':
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'updatedAt':
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      });

      // Test Event 3 - No image to test placeholder
      final event3Ref = _firestore.collection('events').doc('test_event_003');
      batch.set(event3Ref, {
        'title': 'Career Development Workshop',
        'description':
            'Enhance your professional skills and learn about career opportunities in various industries.',
        'imageUrl': '', // Empty to test placeholder
        'category': 'Career',
        'favoriteUserIds': [],
        'registerUrl': 'https://example.com/register/career-workshop',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      await batch.commit();
      debugPrint('✅ Test events added successfully!');

      // Verify the events were added
      final snapshot = await _firestore.collection('events').get();
      debugPrint('📊 Total events in database: ${snapshot.docs.length}');
      for (final doc in snapshot.docs) {
        debugPrint('📄 Event: ${doc.id} - ${doc.data()['title']}');
      }
    } catch (e) {
      debugPrint('❌ Error adding test events: $e');
    }
  }

  static Future<void> clearTestEvents() async {
    try {
      final batch = _firestore.batch();

      // Delete test events
      final testEventIds = [
        'test_event_001',
        'test_event_002',
        'test_event_003'
      ];
      for (final eventId in testEventIds) {
        final docRef = _firestore.collection('events').doc(eventId);
        batch.delete(docRef);
      }

      await batch.commit();
      debugPrint('✅ Test events cleared successfully!');
    } catch (e) {
      debugPrint('❌ Error clearing test events: $e');
    }
  }

  static Future<void> testFavoriteFeature(String userId) async {
    try {
      const eventId = 'test_event_001';
      final eventRef = _firestore.collection('events').doc(eventId);
      final eventDoc = await eventRef.get();

      if (!eventDoc.exists) {
        debugPrint('❌ Test event not found. Run addTestEvents() first.');
        return;
      }

      final data = eventDoc.data() as Map<String, dynamic>;
      List<String> favoriteUserIds =
          List<String>.from(data['favoriteUserIds'] ?? []);

      final isFavorite = favoriteUserIds.contains(userId);

      if (isFavorite) {
        favoriteUserIds.remove(userId);
        debugPrint('🔄 Removing user $userId from favorites');
      } else {
        favoriteUserIds.add(userId);
        debugPrint('🔄 Adding user $userId to favorites');
      }

      await eventRef.update({'favoriteUserIds': favoriteUserIds});
      debugPrint('✅ Favorite status updated successfully!');

      // Verify the update
      final updatedDoc = await eventRef.get();
      final updatedData = updatedDoc.data() as Map<String, dynamic>;
      final updatedFavorites =
          List<String>.from(updatedData['favoriteUserIds'] ?? []);
      debugPrint('📊 Current favorites: $updatedFavorites');
    } catch (e) {
      debugPrint('❌ Error testing favorite feature: $e');
    }
  }
}
