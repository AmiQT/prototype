import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_model.dart';
import '../models/event_registration_model.dart';
import '../models/profile_model.dart';
import 'auto_notification_service.dart';
import '../config/supabase_config.dart';
import '../config/backend_config.dart';

class EventService {
  static const String baseUrl =
      BackendConfig.baseUrl; // Use stable cloud backend

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
    final stopwatch = Stopwatch()..start();
    try {
      // MOBILE APP OPTIMIZATION: Skip custom backend, use Supabase directly
      debugPrint(
          'EventService: Using Supabase directly for mobile app (no custom backend delays)');
      final result = await _getEventsFromSupabase();
      stopwatch.stop();
      debugPrint(
          'EventService: Direct Supabase completed in ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } catch (e) {
      stopwatch.stop();
      debugPrint(
          '❌ Error loading events from Supabase in ${stopwatch.elapsedMilliseconds}ms: $e');
      return []; // Return empty list on error
    }
  }

  /// Fallback method to get events from Supabase directly
  Future<List<EventModel>> _getEventsFromSupabase() async {
    try {
      final response = await SupabaseConfig.client
          .from('events')
          .select('*')
          .eq('is_active', true) // Only get active events
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 5)); // Prevent hanging

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

  // ==================== EVENT REGISTRATION METHODS ====================

