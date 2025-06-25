import 'package:flutter/material.dart';
import '../../../widgets/showcase_post_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ShowcasePost {
  final String id;
  final String userId;
  final String userName;
  final String? userImageUrl;
  final String content;
  final String? imageUrl;
  final List<String> likes;
  final List<ShowcaseComment> comments;
  final DateTime createdAt;
  final String? achievementId; // Link to achievement if applicable

  ShowcasePost({
    required this.id,
    required this.userId,
    required this.userName,
    this.userImageUrl,
    required this.content,
    this.imageUrl,
    required this.likes,
    required this.comments,
    required this.createdAt,
    this.achievementId,
  });

  factory ShowcasePost.fromMap(Map<String, dynamic> data, String id) {
    return ShowcasePost(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userImageUrl: data['userImageUrl'],
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      likes: List<String>.from(data['likes'] ?? []),
      comments: (data['comments'] as List<dynamic>? ?? [])
          .map((comment) => ShowcaseComment.fromMap(comment))
          .toList(),
      createdAt: DateTime.parse(data['createdAt']),
      achievementId: data['achievementId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userImageUrl': userImageUrl,
      'content': content,
      'imageUrl': imageUrl,
      'likes': likes,
      'comments': comments.map((comment) => comment.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'achievementId': achievementId,
    };
  }
}

class ShowcaseComment {
  final String id;
  final String userId;
  final String userName;
  final String content;
  final DateTime createdAt;

  ShowcaseComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
  });

  factory ShowcaseComment.fromMap(Map<String, dynamic> data) {
    return ShowcaseComment(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      content: data['content'] ?? '',
      createdAt: DateTime.parse(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class ShowcaseScreen extends StatefulWidget {
  const ShowcaseScreen({super.key});

  @override
  State<ShowcaseScreen> createState() => _ShowcaseScreenState();
}

class _ShowcaseScreenState extends State<ShowcaseScreen> {
  List<Map<String, dynamic>> posts = [
    {
      'userName': 'Ethan Carter',
      'headline': 'Aspiring Data Scientist',
      'userImage': 'https://randomuser.me/api/portraits/men/32.jpg',
      'content': 'A painting inspired by nature.',
      'imageUrl':
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
      'likes': 12,
      'liked': false,
      'comments': [
        {
          'userName': 'Sarah Lee',
          'userImage': 'https://randomuser.me/api/portraits/women/44.jpg',
          'content': 'Beautiful work!'
        },
        {
          'userName': 'John Doe',
          'userImage': 'https://randomuser.me/api/portraits/men/45.jpg',
          'content': 'Amazing colors.'
        },
      ],
    },
    {
      'userName': 'Sarah Lee',
      'headline': 'Professional IoT',
      'userImage': 'https://randomuser.me/api/portraits/women/44.jpg',
      'content': 'Solved a complex algorithm problem.',
      'imageUrl': null,
      'likes': 8,
      'liked': false,
      'comments': [
        {
          'userName': 'Ethan Carter',
          'userImage': 'https://randomuser.me/api/portraits/men/32.jpg',
          'content': 'Congrats!'
        },
      ],
    },
  ];

  // Track votes: post index -> selected option index
  Map<int, int> pollVotes = {};
  // Track vote counts: post index -> List<int> (votes per option)
  Map<int, List<int>> pollVoteCounts = {};

  bool _isRefreshing = false;

  Future<void> _refreshPosts() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isRefreshing = false);
  }

  void _toggleLike(int index) {
    setState(() {
      posts[index]['liked'] = !(posts[index]['liked'] ?? false);
      posts[index]['likes'] += posts[index]['liked'] ? 1 : -1;
    });
  }

  void _showCommentSheet(int index) {
    final _commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add a Comment',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Write your comment...',
                border: OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_commentController.text.trim().isNotEmpty) {
                  setState(() {
                    posts[index]['comments'].add({
                      'userName': 'You',
                      'userImage':
                          'https://randomuser.me/api/portraits/men/1.jpg',
                      'content': _commentController.text.trim(),
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Post Comment'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share'),
        content: const Text('Share functionality coming soon!'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showFullPost(int index) {
    final post = posts[index];
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildPostCard(post, index, isFull: true),
          ),
        ),
      ),
    );
  }

  void _showAddPostSheet() {
    final _contentController = TextEditingController();
    File? _selectedImage;
    bool canPost = false;
    final picker = ImagePicker();
    DateTime? _scheduledTime;
    bool _showPoll = false;
    final _pollQuestionController = TextEditingController();
    List<TextEditingController> _pollOptionControllers = [
      TextEditingController(),
      TextEditingController()
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            canPost = _contentController.text.trim().isNotEmpty ||
                _selectedImage != null ||
                (_showPoll &&
                    _pollQuestionController.text.trim().isNotEmpty &&
                    _pollOptionControllers
                            .where((c) => c.text.trim().isNotEmpty)
                            .length >=
                        2);
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 16,
                  right: 16,
                  top: 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile and audience
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(
                              'https://randomuser.me/api/portraits/men/1.jpg'),
                          radius: 24,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Noor Azami',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            Row(
                              children: [
                                Text('Post to Anyone',
                                    style: TextStyle(
                                        color: Colors.grey[700], fontSize: 13)),
                                const Icon(Icons.arrow_drop_down,
                                    size: 18, color: Colors.grey),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Large text field
                    TextField(
                      controller: _contentController,
                      onChanged: (val) => setModalState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'What do you want to talk about?',
                        border: InputBorder.none,
                      ),
                      minLines: 5,
                      maxLines: 10,
                      style: const TextStyle(fontSize: 18),
                    ),
                    if (_selectedImage != null) ...[
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_selectedImage!,
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () =>
                                  setModalState(() => _selectedImage = null),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_scheduledTime != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.event, color: Colors.blue),
                          const SizedBox(width: 6),
                          Text(
                              'Scheduled for: ${_scheduledTime!.toLocal().toString().substring(0, 16)}',
                              style: const TextStyle(color: Colors.blue)),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () =>
                                setModalState(() => _scheduledTime = null),
                          ),
                        ],
                      ),
                    ],
                    if (_showPoll) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _pollQuestionController,
                        decoration: const InputDecoration(
                          labelText: 'Poll question',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) => setModalState(() {}),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(
                          _pollOptionControllers.length,
                          (i) => Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _pollOptionControllers[i],
                                      decoration: InputDecoration(
                                        labelText: 'Option ${i + 1}',
                                        border: const OutlineInputBorder(),
                                      ),
                                      onChanged: (val) => setModalState(() {}),
                                    ),
                                  ),
                                  if (_pollOptionControllers.length > 2)
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle,
                                          color: Colors.red),
                                      onPressed: () {
                                        setModalState(() {
                                          _pollOptionControllers.removeAt(i);
                                        });
                                      },
                                    ),
                                ],
                              )),
                      if (_pollOptionControllers.length < 4)
                        TextButton.icon(
                          onPressed: () {
                            setModalState(() {
                              _pollOptionControllers
                                  .add(TextEditingController());
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Option'),
                        ),
                      const SizedBox(height: 8),
                      if (_pollQuestionController.text.trim().isNotEmpty &&
                          _pollOptionControllers
                                  .where((c) => c.text.trim().isNotEmpty)
                                  .length >=
                              2)
                        Card(
                          color: Colors.blue[50],
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_pollQuestionController.text.trim(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                ..._pollOptionControllers
                                    .where((c) => c.text.trim().isNotEmpty)
                                    .map((c) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 2),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.circle_outlined,
                                                  size: 16, color: Colors.blue),
                                              const SizedBox(width: 8),
                                              Text(c.text.trim()),
                                            ],
                                          ),
                                        )),
                              ],
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 12),
                    // Toolbar
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.emoji_emotions_outlined),
                          onPressed: null,
                          color: Colors.grey[400],
                        ),
                        IconButton(
                          icon: const Icon(Icons.image_outlined),
                          onPressed: () async {
                            final picked = await picker.pickImage(
                                source: ImageSource.gallery, imageQuality: 80);
                            if (picked != null) {
                              setModalState(
                                  () => _selectedImage = File(picked.path));
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.event_outlined),
                          onPressed: () async {
                            final now = DateTime.now();
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: now,
                              firstDate: now,
                              lastDate: DateTime(now.year + 2),
                            );
                            if (pickedDate != null) {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(
                                    now.add(const Duration(minutes: 5))),
                              );
                              if (pickedTime != null) {
                                setModalState(() {
                                  _scheduledTime = DateTime(
                                    pickedDate.year,
                                    pickedDate.month,
                                    pickedDate.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                });
                              }
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.poll_outlined),
                          onPressed: () =>
                              setModalState(() => _showPoll = !_showPoll),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: canPost
                              ? () {
                                  setState(() {
                                    posts.insert(0, {
                                      'userName': 'Noor Azami',
                                      'headline': 'Professional IoT',
                                      'userImage':
                                          'https://randomuser.me/api/portraits/men/1.jpg',
                                      'content': _contentController.text.trim(),
                                      'imageUrl': _selectedImage?.path,
                                      'likes': 0,
                                      'liked': false,
                                      'comments': [],
                                      'scheduledTime': _scheduledTime,
                                      'poll': _showPoll &&
                                              _pollQuestionController.text
                                                  .trim()
                                                  .isNotEmpty &&
                                              _pollOptionControllers
                                                      .where((c) => c.text
                                                          .trim()
                                                          .isNotEmpty)
                                                      .length >=
                                                  2
                                          ? {
                                              'question':
                                                  _pollQuestionController.text
                                                      .trim(),
                                              'options': _pollOptionControllers
                                                  .where((c) =>
                                                      c.text.trim().isNotEmpty)
                                                  .map((c) => c.text.trim())
                                                  .toList(),
                                            }
                                          : null,
                                    });
                                  });
                                  Navigator.pop(context);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Post'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, int index,
      {bool isFull = false}) {
    // Initialize poll vote counts if needed
    if (post['poll'] != null && pollVoteCounts[index] == null) {
      pollVoteCounts[index] =
          List.filled((post['poll']['options'] as List).length, 0);
    }
    return GestureDetector(
      onTap: isFull ? null : () => _showFullPost(index),
      child: Card(
        color: Colors.white,
        elevation: 4,
        margin: isFull ? EdgeInsets.zero : const EdgeInsets.only(bottom: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue[300]!, width: 3),
                    ),
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(post['userImage']),
                      radius: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post['userName'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black)),
                        if (post['headline'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(post['headline'],
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (post['imageUrl'] != null &&
                  post['imageUrl'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Tooltip(
                    message: 'Post image',
                    child: Image.network(
                      post['imageUrl'],
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 180,
                        color: Colors.grey[200],
                        child: const Center(
                            child: Icon(Icons.broken_image,
                                size: 48, color: Colors.grey)),
                      ),
                      semanticLabel: 'Post image',
                    ),
                  ),
                ),
              ],
              if (post['scheduledTime'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.event, color: Colors.blue, size: 18),
                    const SizedBox(width: 6),
                    Text(
                        'Scheduled for: ${post['scheduledTime'].toLocal().toString().substring(0, 16)}',
                        style: const TextStyle(color: Colors.blue)),
                  ],
                ),
              ],
              if (post['poll'] != null) ...[
                const SizedBox(height: 8),
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post['poll']['question'],
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        ...List.generate(
                            (post['poll']['options'] as List).length, (i) {
                          final voted = pollVotes[index] != null;
                          final selected = pollVotes[index] == i;
                          final voteCounts = pollVoteCounts[index] ??
                              List.filled(
                                  (post['poll']['options'] as List).length, 0);
                          final totalVotes =
                              voteCounts.fold<int>(0, (a, b) => a + b);
                          final percent = totalVotes > 0
                              ? (voteCounts[i] / totalVotes * 100)
                                  .toStringAsFixed(0)
                              : '0';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: InkWell(
                              onTap: voted
                                  ? null
                                  : () {
                                      setState(() {
                                        pollVotes[index] = i;
                                        pollVoteCounts[index]![i]++;
                                      });
                                    },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? Colors.blue[100]
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: selected
                                          ? Colors.blue
                                          : Colors.grey[300]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                        selected
                                            ? Icons.check_circle
                                            : Icons.circle_outlined,
                                        size: 18,
                                        color: selected
                                            ? Colors.blue
                                            : Colors.grey),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child:
                                            Text(post['poll']['options'][i])),
                                    if (voted) ...[
                                      const SizedBox(width: 8),
                                      Text('$percent%',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue)),
                                      const SizedBox(width: 4),
                                      Text('(${voteCounts[i]})',
                                          style: const TextStyle(
                                              color: Colors.grey)),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        if ((pollVoteCounts[index]
                                    ?.fold<int>(0, (a, b) => a + b) ??
                                0) >
                            0)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                                '${pollVoteCounts[index]!.fold<int>(0, (a, b) => a + b)} votes',
                                style: const TextStyle(color: Colors.blue)),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(post['content'],
                  style: const TextStyle(fontSize: 15, color: Colors.black)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Tooltip(
                    message: post['liked'] ? 'Unlike' : 'Like',
                    child: IconButton(
                      icon: Icon(
                          post['liked']
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: post['liked'] ? Colors.red : Colors.grey),
                      onPressed: () => _toggleLike(index),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('${post['likes']}',
                      style: const TextStyle(color: Colors.black)),
                  const SizedBox(width: 18),
                  Tooltip(
                    message: 'Comment',
                    child: IconButton(
                      icon: const Icon(Icons.comment),
                      onPressed: () => _showCommentSheet(index),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('${post['comments'].length}',
                      style: const TextStyle(color: Colors.black)),
                  const Spacer(),
                  Tooltip(
                    message: 'Share post',
                    child: IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: _showShareDialog,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Comments
              ...List.generate(post['comments'].length, (cidx) {
                final comment = post['comments'][cidx];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.blue[100]!, width: 2),
                        ),
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(comment['userImage']),
                          radius: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                    text: comment['userName'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black)),
                                const TextSpan(text: '  '),
                                TextSpan(
                                    text: comment['content'],
                                    style:
                                        const TextStyle(color: Colors.black)),
                              ],
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Talent Showcase'),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child: _isRefreshing
            ? const Center(child: CircularProgressIndicator())
            : posts.isEmpty
                ? const Center(
                    child: Text(
                        'No posts yet. Be the first to share your talent!',
                        style: TextStyle(fontSize: 16, color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: posts.length,
                    itemBuilder: (context, index) =>
                        _buildPostCard(posts[index], index),
                  ),
      ),
      floatingActionButton: Tooltip(
        message: 'Create Post',
        child: FloatingActionButton(
          onPressed: _showAddPostSheet,
          backgroundColor: Colors.blue[800],
          child: const Icon(Icons.add, size: 32),
          tooltip: 'Create Post',
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
      ),
    );
  }
}
