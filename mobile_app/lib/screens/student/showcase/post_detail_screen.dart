import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../models/showcase_models.dart';
import '../../../models/user_model.dart';
import '../../../services/showcase_service.dart';
import '../../../services/supabase_auth_service.dart';
import '../../../widgets/showcase/post_card_widget.dart';
import '../../../widgets/showcase/comment_widgets.dart';
import '../../../widgets/showcase/share_widget.dart';
import 'post_creation_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final ShowcasePostModel? initialPost;

  const PostDetailScreen({
    super.key,
    required this.postId,
    this.initialPost,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final ShowcaseService _showcaseService = ShowcaseService();
  final ScrollController _scrollController = ScrollController();

  ShowcasePostModel? _post;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadPost();

    // Increment view count
    if (widget.postId.isNotEmpty) {
      _showcaseService.incrementViewCount(widget.postId);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadCurrentUser() {
    final authService =
        Provider.of<SupabaseAuthService>(context, listen: false);
    _currentUser = authService.currentUser;
  }

  Future<void> _loadPost() async {
    if (widget.initialPost != null && _post == null) {
      setState(() {
        _post = widget.initialPost;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get post from Supabase using the new method
      final post = await _showcaseService.getPostById(widget.postId);

      if (post != null) {
        setState(() {
          _post = post;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Post not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load post: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Post'),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      actions: [
        if (_post != null)
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _showShareDialog(),
            tooltip: 'Share Post',
          ),
        if (_post != null &&
            _currentUser != null &&
            _post!.isOwnedBy(_currentUser!.uid))
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Edit Post'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Post', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading post...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPost,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_post == null) {
      return const Center(
        child: Text('Post not found'),
      );
    }

    return StreamBuilder<ShowcasePostModel?>(
      stream: _getPostStream(),
      initialData: _post,
      builder: (context, snapshot) {
        final post = snapshot.data ?? _post!;

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Post content
            SliverToBoxAdapter(
              child: PostCardWidget(
                post: post,
                currentUser: _currentUser,
                onLike: _handleLike,
                onComment: _handleComment,
                onShare: _handleShare,
                onUserTap: _handleUserTap,
                onPostTap: (_) {}, // Already on post detail
                onEdit: _handleEdit,
                onDelete: _handleDelete,
                onReaction: _handleReaction, // LinkedIn-style reactions
                showFullContent: true,
              ),
            ),

            // Divider
            const SliverToBoxAdapter(
              child: Divider(height: 1, thickness: 1),
            ),

            // Comments section
            SliverToBoxAdapter(
              child: CommentSectionWidget(
                postId: post.id,
                comments: post.comments,
                currentUser: _currentUser,
                onAddComment: _handleAddComment,
              ),
            ),
          ],
        );
      },
    );
  }

  Stream<ShowcasePostModel?> _getPostStream() {
    return _showcaseService.showcaseCollection.doc(widget.postId).snapshots();
  }

  Future<void> _handleLike(ShowcasePostModel post) async {
    if (_currentUser == null) return;

    // Add haptic feedback
    HapticFeedback.lightImpact();

    try {
      // Optimistic update
      final updatedPost = post.copyWith(
        likes: post.isLikedBy(_currentUser!.uid)
            ? post.likes.where((id) => id != _currentUser!.uid).toList()
            : [...post.likes, _currentUser!.uid],
      );

      setState(() {
        _post = updatedPost;
      });

      // Real like/unlike
      await _showcaseService.toggleLike(post.id, _currentUser!.uid);

      // Force refresh the post data to ensure UI is in sync
      await _loadPost();
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        _post = post;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update like: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handleComment(ShowcasePostModel post) {
    // Scroll to comments section
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleShare(ShowcasePostModel post) {
    _showShareDialog();
  }

  Future<void> _handleReaction(ReactionType reactionType, String postId) async {
    if (_currentUser == null) return;

    try {
      // Add haptic feedback
      HapticFeedback.lightImpact();

      // Add reaction to the post
      await _showcaseService.addReaction(postId, reactionType.name);

      // Refresh the post data to show the new reaction immediately
      await _loadPost();

      // Also trigger a stream refresh to ensure UI updates
      setState(() {
        // This will trigger a rebuild with the updated post data
      });

      debugPrint(
          'PostDetailScreen: Added ${reactionType.name} reaction to post $postId');
    } catch (e) {
      debugPrint('PostDetailScreen: Error adding reaction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add reaction: $e')),
        );
      }
    }
  }

  void _handleUserTap(ShowcasePostModel post) {
    // Navigate to user profile
    Navigator.pushNamed(
      context,
      '/user-profile',
      arguments: {'userId': post.userId},
    );
  }

  Future<void> _handleAddComment(
      String content, String? parentCommentId) async {
    if (_currentUser == null || _post == null) return;

    try {
      await _showcaseService.addComment(
        _post!.id,
        _currentUser!.uid,
        content,
      );

      // Refresh the post data to show the new comment immediately
      await _loadPost();

      // Also trigger a stream refresh to ensure UI updates
      setState(() {
        // This will trigger a rebuild with the updated post data
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add comment: $e')),
        );
      }
    }
  }

  void _showShareDialog() {
    if (_post == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ShareWidget(
        post: _post!,
        currentUser: _currentUser,
      ),
    );
  }

  void _handleEdit(ShowcasePostModel post) {
    // Navigate to edit post screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostCreationScreen(
          editingPost: post,
        ),
      ),
    ).then((_) {
      // Refresh the post data when returning from edit screen
      _loadPost();
    });
  }

  void _handleDelete(ShowcasePostModel post) {
    _showDeleteConfirmation();
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        // Navigate to edit post screen
        if (_post != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostCreationScreen(
                editingPost: _post!,
              ),
            ),
          ).then((_) {
            // Refresh the post data when returning from edit screen
            _loadPost();
          });
        }
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
            'Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              navigator.pop(); // Close dialog

              try {
                await _showcaseService.deleteShowcasePost(_post!.id);
                if (mounted) {
                  navigator.pop(); // Go back to feed
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Post deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Failed to delete post: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
