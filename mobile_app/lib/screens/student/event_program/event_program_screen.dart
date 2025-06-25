import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class EventProgramScreen extends StatefulWidget {
  const EventProgramScreen({Key? key}) : super(key: key);

  @override
  State<EventProgramScreen> createState() => _EventProgramScreenState();
}

class _EventProgramScreenState extends State<EventProgramScreen> {
  final List<Map<String, dynamic>> _events = [
    {
      'title': 'UTHM Innovation Day',
      'image': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
      'description':
          'A day to showcase student and staff innovations. Join us for talks, exhibitions, and networking!',
      'category': 'Innovation',
      'favorite': false,
      'registerUrl': 'https://forms.gle/uthm-innovation',
    },
    {
      'title': 'Sports Carnival 2024',
      'image': 'https://images.unsplash.com/photo-1517649763962-0c623066013b',
      'description':
          'Annual sports event for all students. Compete, have fun, and win prizes!',
      'category': 'Sports',
      'favorite': false,
      'registerUrl': 'https://forms.gle/uthm-sports',
    },
    {
      'title': 'Career Fair',
      'image': 'https://images.unsplash.com/photo-1464983953574-0892a716854b',
      'description':
          'Meet top employers and explore job opportunities. Bring your resume!',
      'category': 'Career',
      'favorite': false,
      'registerUrl': 'https://forms.gle/uthm-career',
    },
  ];

  bool _isRefreshing = false;

  Future<void> _refreshEvents() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isRefreshing = false);
  }

  void _toggleFavorite(int index) {
    setState(() {
      _events[index]['favorite'] = !_events[index]['favorite'];
    });
  }

  void _openDetail(Map<String, dynamic> event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailPage(event: event),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events & Programs'),
        centerTitle: true,
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshEvents,
        child: _isRefreshing
            ? const Center(child: CircularProgressIndicator())
            : _events.isEmpty
                ? const Center(
                    child: Text('No events or programs found.',
                        style: TextStyle(fontSize: 16, color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final event = _events[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        child: InkWell(
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
                                      message: 'Event image: ${event['title']}',
                                      child: Image.network(
                                        event['image'],
                                        height: 160,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                          height: 160,
                                          color: Colors.grey[200],
                                          child: const Center(
                                              child: Icon(Icons.broken_image,
                                                  size: 48,
                                                  color: Colors.grey)),
                                        ),
                                        semanticLabel:
                                            'Event image: ${event['title']}',
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: GestureDetector(
                                      onTap: () => _toggleFavorite(index),
                                      child: Tooltip(
                                        message: event['favorite']
                                            ? 'Remove from favorites'
                                            : 'Add to favorites',
                                        child: CircleAvatar(
                                          backgroundColor: Colors.white,
                                          child: Icon(
                                            event['favorite']
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: event['favorite']
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
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            event['category'],
                                            style: TextStyle(
                                              color: Colors.blue[700],
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      event['title'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      event['description'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 15, color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class EventDetailPage extends StatelessWidget {
  final Map<String, dynamic> event;
  const EventDetailPage({required this.event, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event['title']),
        actions: [
          IconButton(
            icon: Icon(
                event['favorite'] ? Icons.favorite : Icons.favorite_border,
                color: event['favorite'] ? Colors.red : Colors.grey),
            tooltip: event['favorite']
                ? 'Remove from favorites'
                : 'Add to favorites',
            onPressed: () {}, // Could implement favorite toggle here if needed
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share event',
            onPressed: () {
              Share.share('Check out this event: ${event['title']}');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Tooltip(
              message: 'Event image: ${event['title']}',
              child: Image.network(
                event['image'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(
                      child: Icon(Icons.broken_image,
                          size: 48, color: Colors.grey)),
                ),
                semanticLabel: 'Event image: ${event['title']}',
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
                  event['category'],
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
            event['title'],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          const SizedBox(height: 10),
          Text(
            event['description'],
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.app_registration),
            label: const Text('Register'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            onPressed: () async {
              final url = Uri.parse(event['registerUrl']);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Could not open registration link.')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
