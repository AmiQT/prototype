import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/showcase_models.dart';
import '../../../models/user_model.dart';
import '../../../services/showcase_service.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/showcase/post_card_widget.dart';
import '../../../widgets/showcase/feed_widgets.dart';
import '../../../widgets/showcase/comment_widgets.dart';
import '../../../widgets/showcase/share_widget.dart';
import 'post_creation_screen.dart';
import 'post_detail_screen.dart';
import '../../profile/user_profile_screen.dart';

class ShowcaseFeedScreen extends StatefulWidget {
  final PostCategory? filterCategory;
  final String? filterUserId;

  const ShowcaseFeedScreen({
    super.key,
    this.filterCategory,
    this.filterUserId,
  });

  @override
  State<ShowcaseFeedScreen> createState() => _ShowcaseFeedScreenState();
}

class _ShowcaseFeedScreenState extends State<ShowcaseFeedScreen>
    with AutomaticKeepAliveClientMixin {
  final ShowcaseService _showcaseService = ShowcaseService();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  // State variables
  List<ShowcasePostModel> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  String? _lastPostId;
  PostCategory? _selectedCategory;
  UserModel? _currentUser;

  // Pagination
  static const int _postsPerPage = 10;

  // Stream subscription
  StreamSubscription<List<ShowcasePostModel>>? _postsSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.filterCategory;
    _loadCurrentUser();
    _setupScrollListener();
    _loadInitialPosts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _postsSubscription?.cancel();
    super.dispose();
  }

  void _loadCurrentUser() {
    final authService = Provider.of<AuthService>(context, listen: false);
    _currentUser = authService.currentUser;
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoading && _hasMore) {
          _loadMorePosts();
        }
      }
    });
  }

  Future<void> _loadInitialPosts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _posts.clear();
      _lastPostId = null;
      _hasMore = true;
    });

    try {
      _postsSubscription?.cancel();
      _postsSubscription = _showcaseService
          .getShowcasePostsStream(
        limit: _postsPerPage,
        category: _selectedCategory,
        userId: widget.filterUserId,
      )
          .listen(
        (posts) {
          if (mounted) {
            setState(() {
              _posts = posts;
              _isLoading = false;
              _hasMore = posts.length >= _postsPerPage;
              if (posts.isNotEmpty) {
                _lastPostId = posts.last.id;
              }
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _error = error.toString();
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final morePosts = await _showcaseService
          .getShowcasePostsStream(
            limit: _postsPerPage,
            lastPostId: _lastPostId,
            category: _selectedCategory,
            userId: widget.filterUserId,
          )
          .first;

      if (mounted) {
        setState(() {
          _posts.addAll(morePosts);
          _isLoading = false;
          _hasMore = morePosts.length >= _postsPerPage;
          if (morePosts.isNotEmpty) {
            _lastPostId = morePosts.last.id;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshFeed() async {
    await _loadInitialPosts();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Showcase'),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterDialog,
          tooltip: 'Filter Posts',
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _showSearchDialog,
          tooltip: 'Search Posts',
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_error != null && _posts.isEmpty) {
      return _buildErrorState();
    }

    if (_isLoading && _posts.isEmpty) {
      return _buildLoadingState();
    }

    if (_posts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _refreshFeed,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Filter chips
          if (_selectedCategory != null) _buildFilterChips(),

          // Posts list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < _posts.length) {
                  return PostCardWidget(
                    post: _posts[index],
                    currentUser: _currentUser,
                    onLike: _handleLike,
                    onComment: _handleComment,
                    onShare: _handleShare,
                    onUserTap: _handleUserTap,
                    onPostTap: _handlePostTap,
                    onEdit: _handleEdit,
                    onDelete: _handleDelete,
                  );
                } else if (_hasMore) {
                  return _buildLoadingIndicator();
                }
                return null;
              },
              childCount: _posts.length + (_hasMore ? 1 : 0),
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Chip(
              label: Text(_getCategoryDisplayName(_selectedCategory!)),
              onDeleted: () {
                setState(() {
                  _selectedCategory = null;
                });
                _loadInitialPosts();
              },
              backgroundColor:
                  Theme.of(context).primaryColor.withValues(alpha: 0.1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading posts...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
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
          const Text(
            'Failed to load posts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadInitialPosts,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.post_add,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No posts yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share your talents!',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _navigateToCreatePost,
            icon: const Icon(Icons.add),
            label: const Text('Create Post'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _navigateToCreatePost,
      child: const Icon(Icons.add),
      tooltip: 'Create Post',
    );
  }

  // Navigation and interaction methods
  void _navigateToCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PostCreationScreen(),
      ),
    );
  }

  void _handleLike(ShowcasePostModel post) async {
    if (_currentUser == null) return;

    try {
      // Optimistic update
      final updatedPost = post.copyWith(
        likes: post.isLikedBy(_currentUser!.uid)
            ? post.likes.where((id) => id != _currentUser!.uid).toList()
            : [...post.likes, _currentUser!.uid],
      );

      setState(() {
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          _posts[index] = updatedPost;
        }
      });

      // Real Firebase like/unlike
      await _showcaseService.toggleLike(post.id, _currentUser!.uid);
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          _posts[index] = post;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update like: $e')),
        );
      }
    }
  }

  void _handleComment(ShowcasePostModel post) {
    // Navigate to post detail screen for commenting
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(
          postId: post.id,
          initialPost: post,
        ),
      ),
    );
  }

  void _handleShare(ShowcasePostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ShareWidget(
        post: post,
        currentUser: _currentUser,
      ),
    );
  }

  void _handleUserTap(ShowcasePostModel post) {
    // Navigate to user profile
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          userId: post.userId,
        ),
      ),
    );
  }

  void _handlePostTap(ShowcasePostModel post) {
    // Navigate to post detail screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(
          postId: post.id,
          initialPost: post,
        ),
      ),
    );
  }

  void _handleEdit(ShowcasePostModel post) {
    // Navigate to edit post screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit feature coming soon!')),
    );
  }

  void _handleDelete(ShowcasePostModel post) async {
    try {
      await _showcaseService.deletePost(post.id);
      setState(() {
        _posts.removeWhere((p) => p.id == post.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting post: $e')),
        );
      }
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FilterBottomSheet(
        selectedCategory: _selectedCategory,
        onCategoryChanged: (category) {
          setState(() {
            _selectedCategory = category;
          });
          _loadInitialPosts();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showSearchDialog() {
    // TODO: Implement search functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search feature coming soon!')),
    );
  }

  String _getCategoryDisplayName(PostCategory category) {
    switch (category) {
      case PostCategory.academic:
        return 'Academic';
      case PostCategory.creative:
        return 'Creative';
      case PostCategory.technical:
        return 'Technical';
      case PostCategory.sports:
        return 'Sports';
      case PostCategory.volunteer:
        return 'Volunteer';
      case PostCategory.achievement:
        return 'Achievement';
      case PostCategory.project:
        return 'Project';
      case PostCategory.general:
        return 'General';
    }
  }
}
