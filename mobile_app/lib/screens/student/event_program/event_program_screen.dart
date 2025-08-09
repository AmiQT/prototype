import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/event_model.dart';
import '../../../services/event_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventProgramScreen extends StatefulWidget {
  const EventProgramScreen({super.key});

  @override
  State<EventProgramScreen> createState() => _EventProgramScreenState();
}

class _EventProgramScreenState extends State<EventProgramScreen> {
  final EventService _eventService = EventService();
  String? _userId;

  // Helper method to validate image URLs
  bool _isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    // Check if it's a data URL (base64)
    if (url.startsWith('data:')) return false;
    // Check if it's a valid HTTP/HTTPS URL
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _userId = user?.uid;
    });
  }

  Future<void> _toggleFavorite(EventModel event) async {
    if (_userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to add favorites')),
        );
      }
      return;
    }

    // Debug logging
    debugPrint('🔄 Toggling favorite for event: ${event.id} (${event.title})');
    debugPrint('🔄 User ID: $_userId');

    if (event.id.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Event ID is missing')),
        );
      }
      return;
    }

    try {
      final isFavorite = event.favoriteUserIds.contains(_userId);
      await _eventService.toggleFavorite(
        eventId: event.id,
        userId: _userId!,
        isFavorite: !isFavorite,
      );

      debugPrint('✅ Successfully toggled favorite status');

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                isFavorite ? 'Removed from favorites' : 'Added to favorites'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error toggling favorite: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating favorites: $e')),
        );
      }
    }
  }

  void _openDetail(EventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailPage(event: event),
      ),
    );
  }

  // Method to add test events to Firebase
  Future<void> _addTestEvents() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Clear existing events first
      final existingEvents = await firestore.collection('events').get();
      for (final doc in existingEvents.docs) {
        await doc.reference.delete();
      }

      // Add properly structured test events
      final testEvents = [
        {
          'title': 'RISE UTHM',
          'description':
              'Research, Innovation, and Startup Ecosystem at UTHM. Join us for an exciting event showcasing the latest research and innovation projects.',
          'imageUrl':
              'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800&h=400&fit=crop',
          'category': 'Research',
          'favoriteUserIds': [],
          'registerUrl': 'https://example.com/register/rise-uthm',
          'createdAt': DateTime.now()
              .subtract(const Duration(days: 2))
              .toIso8601String(),
          'updatedAt': DateTime.now()
              .subtract(const Duration(days: 2))
              .toIso8601String(),
        },
        {
          'title': 'Tech Innovation Summit',
          'description':
              'Discover the latest technological innovations and network with industry leaders in this comprehensive summit.',
          'imageUrl':
              'https://images.unsplash.com/photo-1559136555-9303baea8ebd?w=800&h=400&fit=crop',
          'category': 'Technology',
          'favoriteUserIds': [],
          'registerUrl': 'https://example.com/register/tech-summit',
          'createdAt': DateTime.now()
              .subtract(const Duration(days: 1))
              .toIso8601String(),
          'updatedAt': DateTime.now()
              .subtract(const Duration(days: 1))
              .toIso8601String(),
        },
        {
          'title': 'Career Development Workshop',
          'description':
              'Enhance your professional skills and learn about career opportunities in various industries.',
          'imageUrl': '', // Empty to test placeholder
          'category': 'Career',
          'favoriteUserIds': [],
          'registerUrl': 'https://example.com/register/career-workshop',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      ];

      // Add events to Firebase
      for (int i = 0; i < testEvents.length; i++) {
        await firestore
            .collection('events')
            .doc('event_${i + 1}')
            .set(testEvents[i]);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Test events added successfully!'),
            duration: Duration(seconds: 3),
          ),
        );
      }

      debugPrint('✅ Test events added successfully!');
    } catch (e) {
      debugPrint('❌ Error adding test events: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error adding test events: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event'),
        centerTitle: true,
        elevation: 0.5,
        actions: [
          // Test button to add sample events
          IconButton(
            icon: const Icon(Icons.add_circle),
            tooltip: 'Add Test Events',
            onPressed: () async {
              await _addTestEvents();
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            tooltip: 'View favorite events',
            onPressed: () async {
              final userId = _userId;
              if (userId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please log in to view favorites.')),
                );
                return;
              }
              final allEvents = await _eventService.streamAllEvents().first;
              final favoriteEvents = allEvents
                  .where((e) => e.favoriteUserIds.contains(userId))
                  .toList();
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FavoriteEventsPage(favoriteEvents: favoriteEvents),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: _eventService.streamAllEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return const Center(
              child: Text('No events found.',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final isFavorite =
                  _userId != null && event.favoriteUserIds.contains(_userId);
              return Card(
                margin: const EdgeInsets.only(bottom: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Stack(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _openDetail(event),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                                child: Tooltip(
                                  message: 'Event image: ${event.title}',
                                  child: event.imageUrl.isNotEmpty &&
                                          _isValidImageUrl(event.imageUrl)
                                      ? Image.network(
                                          event.imageUrl,
                                          height: 160,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return Container(
                                              height: 160,
                                              color: Colors.grey[200],
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  value: loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                      : null,
                                                ),
                                              ),
                                            );
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            debugPrint(
                                                'Error loading event image: $error');
                                            return Container(
                                              height: 160,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Colors.grey[300]!,
                                                    Colors.grey[400]!,
                                                  ],
                                                ),
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .image_not_supported_outlined,
                                                    size: 48,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Image not available',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          semanticLabel:
                                              'Event image: ${event.title}',
                                        )
                                      : Container(
                                          height: 160,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Colors.grey[300]!,
                                                Colors.grey[400]!,
                                              ],
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.event_outlined,
                                                size: 48,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Event Image',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: GestureDetector(
                                  onTap: () async {
                                    await _toggleFavorite(event);
                                    setState(() {});
                                  },
                                  child: Tooltip(
                                    message: isFavorite
                                        ? 'Remove from favorites'
                                        : 'Add to favorites',
                                    child: CircleAvatar(
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        isFavorite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isFavorite
                                            ? Colors.red
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue[600]!,
                                            Colors.blue[700]!,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue
                                                .withValues(alpha: 0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        event.category.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  event.title.isNotEmpty
                                      ? event.title
                                      : 'Untitled Event',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  event.description.isNotEmpty
                                      ? event.description
                                      : 'No description available',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[700],
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class EventDetailPage extends StatelessWidget {
  final EventModel event;
  const EventDetailPage({required this.event, super.key});

  // Helper method to validate image URLs
  static bool _isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    // Check if it's a data URL (base64)
    if (url.startsWith('data:')) return false;
    // Check if it's a valid HTTP/HTTPS URL
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final isFavorite = userId != null && event.favoriteUserIds.contains(userId);
    final eventService = EventService();
    return Scaffold(
      appBar: AppBar(
        title: Text(event.title.isNotEmpty ? event.title : 'Event Details'),
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.grey),
            tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
            onPressed: userId == null
                ? null
                : () async {
                    await eventService.toggleFavorite(
                      eventId: event.id,
                      userId: userId,
                      isFavorite: !isFavorite,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isFavorite
                            ? 'Removed from favorites'
                            : 'Added to favorites'),
                      ),
                    );
                  },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share event',
            onPressed: () {
              Share.share('Check out this event: ${event.title}');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Tooltip(
                message: 'Event image: ${event.title}',
                child: event.imageUrl.isNotEmpty &&
                        _isValidImageUrl(event.imageUrl)
                    ? Image.network(
                        event.imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint(
                              'Error loading event detail image: $error');
                          return Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.broken_image,
                                    size: 64, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text(
                                  'Image not available',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        semanticLabel: 'Event image: ${event.title}',
                      )
                    : Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.image,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              'No image',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    event.category,
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              event.title.isNotEmpty ? event.title : 'Untitled Event',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(height: 10),
            Text(
              event.description.isNotEmpty
                  ? event.description
                  : 'No description available',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: const Text('Register'),
                  onPressed: () async {
                    final url = Uri.parse(event.registerUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open link.')),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoriteEventsPage extends StatelessWidget {
  final List<EventModel> favoriteEvents;
  const FavoriteEventsPage({required this.favoriteEvents, super.key});

  // Helper method to validate image URLs
  static bool _isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    // Check if it's a data URL (base64)
    if (url.startsWith('data:')) return false;
    // Check if it's a valid HTTP/HTTPS URL
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Events'),
      ),
      body: favoriteEvents.isEmpty
          ? const Center(child: Text('No favorite events added.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favoriteEvents.length,
              itemBuilder: (context, index) {
                final event = favoriteEvents[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EventDetailPage(event: event),
                        ),
                      );
                    },
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: event.imageUrl.isNotEmpty &&
                                _isValidImageUrl(event.imageUrl)
                            ? Image.network(
                                event.imageUrl,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 56,
                                    height: 56,
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint(
                                      'Error loading favorite event image: $error');
                                  return Container(
                                    width: 56,
                                    height: 56,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image,
                                        color: Colors.grey),
                                  );
                                },
                              )
                            : Container(
                                width: 56,
                                height: 56,
                                color: Colors.grey[200],
                                child:
                                    const Icon(Icons.image, color: Colors.grey),
                              ),
                      ),
                      title: Text(event.title.isNotEmpty
                          ? event.title
                          : 'Untitled Event'),
                      subtitle: Text(event.category),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
