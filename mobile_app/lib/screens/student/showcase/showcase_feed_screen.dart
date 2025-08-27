import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/showcase_models.dart';
import '../../../models/user_model.dart';
import '../../../services/showcase_service.dart';
import '../../../services/supabase_auth_service.dart';
import '../../../widgets/modern/modern_post_card.dart';

import '../../../utils/app_theme.dart';
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
    _setupRealTimeSubscription();
  }

  /// Setup real-time subscription for posts
  void _setupRealTimeSubscription() {
    try {
      // Setup real-time subscription
      _postsSubscription = _showcaseService
          .getShowcasePostsRealtimeStream(
        limit: _postsPerPage,
        category: _selectedCategory,
      )
          .listen(
        (posts) {
          debugPrint(
              'ShowcaseFeedScreen: Real-time update received: ${posts.length} posts');
          if (posts.isNotEmpty) {
            debugPrint(
                'ShowcaseFeedScreen: First post data: ${posts.first.id} - ${posts.first.content.substring(0, posts.first.content.length > 20 ? 20 : posts.first.content.length)}...');
          }

          if (mounted) {
            debugPrint(
                'ShowcaseFeedScreen: Successfully received ${posts.length} posts');

            setState(() {
              _posts = posts;
              _isLoading = false;
              _hasMore = posts.length >= _postsPerPage;
              _error = null;
            });

            debugPrint(
                'ShowcaseFeedScreen: Feed updated with ${posts.length} posts');
          }
        },
        onError: (error) {
          debugPrint(
              'ShowcaseFeedScreen: Real-time subscription error: $error');
          if (mounted) {
            setState(() {
              _error = error.toString();
              _isLoading = false;
            });
          }
          // Fallback to manual loading
          _loadInitialPosts();
        },
      );
    } catch (e) {
      debugPrint('ShowcaseFeedScreen: Error setting up subscription: $e');
      // Fallback to manual loading
      _loadInitialPosts();
    }
  }

  /// Refresh feed manually (called from external sources)
  void refreshFeed() {
    debugPrint('ShowcaseFeedScreen: Manual refresh requested');
    _setupRealTimeSubscription();
  }

  /// Refresh feed and show loading indicator
  Future<void> _refreshFeedWithLoading() async {
    debugPrint('ShowcaseFeedScreen: Refresh with loading indicator');

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Wait a bit for real-time update
    await Future.delayed(const Duration(milliseconds: 500));

    // If no real-time update received, fallback to manual refresh
    if (_posts.isEmpty) {
      _loadInitialPosts();
    }
  }

  /// Update category filter and refresh feed
  void _updateCategoryFilter(PostCategory? category) {
    setState(() {
      _selectedCategory = category;
    });
    _setupRealTimeSubscription();
  }

  /// Force refresh feed by calling backend API directly
  Future<void> forceRefreshFeed() async {
    debugPrint('ShowcaseFeedScreen: Force refreshing feed...');

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Cancel existing subscription temporarily
      _postsSubscription?.cancel();

      // Load posts directly from backend using the working method
      final posts = await _showcaseService.getShowcasePosts(
        limit: _postsPerPage,
        category: _selectedCategory,
      );
      debugPrint('ShowcaseFeedScreen: Force refresh got ${posts.length} posts');

      if (posts.isNotEmpty) {
        debugPrint(
            'ShowcaseFeedScreen: First post data: ${posts.first.id} - ${posts.first.content.substring(0, posts.first.content.length > 20 ? 20 : posts.first.content.length)}...');
      }

      debugPrint(
          'ShowcaseFeedScreen: Force refresh successfully received ${posts.length} posts');

      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
          _hasMore = posts.length >= _postsPerPage;
        });
      }

      // Re-setup real-time subscription
      _setupRealTimeSubscription();
    } catch (e) {
      debugPrint('ShowcaseFeedScreen: Force refresh error: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Debug section for testing
  Widget _buildDebugSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Debug Controls',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: forceRefreshFeed,
                child: const Text('Force Refresh'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  debugPrint(
                      'ShowcaseFeedScreen: Current posts count: ${_posts.length}');
                  if (_posts.isNotEmpty) {
                    debugPrint(
                        'ShowcaseFeedScreen: Posts: ${_posts.map((p) => '${p.id}: ${p.content.substring(0, p.content.length > 20 ? 20 : p.content.length)}...').join(', ')}');
                  } else {
                    debugPrint('ShowcaseFeedScreen: No posts loaded');
                  }
                },
                child: const Text('Debug Info'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _postsSubscription?.cancel();
    super.dispose();
  }

  void _loadCurrentUser() {
    final authService =
        Provider.of<SupabaseAuthService>(context, listen: false);
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

    debugPrint('ShowcaseFeedScreen: Starting to load initial posts...');

    setState(() {
      _isLoading = true;
      _error = null;
      _posts.clear();
      _hasMore = true;
    });

    try {
      _postsSubscription?.cancel();

      debugPrint('ShowcaseFeedScreen: Calling getShowcasePosts()...');
      // Use the working getShowcasePosts method
      final posts = await _showcaseService.getShowcasePosts(
        limit: _postsPerPage,
        category: _selectedCategory,
      );
      debugPrint(
          'ShowcaseFeedScreen: Received ${posts.length} posts from backend');

      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
          _hasMore = posts.length >= _postsPerPage;
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

  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      // For now, just reload all posts since backend doesn't support pagination yet
      final allPosts = await _showcaseService.getShowcasePosts(
        limit: _postsPerPage * 2, // Get more posts for pagination
        category: _selectedCategory,
      );

      // Simple pagination simulation - skip already loaded posts
      final newPosts =
          allPosts.skip(_posts.length).take(_postsPerPage).toList();

      if (mounted) {
        setState(() {
          _posts.addAll(newPosts);
          _isLoading = false;
          _hasMore = newPosts.length >= _postsPerPage;
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

    return Container(
      color: Colors.transparent,
      child: _buildBody(),
    );
  }

  /// Navigate to post creation with callback to refresh feed
  void _navigateToPostCreation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostCreationScreen(
          onPostCreated: () {
            debugPrint('ShowcaseFeedScreen: Post created, refreshing feed...');
            refreshFeed();
          },
        ),
      ),
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
      onRefresh: _refreshFeedWithLoading,
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
                  return ModernPostCard(
                    post: _posts[index],
                    currentUser: _currentUser,
                    onLike: _handleLike,
                    onComment: _handleComment,
                    onShare: _handleShare,
                    onUserTap: _handleUserTap,
                    onPostTap: _handlePostTap,
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
                _updateCategoryFilter(null);
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: AppTheme.spaceLg),
          Text(
            'Loading amazing content...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
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
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInitialPosts,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space2xl),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            Text(
              'Ready to Shine?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: null, // Use theme default
                  ),
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Text(
              'Share your talents, achievements, and connect with the UTHM community!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: null, // Use theme default
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _navigateToPostCreation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceLg,
                    vertical: AppTheme.spaceMd,
                  ),
                ),
                icon: Icon(Icons.add_rounded,
                    color: Theme.of(context).colorScheme.onPrimary),
                label: Text(
                  'Create Your First Post',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            // Debug section
            _buildDebugSection(),
          ],
        ),
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

  // Navigation and interaction methods

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
