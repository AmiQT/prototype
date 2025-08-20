
class SampleEventData {
  static List<Map<String, dynamic>> getSampleEvents() {
    return [
      {
        'id': 'event_001',
        'title': 'Tech Innovation Summit 2024',
        'description':
            'Join us for an exciting summit featuring the latest innovations in technology, AI, and digital transformation. Network with industry leaders and discover cutting-edge solutions.',
        'imageUrl':
            'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800&h=400&fit=crop',
        'category': 'Technology',
        'favoriteUserIds': [],
        'registerUrl': 'https://example.com/register/tech-summit',
        'createdAt':
            DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        'updatedAt':
            DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      },
      {
        'id': 'event_002',
        'title': 'Career Development Workshop',
        'description':
            'Enhance your professional skills with our comprehensive career development workshop. Learn about resume writing, interview techniques, and networking strategies.',
        'imageUrl':
            'https://images.unsplash.com/photo-1552664730-d307ca884978?w=800&h=400&fit=crop',
        'category': 'Career',
        'favoriteUserIds': [],
        'registerUrl': 'https://example.com/register/career-workshop',
        'createdAt':
            DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        'updatedAt':
            DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      },
      {
        'id': 'event_003',
        'title': 'Entrepreneurship Bootcamp',
        'description':
            'A 3-day intensive bootcamp for aspiring entrepreneurs. Learn about business planning, funding strategies, and startup essentials from successful entrepreneurs.',
        'imageUrl':
            'https://images.unsplash.com/photo-1559136555-9303baea8ebd?w=800&h=400&fit=crop',
        'category': 'Business',
        'favoriteUserIds': [],
        'registerUrl': 'https://example.com/register/entrepreneur-bootcamp',
        'createdAt':
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'updatedAt':
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'id': 'event_004',
        'title': 'Digital Marketing Masterclass',
        'description':
            'Master the art of digital marketing with hands-on sessions covering SEO, social media marketing, content strategy, and analytics.',
        'imageUrl': '', // No image to test placeholder
        'category': 'Marketing',
        'favoriteUserIds': [],
        'registerUrl': 'https://example.com/register/digital-marketing',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      {
        'id': 'event_005',
        'title': 'Leadership Excellence Program',
        'description':
            'Develop your leadership skills through interactive workshops, case studies, and mentorship sessions with experienced leaders.',
        'imageUrl':
            'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=800&h=400&fit=crop',
        'category': 'Leadership',
        'favoriteUserIds': [],
        'registerUrl': 'https://example.com/register/leadership-program',
        'createdAt':
            DateTime.now().add(const Duration(days: 2)).toIso8601String(),
        'updatedAt':
            DateTime.now().add(const Duration(days: 2)).toIso8601String(),
      },
    ];
  }

  // Firebase method removed - migrating to Supabase
  // static Future<void> addSampleEventsToFirebase() async {
  //   try {
  //     final sampleEvents = getSampleEvents();
  //     final batch = _firestore.batch();

  //     for (final eventData in sampleEvents) {
  //       final docRef = _firestore.collection('events').doc(eventData['id']);
  //       batch.set(docRef, eventData);
  //     }

  //     await batch.commit();
  //     debugPrint('✅ Sample events added successfully!');
  //   } catch (e) {
  //     debugPrint('❌ Error adding sample events: $e');
  //   }
  // }

  // Firebase methods removed - migrating to Supabase
  // static Future<void> clearAllEvents() async {
  //   try {
  //     final snapshot = await _firestore.collection('events').get();
  //     final batch = _firestore.batch();

  //     for (final doc in snapshot.docs) {
  //       batch.delete(doc.reference);
  //     }

  //       await batch.commit();
  //       debugPrint('✅ All events cleared successfully!');
  //     } catch (e) {
  //       debugPrint('❌ Error clearing events: $e');
  //     }
  //   }

  //   static Future<void> testFavoriteFeature(String userId, String eventId) async {
  //     try {
  //       final eventRef = _firestore.collection('events').doc(eventId);
  //       final eventDoc = await eventRef.get();

  //       if (!eventDoc.exists) {
  //         debugPrint('❌ Event not found: $eventId');
  //         return;
  //       }

  //       final data = eventDoc.data() as Map<String, dynamic>;
  //       List<String> favoriteUserIds =
  //           List<String>.from(data['favoriteUserIds'] ?? []);

  //       final isFavorite = favoriteUserIds.contains(userId);

  //       if (isFavorite) {
  //         favoriteUserIds.remove(userId);
  //         debugPrint(
  //             '🔄 Removing user $userId from favorites for event $eventId');
  //       } else {
  //         favoriteUserIds.add(userId);
  //         debugPrint('🔄 Adding user $userId to favorites for event $eventId');
  //       }

  //       await eventRef.update({'favoriteUserIds': favoriteUserIds});
  //       debugPrint('✅ Favorite status updated successfully!');

  //       // Verify the update
  //       final updatedDoc = await eventRef.get();
  //       final updatedData = updatedDoc.data() as Map<String, dynamic>;
  //       final updatedFavorites =
  //           List<String>.from(updatedData['favoriteUserIds'] ?? []);
  //       debugPrint('📊 Current favorites for event $eventId: $updatedFavorites');
  //     } catch (e) {
  //       debugPrint('❌ Error testing favorite feature: $e');
  //       }
  //   }
}