  Future<EventRegistrationModel?> registerForEvent({
    required String eventId,
    required ProfileModel userProfile,
  }) async {
    try {
      debugPrint('🔵 EventService: Starting registration for event $eventId');

      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ EventService: No authenticated user');
        return null;
      }

      debugPrint('🔵 EventService: User ID: $userId');

      // Check if already registered
      debugPrint('🔵 EventService: Checking if already registered...');
      final alreadyRegistered = await isRegisteredForEvent(eventId, userId);
      if (alreadyRegistered) {
        debugPrint(
            '⚠️ EventService: User already registered for event $eventId');
        return null;
      }

      debugPrint('🔵 EventService: User not registered yet, proceeding...');

      // Get event to check capacity (OPTIONAL - skip if event doesn't have registration fields yet)
      final event = await getEventById(eventId);
      if (event == null) {
        debugPrint(
            '⚠️ EventService: Event $eventId not found, but continuing with registration');
        // Continue anyway - event exists in database
      } else {
        debugPrint('🔵 EventService: Event found: ${event.title}');

        // Only check canRegister if event has registration fields
        if (event.registrationOpen != null && !event.canRegister) {
          debugPrint(
              '❌ EventService: Cannot register - ${event.registrationStatus}');
          return null;
        }
      }

      // Auto-fill registration data from profile
      debugPrint(
          '🔵 EventService: Creating registration with auto-filled data...');
      final registration = EventRegistrationModel(
        eventId: eventId,
        userId: userId,
        registrationDate: DateTime.now(),
        attendanceStatus: 'pending',
        fullName: userProfile.fullName,
        studentId: userProfile.academicInfo?.studentId ?? '',
        phone: userProfile.phoneNumber ?? '',
        email: SupabaseConfig.auth.currentUser?.email ?? '',
        program: userProfile.academicInfo?.program ?? '',
        department: userProfile.academicInfo?.department ?? '',
        faculty: userProfile.academicInfo?.faculty ?? '',
        relevantSkills: userProfile.skills,
      );

      debugPrint('🔵 EventService: Registration data prepared');
      final dataToInsert = registration.toJsonForInsert();
      debugPrint('🔵 EventService: Data to insert: $dataToInsert');

      debugPrint('🔵 EventService: Inserting into database...');

      // Insert into database
      final response = await SupabaseConfig.client
          .from('event_participations')
          .insert(dataToInsert)
          .select()
          .single();

      debugPrint('✅ EventService: Successfully registered for event $eventId');
      debugPrint('🔵 EventService: Response: $response');

      // Update current participants count in events table (only if event has the field)
      if (event != null && event.maxParticipants != null) {
        debugPrint('🔵 EventService: Updating participant count...');
        await _incrementParticipantCount(eventId);
      }

      // Send confirmation notification
      debugPrint('🔵 EventService: Sending confirmation notification...');
      await AutoNotificationService.sendEventRegistrationConfirmation(
        eventTitle: event?.title ?? 'Event',
        eventDate: event?.eventDate ?? DateTime.now(),
      );

      return EventRegistrationModel.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint(
          '❌ EventService: PostgrestException - Code: ${e.code}, Message: ${e.message}');
      debugPrint('❌ EventService: Details: ${e.details}');
      debugPrint('❌ EventService: Hint: ${e.hint}');
      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ EventService: Error registering for event: $e');
      debugPrint('❌ EventService: Stack trace: $stackTrace');
      return null;
    }
  }

  /// Check if user is registered for an event
  Future<bool> isRegisteredForEvent(String eventId, String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('event_participations')
          .select('id')
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('❌ EventService: Error checking registration: $e');
      return false;
    }
  }

  /// Get all events the user has registered for
  Future<List<EventRegistrationModel>> getRegisteredEvents(
      String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('event_participations')
          .select()
          .eq('user_id', userId)
          .order('registration_date', ascending: false);

      return (response as List)
          .map((json) => EventRegistrationModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ EventService: Error fetching registered events: $e');
      return [];
    }
  }

  /// Get registration details for a specific event
  Future<EventRegistrationModel?> getRegistrationDetails(
      String eventId, String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('event_participations')
          .select()
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;

      return EventRegistrationModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ EventService: Error fetching registration details: $e');
      return null;
    }
  }

  /// Cancel event registration
  Future<bool> cancelRegistration(String eventId, String userId) async {
    try {
      await SupabaseConfig.client
          .from('event_participations')
          .delete()
          .eq('event_id', eventId)
          .eq('user_id', userId);

      debugPrint('✅ EventService: Successfully cancelled registration');

      // Decrement participant count
      await _decrementParticipantCount(eventId);

      return true;
    } catch (e) {
      debugPrint('❌ EventService: Error cancelling registration: $e');
      return false;
    }
  }

  /// Submit feedback for attended event
  Future<bool> submitEventFeedback({
    required String eventId,
    required String userId,
    required double rating,
    String? comment,
  }) async {
    try {
      await SupabaseConfig.client
          .from('event_participations')
          .update({
            'feedback_rating': rating,
            'feedback_comment': comment,
          })
          .eq('event_id', eventId)
          .eq('user_id', userId);

      debugPrint('✅ EventService: Successfully submitted feedback');
      return true;
    } catch (e) {
      debugPrint('❌ EventService: Error submitting feedback: $e');
      return false;
    }
  }

  /// Update attendance status (for organizers/admins)
  Future<bool> updateAttendanceStatus({
    required String eventId,
    required String userId,
    required String status, // 'confirmed', 'attended', 'cancelled'
  }) async {
    try {
      await SupabaseConfig.client
          .from('event_participations')
          .update({'attendance_status': status})
          .eq('event_id', eventId)
          .eq('user_id', userId);

      debugPrint('✅ EventService: Successfully updated attendance status');
      return true;
    } catch (e) {
      debugPrint('❌ EventService: Error updating attendance status: $e');
      return false;
    }
  }

  /// Get participant count for an event
  Future<int> getParticipantCount(String eventId) async {
    try {
      final response = await SupabaseConfig.client
          .from('event_participations')
          .select('id')
          .eq('event_id', eventId);

      return (response as List).length;
    } catch (e) {
      debugPrint('❌ EventService: Error getting participant count: $e');
      return 0;
    }
  }

  /// Helper: Increment participant count in events table
  Future<void> _incrementParticipantCount(String eventId) async {
    try {
      // Get current count
      final event = await getEventById(eventId);
      if (event == null) return;

      final newCount = (event.currentParticipants ?? 0) + 1;

      await SupabaseConfig.client
          .from('events')
          .update({'current_participants': newCount}).eq('id', eventId);

      debugPrint('✅ EventService: Incremented participant count to $newCount');
    } catch (e) {
      debugPrint('❌ EventService: Error incrementing participant count: $e');
    }
  }

  /// Helper: Decrement participant count in events table
  Future<void> _decrementParticipantCount(String eventId) async {
    try {
      // Get current count
      final event = await getEventById(eventId);
      if (event == null) return;

      final newCount = (event.currentParticipants ?? 1) - 1;
      final finalCount = newCount < 0 ? 0 : newCount;

      await SupabaseConfig.client
          .from('events')
          .update({'current_participants': finalCount}).eq('id', eventId);

      debugPrint(
          '✅ EventService: Decremented participant count to $finalCount');
    } catch (e) {
      debugPrint('❌ EventService: Error decrementing participant count: $e');
    }
  }
}
