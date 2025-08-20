import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import 'auto_notification_service.dart';
import '../config/supabase_config.dart';

class EventService {
  static const String baseUrl = 'https://c3168f89d034.ngrok-free.app'; // ngrok tunnel
  
  // Get Supabase auth token for authentication
  static Future<String?> _getAuthToken() async {
    try {
      final session = SupabaseConfig.auth.currentSession;
      if (session?.accessToken != null) {
        return session!.accessToken;
      }
      return null;
    } catch (e) {
      debugPrint('EventService: Error getting auth token: $e');
      return null;
    }
  }

  Future<List<EventModel>> getAllEvents() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/events'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> eventsJson = data['events'] ?? data;
        
        final events = <EventModel>[];
        for (final eventData in eventsJson) {
          debugPrint('📄 Backend Event Data: $eventData');
          
          final event = EventModel(
            id: eventData['id'] ?? '',
            title: eventData['title'] ?? '',
            description: eventData['description'] ?? '',
            imageUrl: eventData['image_url'] ?? eventData['imageUrl'] ?? '',
            category: eventData['category'] ?? '',
            favoriteUserIds: [], // Will be handled separately
            registerUrl: eventData['register_url'] ?? eventData['registerUrl'] ?? '',
            createdAt: eventData['created_at'] != null 
                ? DateTime.parse(eventData['created_at'])
                : DateTime.now(),
            updatedAt: eventData['updated_at'] != null
                ? DateTime.parse(eventData['updated_at'])
                : DateTime.now(),
          );
          
          debugPrint('📄 Created event: ${event.title}');
          events.add(event);
        }

        return events;
      } else {
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error loading events: $e');
      throw Exception('Failed to load events: $e');
    }
  }

  Future<EventModel?> getEventById(String eventId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/events/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final eventData = json.decode(response.body);
        return EventModel(
          id: eventData['id'] ?? '',
          title: eventData['title'] ?? '',
          description: eventData['description'] ?? '',
          imageUrl: eventData['image_url'] ?? eventData['imageUrl'] ?? '',
          category: eventData['category'] ?? '',
          favoriteUserIds: [], // Will be handled separately
          registerUrl: eventData['register_url'] ?? eventData['registerUrl'] ?? '',
          createdAt: eventData['created_at'] != null 
              ? DateTime.parse(eventData['created_at'])
              : DateTime.now(),
          updatedAt: eventData['updated_at'] != null
              ? DateTime.parse(eventData['updated_at'])
              : DateTime.now(),
        );
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load event: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error loading event: $e');
      return null;
    }
  }

  Future<void> addEvent(EventModel event) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/events'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'title': event.title,
          'description': event.description,
          'category': event.category,
          'image_url': event.imageUrl,
          'register_url': event.registerUrl,
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to create event: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error creating event: $e');
      throw Exception('Failed to create event: $e');
    }
  }

  Future<void> updateEvent(EventModel event) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/events/${event.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'title': event.title,
          'description': event.description,
          'category': event.category,
          'image_url': event.imageUrl,
          'register_url': event.registerUrl,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update event: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error updating event: $e');
      throw Exception('Failed to update event: $e');
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/events/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete event: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error deleting event: $e');
      throw Exception('Failed to delete event: $e');
    }
  }

  Future<void> toggleFavorite({
    required String eventId,
    required String userId,
    required bool isFavorite,
  }) async {
    try {
      // Validate inputs
      if (eventId.isEmpty) {
        throw Exception('Event ID cannot be empty');
      }
      if (userId.isEmpty) {
        throw Exception('User ID cannot be empty');
      }

      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/events/$eventId/favorite'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'is_favorite': isFavorite,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to toggle favorite: ${response.statusCode}');
      }

      // Create notification when user favorites an event
      if (isFavorite) {
        final event = await getEventById(eventId);
        if (event != null) {
          await AutoNotificationService.onEventFavorited(
            userId: userId,
            eventTitle: event.title,
            eventId: eventId,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error toggling favorite: $e');
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  Stream<List<EventModel>> streamAllEvents() {
    // For now, we'll use periodic polling instead of real-time streams
    // TODO: Implement WebSocket or Server-Sent Events for real-time updates
    return Stream.periodic(const Duration(seconds: 30), (_) async {
      return await getAllEvents();
    }).asyncMap((future) => future).handleError((error) {
      debugPrint('❌ Error in event stream: $error');
      return <EventModel>[];
    });
  }

  // Helper method to get events with polling
  Stream<List<EventModel>> streamEventsWithPolling({Duration? interval}) {
    return Stream.periodic(
      interval ?? const Duration(seconds: 30), 
      (_) async => await getAllEvents()
    ).asyncMap((future) => future).handleError((error) {
      debugPrint('❌ Error in event polling: $error');
      return <EventModel>[];
    });
  }
}
