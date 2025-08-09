import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/event_model.dart';

class EventService {
  final CollectionReference eventsCollection =
      FirebaseFirestore.instance.collection('events');

  Future<List<EventModel>> getAllEvents() async {
    final querySnapshot = await eventsCollection.get();
    final events = <EventModel>[];

    for (final doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      debugPrint('📄 Raw Document ID: "${doc.id}"');
      debugPrint('📄 Document exists: ${doc.exists}');
      debugPrint('📄 Document data: $data');
      debugPrint('📄 Title: "${data['title']}"');
      debugPrint('📄 Description: "${data['description']}"');

      // Create event with explicit document ID
      final event = EventModel(
        id: doc.id, // Direct assignment
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        imageUrl: data['imageUrl'] ?? '',
        category: data['category'] ?? '',
        favoriteUserIds: List<String>.from(data['favoriteUserIds'] ?? []),
        registerUrl: data['registerUrl'] ?? '',
        createdAt: data['createdAt'] is String
            ? DateTime.parse(data['createdAt'])
            : DateTime.now(),
        updatedAt: data['updatedAt'] is String
            ? DateTime.parse(data['updatedAt'])
            : DateTime.now(),
      );

      debugPrint(
          '📄 Created event with ID: "${event.id}", Title: "${event.title}", Description: "${event.description}"');
      events.add(event);
    }

    return events;
  }

  Future<EventModel?> getEventById(String eventId) async {
    final doc = await eventsCollection.doc(eventId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return EventModel.fromJson(data, documentId: doc.id);
    }
    return null;
  }

  Future<void> addEvent(EventModel event) async {
    await eventsCollection.doc(event.id).set(event.toJson());
  }

  Future<void> updateEvent(EventModel event) async {
    await eventsCollection.doc(event.id).update(event.toJson());
  }

  Future<void> deleteEvent(String eventId) async {
    await eventsCollection.doc(eventId).delete();
  }

  Future<void> toggleFavorite({
    required String eventId,
    required String userId,
    required bool isFavorite,
  }) async {
    // Validate inputs
    if (eventId.isEmpty) {
      throw Exception('Event ID cannot be empty');
    }
    if (userId.isEmpty) {
      throw Exception('User ID cannot be empty');
    }

    final docRef = eventsCollection.doc(eventId);
    final doc = await docRef.get();

    if (!doc.exists) {
      throw Exception('Event not found with ID: $eventId');
    }

    final data = doc.data() as Map<String, dynamic>;
    List<String> favoriteUserIds =
        List<String>.from(data['favoriteUserIds'] ?? []);

    if (isFavorite) {
      if (!favoriteUserIds.contains(userId)) {
        favoriteUserIds.add(userId);
      }
    } else {
      favoriteUserIds.remove(userId);
    }

    await docRef.update({'favoriteUserIds': favoriteUserIds});
  }

  Stream<List<EventModel>> streamAllEvents() {
    return eventsCollection.snapshots().map((snapshot) {
      final events = <EventModel>[];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('🔄 Stream Document ID: "${doc.id}"');

        // Create event with explicit document ID
        final event = EventModel(
          id: doc.id, // Direct assignment
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          category: data['category'] ?? '',
          favoriteUserIds: List<String>.from(data['favoriteUserIds'] ?? []),
          registerUrl: data['registerUrl'] ?? '',
          createdAt: data['createdAt'] is String
              ? DateTime.parse(data['createdAt'])
              : DateTime.now(),
          updatedAt: data['updatedAt'] is String
              ? DateTime.parse(data['updatedAt'])
              : DateTime.now(),
        );

        debugPrint('🔄 Stream created event with ID: "${event.id}"');
        events.add(event);
      }

      return events;
    });
  }
}
