import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_model.dart';
import 'auto_notification_service.dart';
import '../config/supabase_config.dart';

class EventService {
  static const String baseUrl =
      'https://prototype-348e.onrender.com'; // Render backend

  static int _backendFailureCount = 0;

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
        debugPrint('EventService: No auth token, trying Supabase fallback');
        return await _getEventsFromSupabase();
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
          final event = EventModel(
            id: eventData['id'] ?? '',
            title: eventData['title'] ?? '',
            description: eventData['description'] ?? '',
            imageUrl: eventData['image_url'] ?? eventData['imageUrl'] ?? '',
            category: eventData['category'] ?? '',
            favoriteUserIds: [], // Will be handled separately
            registerUrl:
                eventData['register_url'] ?? eventData['registerUrl'] ?? '',
            createdAt: eventData['created_at'] != null
                ? DateTime.parse(eventData['created_at'])
                : DateTime.now(),
            updatedAt: eventData['updated_at'] != null
                ? DateTime.parse(eventData['updated_at'])
                : DateTime.now(),
          );

          events.add(event);
        }

        return events;
      } else {
        _backendFailureCount++;
        // Only log every 10th failure to reduce spam
        if (_backendFailureCount % 10 == 1) {
          debugPrint(
              'EventService: Backend failed (${response.statusCode}), trying Supabase fallback [Failure #$_backendFailureCount]');
        }
        return await _getEventsFromSupabase();
      }
    } catch (e) {
      debugPrint('❌ Error loading events from backend: $e');
      return await _getEventsFromSupabase();
    }
  }

  /// Fallback method to get events from Supabase directly
  Future<List<EventModel>> _getEventsFromSupabase() async {
    try {
      final response = await SupabaseConfig.client
          .from('events')
          .select('*')
          .eq('is_active', true) // Only get active events
          .order('created_at', ascending: false);

      final events = <EventModel>[];
      for (final eventData in response) {
        // Map Supabase fields to EventModel fields
        final event = EventModel(
          id: eventData['id'] ?? '',
          title: eventData['title'] ?? '',
          description: eventData['description'] ?? '',
          imageUrl: _getDefaultEventImage(eventData['title'] ?? 'Event') ??
              '', // Use default image or empty string
          category: _getCategoryFromLocation(
              eventData['location']), // Derive category from location
          favoriteUserIds: [], // Will be populated below
          registerUrl: '', // Events table doesn't have register_url field
          createdAt: eventData['created_at'] != null
              ? DateTime.parse(eventData['created_at'])
              : DateTime.now(),
          updatedAt: eventData['updated_at'] != null
              ? DateTime.parse(eventData['updated_at'])
              : DateTime.now(),
        );

        events.add(event);
      }

      // Populate favorite data for all events
      await _populateFavoriteData(events);

      return events;
    } catch (e) {
      debugPrint('❌ Error loading events from Supabase: $e');
      return []; // Return empty list if both backend and Supabase fail
    }
  }

  /// Populate favorite data for events
  Future<void> _populateFavoriteData(List<EventModel> events) async {
    try {
      // Get all favorite relationships
      final favoritesResponse = await SupabaseConfig.client
          .from('event_favorites')
          .select('event_id, user_id');

      // Group favorites by event_id
      final Map<String, List<String>> favoritesMap = {};
      for (final favorite in favoritesResponse) {
        final eventId = favorite['event_id'] as String;
        final userId = favorite['user_id'] as String;

        if (!favoritesMap.containsKey(eventId)) {
          favoritesMap[eventId] = [];
        }
        favoritesMap[eventId]!.add(userId);
      }

      // Update events with favorite data
      for (int i = 0; i < events.length; i++) {
        final event = events[i];
        final favoriteUserIds = favoritesMap[event.id] ?? [];

        // Create new event with updated favorite data
        events[i] = event.copyWith(favoriteUserIds: favoriteUserIds);
      }
    } catch (e) {
      debugPrint('EventService: Error populating favorite data: $e');
      // Don't throw error, just log it - events will still work without favorite data
    }
  }

  /// Helper method to derive category from location
  String _getCategoryFromLocation(String? location) {
    if (location == null || location.isEmpty) return 'General';

    final locationLower = location.toLowerCase();
    if (locationLower.contains('computer') || locationLower.contains('lab')) {
      return 'Technology';
    } else if (locationLower.contains('engineering') ||
        locationLower.contains('workshop')) {
      return 'Engineering';
    } else if (locationLower.contains('dewan') ||
        locationLower.contains('hall')) {
      return 'Conference';
    } else {
      return 'General';
    }
  }

  /// Get default event image based on event title
  String? _getDefaultEventImage(String title) {
    // Return null for all events - let users upload their own images
    // No more hardcoded Unsplash images
    return null;
  }

  Future<EventModel?> getEventById(String eventId) async {
    try {
      debugPrint('EventService: Getting event by ID: $eventId');

      // Try backend first
      try {
        final token = await _getAuthToken();
        if (token != null) {
          final response = await http.get(
            Uri.parse('$baseUrl/api/events/$eventId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          if (response.statusCode == 200) {
            final eventData = json.decode(response.body);
            debugPrint(
                'EventService: Event loaded from backend: ${eventData['title']}');
            return EventModel(
              id: eventData['id'] ?? '',
              title: eventData['title'] ?? '',
              description: eventData['description'] ?? '',
              imageUrl: eventData['image_url'] ?? eventData['imageUrl'] ?? '',
              category: eventData['category'] ?? '',
              favoriteUserIds: [], // Will be handled separately
              registerUrl:
                  eventData['register_url'] ?? eventData['registerUrl'] ?? '',
              createdAt: eventData['created_at'] != null
                  ? DateTime.parse(eventData['created_at'])
                  : DateTime.now(),
              updatedAt: eventData['updated_at'] != null
                  ? DateTime.parse(eventData['updated_at'])
                  : DateTime.now(),
            );
          } else {
            debugPrint(
                'EventService: Backend getEventById failed: ${response.statusCode}');
          }
        }
      } catch (e) {
        debugPrint('EventService: Backend getEventById error: $e');
      }

      // Fallback to Supabase
      debugPrint('EventService: Using Supabase fallback for getEventById');
      return await _getEventFromSupabase(eventId);
    } catch (e) {
      debugPrint('❌ Error loading event: $e');
      return null;
    }
  }

  /// Get single event from Supabase
  Future<EventModel?> _getEventFromSupabase(String eventId) async {
    try {
      debugPrint('EventService: Getting event from Supabase: $eventId');

      final response = await SupabaseConfig.client
          .from('events')
          .select('*')
          .eq('id', eventId)
          .eq('is_active', true)
          .maybeSingle();

      if (response != null) {
        debugPrint(
            'EventService: Event found in Supabase: ${response['title']}');

        final event = EventModel(
          id: response['id'] ?? eventId,
          title: response['title'] ?? '',
          description: response['description'] ?? '',
          imageUrl: _getDefaultEventImage(response['title'] ?? 'Event') ??
              '', // Use default image or empty string
          category: _getCategoryFromLocation(response['location'] ?? ''),
          favoriteUserIds: [], // Will be populated below
          registerUrl: '', // Not available in Supabase events table
          createdAt: response['created_at'] != null
              ? DateTime.parse(response['created_at'])
              : DateTime.now(),
          updatedAt: response['updated_at'] != null
              ? DateTime.parse(response['updated_at'])
              : DateTime.now(),
        );

        // Populate favorite data for this single event
        await _populateFavoriteData([event]);

        return event;
      } else {
        debugPrint('EventService: Event not found in Supabase: $eventId');
        return null;
      }
    } catch (e) {
      debugPrint('EventService: Error getting event from Supabase: $e');
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

      debugPrint(
          'EventService: Toggling favorite for event $eventId, user $userId, favorite: $isFavorite');

      // Try backend first
      try {
        final token = await _getAuthToken();
        if (token != null) {
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

          if (response.statusCode == 200) {
            debugPrint(
                'EventService: Favorite toggled successfully via backend');
            await _handleFavoriteNotification(eventId, userId, isFavorite);
            return;
          } else {
            debugPrint(
                'EventService: Backend favorite toggle failed: ${response.statusCode}');
          }
        }
      } catch (e) {
        debugPrint('EventService: Backend favorite toggle error: $e');
      }

      // Fallback to Supabase or local storage
      debugPrint('EventService: Using fallback for favorite toggle');
      await _toggleFavoriteFallback(eventId, userId, isFavorite);
      await _handleFavoriteNotification(eventId, userId, isFavorite);
    } catch (e) {
      debugPrint('❌ Error toggling favorite: $e');
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  /// Fallback method for favorite toggle using Supabase or local storage
  Future<void> _toggleFavoriteFallback(
      String eventId, String userId, bool isFavorite) async {
    try {
      // Try Supabase first
      try {
        debugPrint('EventService: Attempting Supabase favorite toggle...');

        if (isFavorite) {
          // Add to favorites
          final result =
              await SupabaseConfig.client.from('event_favorites').upsert({
            'user_id': userId,
            'event_id': eventId,
            'created_at': DateTime.now().toIso8601String(),
          });
          debugPrint('EventService: Supabase upsert result: $result');
        } else {
          // Remove from favorites
          final result = await SupabaseConfig.client
              .from('event_favorites')
              .delete()
              .eq('user_id', userId)
              .eq('event_id', eventId);
          debugPrint('EventService: Supabase delete result: $result');
        }
        debugPrint('EventService: Favorite toggled successfully via Supabase');
        return;
      } catch (e) {
        debugPrint('EventService: Supabase favorite toggle failed: $e');
        // Check if it's a table not found error
        if (e.toString().contains('event_favorites') &&
            e.toString().contains('Not Found')) {
          debugPrint(
              'EventService: event_favorites table not found, please create it in Supabase');
        }
      }

      // Fallback to local storage (SharedPreferences)
      debugPrint('EventService: Falling back to local storage...');
      await _toggleFavoriteLocal(eventId, userId, isFavorite);
    } catch (e) {
      debugPrint('EventService: Fallback favorite toggle error: $e');
      // Don't throw error, just log it - favorite is not critical functionality
    }
  }

  /// Local storage fallback for favorites
  Future<void> _toggleFavoriteLocal(
      String eventId, String userId, bool isFavorite) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'favorite_events_$userId';
      final favoriteEvents = prefs.getStringList(key) ?? [];

      if (isFavorite) {
        if (!favoriteEvents.contains(eventId)) {
          favoriteEvents.add(eventId);
        }
      } else {
        favoriteEvents.remove(eventId);
      }

      await prefs.setStringList(key, favoriteEvents);
      debugPrint(
          'EventService: Favorite toggled successfully via local storage');
    } catch (e) {
      debugPrint('EventService: Local storage favorite toggle error: $e');
    }
  }

  /// Handle favorite notification
  Future<void> _handleFavoriteNotification(
      String eventId, String userId, bool isFavorite) async {
    try {
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
      debugPrint('EventService: Error handling favorite notification: $e');
    }
  }

  /// Check if event is favorited by user
  Future<bool> isEventFavorited(String eventId, String userId) async {
    try {
      debugPrint(
          'EventService: Checking favorite status for event $eventId, user $userId');

      // Try Supabase first
      try {
        final response = await SupabaseConfig.client
            .from('event_favorites')
            .select('id')
            .eq('user_id', userId)
            .eq('event_id', eventId)
            .maybeSingle();

        if (response != null) {
          debugPrint('EventService: Event is favorited in Supabase');
          return true;
        } else {
          debugPrint('EventService: Event not found in Supabase favorites');
        }
      } catch (e) {
        debugPrint('EventService: Supabase favorite check failed: $e');
        if (e.toString().contains('event_favorites') &&
            e.toString().contains('Not Found')) {
          debugPrint(
              'EventService: event_favorites table not found, using local storage');
        }
      }

      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final key = 'favorite_events_$userId';
      final favoriteEvents = prefs.getStringList(key) ?? [];
      final isLocalFavorite = favoriteEvents.contains(eventId);
      debugPrint(
          'EventService: Local storage favorite status: $isLocalFavorite');
      return isLocalFavorite;
    } catch (e) {
      debugPrint('EventService: Error checking favorite status: $e');
      return false;
    }
  }

  /// Get all favorited events for a user
  Future<List<String>> getFavoriteEventIds(String userId) async {
    try {
      debugPrint('EventService: Getting favorite events for user $userId');

      // Try Supabase first
      try {
        final response = await SupabaseConfig.client
            .from('event_favorites')
            .select('event_id')
            .eq('user_id', userId);

        if (response.isNotEmpty) {
          final eventIds =
              response.map((item) => item['event_id'] as String).toList();
          debugPrint(
              'EventService: Found ${eventIds.length} favorites in Supabase');
          return eventIds;
        } else {
          debugPrint('EventService: No favorites found in Supabase');
        }
      } catch (e) {
        debugPrint('EventService: Supabase favorite list failed: $e');
        if (e.toString().contains('event_favorites') &&
            e.toString().contains('Not Found')) {
          debugPrint(
              'EventService: event_favorites table not found, using local storage');
        }
      }

      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final key = 'favorite_events_$userId';
      final localFavorites = prefs.getStringList(key) ?? [];
      debugPrint(
          'EventService: Found ${localFavorites.length} favorites in local storage');
      return localFavorites;
    } catch (e) {
      debugPrint('EventService: Error getting favorite events: $e');
      return [];
    }
  }

  Stream<List<EventModel>> streamAllEvents() {
    // For now, we'll use periodic polling instead of real-time streams
    // Implement real-time updates using periodic polling
    // In production, replace with WebSocket or Server-Sent Events

    // Create a controller to emit initial data immediately
    final controller = StreamController<List<EventModel>>();

    // Load initial data
    getAllEvents().then((initialEvents) {
      debugPrint(
          'EventService: Stream started with ${initialEvents.length} events');
      controller.add(initialEvents);
    }).catchError((error) {
      debugPrint('❌ Error loading initial events: $error');
      controller.add(<EventModel>[]);
    });

    // Set up periodic updates
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        final events = await getAllEvents();
        controller.add(events);
      } catch (error) {
        debugPrint('❌ Error in periodic update: $error');
      }
    });

    return controller.stream;
  }

  // Helper method to get events with polling
  Stream<List<EventModel>> streamEventsWithPolling({Duration? interval}) {
    return Stream.periodic(interval ?? const Duration(seconds: 30),
            (_) async => await getAllEvents())
        .asyncMap((future) => future)
        .handleError((error) {
      debugPrint('❌ Error in event polling: $error');
      return <EventModel>[];
    });
  }
}
