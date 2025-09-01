import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../models/showcase_models.dart';
import '../../../models/user_model.dart';
import '../../../services/showcase_service.dart';
import '../../../services/supabase_auth_service.dart';
import '../../../widgets/modern/modern_post_card.dart';

import '../../../utils/app_theme.dart';
import '../../../widgets/showcase/share_widget.dart';
import '../../../widgets/animations/loading_animations.dart';
import '../../../utils/animation_system.dart';
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

  // Counter for reducing console spam
  int _updateCount = 0;

  // Debug flag to disable real-time updates
  static const bool _enableRealTimeUpdates =
      true; // Enable real-time updates for better UX

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

  // Loading progress
  double _loadingProgress = 0.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.filterCategory;
    _loadCurrentUser();
    _setupScrollListener();

    // Show loading state immediately for better UX during hot restart
    setState(() {
      _isLoading = true;
    });

    // Preload common data for faster access
    _preloadData();

    // Only setup real-time subscription if enabled
    if (_enableRealTimeUpdates) {
      _setupRealTimeSubscription();
    } else {
      // Load initial posts without real-time updates
      _loadInitialPosts();
    }
  }

  /// Preload data for faster access
  Future<void> _preloadData() async {
    try {
      // Preload common data in background
      await _showcaseService.preloadCommonData();
    } catch (e) {
      debugPrint('ShowcaseFeedScreen: Error preloading data: $e');
    }
  }

  /// Setup real-time subscription for posts (ultra-fast)
  void _setupRealTimeSubscription() {
    try {
      // Show loading state immediately for better UX during hot restart
      setState(() {
        _isLoading = true;
        _posts.clear();
      });

      // Setup ultra-fast real-time subscription
      _postsSubscription = _showcaseService
          .getShowcasePostsRealtimeStream(
        limit: _postsPerPage,
        category: _selectedCategory,
      )
          .listen(
        (posts) {
          // Only log every 20th update to reduce console spam
          _updateCount++;
          if (_updateCount % 20 == 1) {
            debugPrint(
                'ShowcaseFeedScreen: Ultra-fast real-time update received: ${posts.length} posts [Update #$_updateCount]');
            if (posts.isNotEmpty) {
              debugPrint(
                  'ShowcaseFeedScreen: First post data: ${posts.first.id} - ${posts.first.content.substring(0, posts.first.content.length > 20 ? 20 : posts.first.content.length)}...');
            }
          }

          if (mounted) {
            setState(() {
              _posts = posts;
              _isLoading = false;
              _hasMore = posts.length >= _postsPerPage;
              _error = null;
            });

            // Only log feed update every 20th time
            if (_updateCount % 20 == 1) {
              debugPrint(
                  'ShowcaseFeedScreen: Feed updated with ${posts.length} posts [Update #$_updateCount]');
            }
          }
        },
        onError: (error) {
          debugPrint(
              'ShowcaseFeedScreen: Ultra-fast real-time subscription error: $error');
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
      debugPrint(
          'ShowcaseFeedScreen: Error setting up ultra-fast subscription: $e');
      // Fallback to manual loading
      _loadInitialPosts();
    }
  }

  /// Refresh feed manually (called from external sources)
  void refreshFeed() {
    debugPrint('ShowcaseFeedScreen: Manual refresh requested');
    debugPrint(
        'ShowcaseFeedScreen: _enableRealTimeUpdates: $_enableRealTimeUpdates');
    debugPrint(
        'ShowcaseFeedScreen: Current posts count before refresh: ${_posts.length}');

    if (_enableRealTimeUpdates) {
      debugPrint('ShowcaseFeedScreen: Setting up real-time subscription...');
      _setupRealTimeSubscription();
    } else {
      debugPrint('ShowcaseFeedScreen: Loading initial posts...');
      // Force refresh by clearing current posts and loading fresh data
      setState(() {
        _posts.clear();
        _isLoading = true;
        _error = null;
        _hasMore = true; // Reset pagination
      });
      _loadInitialPosts();
    }
  }

  /// Refresh feed and show loading indicator (ultra-fast)
  Future<void> _refreshFeedWithLoading() async {
    debugPrint('ShowcaseFeedScreen: Ultra-fast refresh with loading indicator');

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Wait a bit for real-time update (reduced wait time)
    await Future.delayed(
        const Duration(milliseconds: 200)); // Reduced from 500ms to 200ms

    // Always force refresh to get latest posts
    await _loadInitialPosts();
  }

  /// Update category filter and refresh feed
  void _updateCategoryFilter(PostCategory? category) {
    setState(() {
      _selectedCategory = category;
    });
    if (_enableRealTimeUpdates) {
      _setupRealTimeSubscription();
    } else {
      _loadInitialPosts();
    }
  }

  /// Force refresh feed by calling backend API directly (ultra-fast)
  Future<void> forceRefreshFeed() async {
    debugPrint('ShowcaseFeedScreen: Ultra-fast force refreshing feed...');
    debugPrint(
        'ShowcaseFeedScreen: Current posts before refresh: ${_posts.length}');

    setState(() {
      _isLoading = true;
      _error = null;
      _posts.clear(); // Clear existing posts immediately
    });

    try {
      // Cancel existing subscription temporarily
      _postsSubscription?.cancel();

      // Load posts directly from backend using the ultra-optimized method with ultra-fast timeout
      final posts = await _showcaseService
          .getShowcasePosts(
            limit: _postsPerPage,
            category: _selectedCategory,
          )
          .timeout(const Duration(
              seconds: 3)); // Ultra-fast timeout (reduced from 4 to 3 seconds)
      debugPrint(
          'ShowcaseFeedScreen: Ultra-fast force refresh got ${posts.length} posts');

      if (posts.isNotEmpty) {
        debugPrint(
            'ShowcaseFeedScreen: First post data: ${posts.first.id} - ${posts.first.content.substring(0, posts.first.content.length > 20 ? 20 : posts.first.content.length)}...');
        debugPrint(
            'ShowcaseFeedScreen: Last post data: ${posts.last.id} - ${posts.last.content.substring(0, posts.last.content.length > 20 ? 20 : posts.last.content.length)}...');
      }

      debugPrint(
          'ShowcaseFeedScreen: Ultra-fast force refresh successfully received ${posts.length} posts');

      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
          _hasMore = posts.length >= _postsPerPage;
        });
        debugPrint(
            'ShowcaseFeedScreen: State updated with ${_posts.length} posts');
      }

      // Re-setup real-time subscription only if enabled
      if (_enableRealTimeUpdates) {
        _setupRealTimeSubscription();
      }
    } catch (e) {
      debugPrint('ShowcaseFeedScreen: Ultra-fast force refresh error: $e');
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
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  final stats = ShowcaseService.getCacheStats();
                  debugPrint('ShowcaseFeedScreen: Cache stats: $stats');
                },
                child: const Text('Cache Stats'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  ShowcaseService.clearAllCaches();
                  debugPrint('ShowcaseFeedScreen: All caches cleared');
                },
                child: const Text('Clear Cache'),
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

    setState(() {
      _isLoading = true;
      _error = null;
      _posts.clear();
      _hasMore = true;
      _loadingProgress = 0.0; // Reset progress
    });

    try {
      _postsSubscription?.cancel();

      // Update progress to show loading started
      setState(() {
        _loadingProgress = 0.2; // 20% - loading started
      });

      // Use ultra-optimized method with service-level timeout for homepage
      final posts = await _showcaseService
          .getShowcasePosts(
            limit: _postsPerPage,
            category: _selectedCategory,
          )
          .timeout(const Duration(
              seconds: 15)); // Add reasonable timeout for better UX

      // Update progress to show data loaded
      if (mounted) {
        setState(() {
          _loadingProgress = 0.8; // 80% - data loaded
        });
      }

      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
          _hasMore = posts.length >= _postsPerPage;
          _loadingProgress = 1.0; // 100% - complete
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _loadingProgress = 0.0; // Reset on error
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      color: Colors.transparent,
      child: _buildBody(),
    );
  }

  /// Navigate to post creation with callback to refresh feed
  void _navigateToPostCreation() async {
    debugPrint('ShowcaseFeedScreen: Navigating to post creation...');
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PostCreationScreen(),
      ),
    );

    debugPrint('ShowcaseFeedScreen: Post creation screen returned: $result');

    // Check if post was created successfully
    if (result == true) {
      debugPrint(
          'ShowcaseFeedScreen: Post creation completed, refreshing feed...');
      debugPrint('ShowcaseFeedScreen: Current posts count: ${_posts.length}');
      debugPrint('ShowcaseFeedScreen: Calling forceRefreshFeed()...');

      // Add a small delay to ensure database has processed the new post (reduced)
      await Future.delayed(
          const Duration(milliseconds: 500)); // Reduced from 1000ms to 500ms

      // Force a complete refresh
      await forceRefreshFeed();
      debugPrint(
          'ShowcaseFeedScreen: forceRefreshFeed() completed. New posts count: ${_posts.length}');
    } else {
      debugPrint(
          'ShowcaseFeedScreen: Post creation did not return true, result: $result');
    }
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

          // Posts list with staggered animations
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < _posts.length) {
                  return AnimationPresets.staggeredSlideIn(
                    index: index,
                    child: ModernPostCard(
                      post: _posts[index],
                      currentUser: _currentUser,
                      onLike: _handleLike,
                      onComment: _handleComment,
                      onShare: _handleShare,
                      onUserTap: _handleUserTap,
                      onPostTap: _handlePostTap,
                      onReaction: _handleReaction, // LinkedIn-style reactions
                      onPostDeleted: _handlePostDeleted,
                    ),
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
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        // Header loading (ultra-fast)
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            child: Column(
              children: [
                // Loading animation with ultra-fast UX
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
                  child: Column(
                    children: [
                      LoadingAnimations.pulsingDots(
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: AppTheme.spaceMd),
                      AnimationPresets.fadeIn(
                        delay: const Duration(
                            milliseconds: 150), // Reduced from 300ms to 150ms
                        child: Text(
                          'Loading content at lightning speed...', // Updated text
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spaceLg),
              ],
            ),
          ),
        ),

        // Skeleton loading for posts (ultra-fast)
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return AnimationPresets.staggeredSlideIn(
                index: index,
                staggerDelay: const Duration(
                    milliseconds: 50), // Reduced from 100ms to 50ms
                child: _buildPostSkeleton(),
              );
            },
            childCount:
                2, // Reduced from 3 to 2 skeleton posts for faster loading
          ),
        ),
      ],
    );
  }

  Widget _buildPostSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info skeleton
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 12,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Content skeleton
          Container(
            height: 16,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 16,
            width: MediaQuery.of(context).size.width * 0.7,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons skeleton
          Row(
            children: [
              Container(
                height: 32,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                height: 32,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                height: 32,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
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
            AnimationPresets.shake(
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            AnimationPresets.fadeIn(
              delay: const Duration(milliseconds: 200),
              child: const Text(
                'Failed to load posts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            AnimationPresets.fadeIn(
              delay: const Duration(milliseconds: 400),
              child: Text(
                _error ?? 'Unknown error occurred',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 16),
            AnimationPresets.fadeIn(
              delay: const Duration(milliseconds: 600),
              child: AnimationPresets.scaleOnPress(
                onPressed: _loadInitialPosts,
                child: ElevatedButton(
                  onPressed: null, // Disabled, handled by scaleOnPress
                  child: const Text('Retry'),
                ),
              ),
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
            AnimationPresets.fadeIn(
              delay: const Duration(milliseconds: 200),
              child: AnimationPresets.bounceIn(
                child: Container(
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
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            AnimationPresets.slideIn(
              delay: const Duration(milliseconds: 400),
              begin: const Offset(0, 30),
              child: Text(
                'Ready to Shine?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: null, // Use theme default
                    ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceSm),
            AnimationPresets.slideIn(
              delay: const Duration(milliseconds: 600),
              begin: const Offset(0, 30),
              child: Text(
                'Share your talents, achievements, and connect with the UTHM community!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: null, // Use theme default
                      height: 1.5,
                    ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            AnimationPresets.slideIn(
              delay: const Duration(milliseconds: 800),
              begin: const Offset(0, 30),
              child: AnimationPresets.scaleOnPress(
                onPressed: () {
                  debugPrint(
                      'ShowcaseFeedScreen: Post creation button pressed');
                  _navigateToPostCreation();
                },
                child: Container(
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
                    onPressed: null, // Disabled, handled by scaleOnPress
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
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            // Debug section
            AnimationPresets.fadeIn(
              delay: const Duration(milliseconds: 1000),
              child: _buildDebugSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            LoadingAnimations.pulsingDots(
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              'Loading more posts...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // Navigation and interaction methods

  void _handleLike(ShowcasePostModel post) async {
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
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          _posts[index] = updatedPost;
        }
      });

      // Real like/unlike
      await _showcaseService.toggleLike(post.id, _currentUser!.uid);

      // Refresh the post to ensure UI is in sync with database
      await _refreshSpecificPost(post.id);
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

  Future<void> _handleReaction(ReactionType reactionType, String postId) async {
    if (_currentUser == null) return;

    try {
      // Add haptic feedback
      HapticFeedback.lightImpact();

      // Add reaction to the post
      await _showcaseService.addReaction(postId, reactionType.name);

      // Refresh the post to ensure UI is in sync with database
      await _refreshSpecificPost(postId);

      debugPrint(
          'ShowcaseFeedScreen: Added ${reactionType.name} reaction to post $postId');
    } catch (e) {
      debugPrint('ShowcaseFeedScreen: Error adding reaction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add reaction: $e')),
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
    ).then((_) {
      // Refresh the specific post when returning from detail screen
      _refreshSpecificPost(post.id);
    });
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

  void _handlePostDeleted() {
    debugPrint('ShowcaseFeedScreen: Post deleted, refreshing feed...');
    // Refresh the feed to remove the deleted post
    _loadInitialPosts();
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
    ).then((_) {
      // Refresh the specific post when returning from detail screen
      _refreshSpecificPost(post.id);
    });
  }

  /// Refresh a specific post in the feed
  Future<void> _refreshSpecificPost(String postId) async {
    try {
      // Get updated post data
      final updatedPost = await _showcaseService.getPostById(postId);

      if (updatedPost != null && mounted) {
        setState(() {
          final index = _posts.indexWhere((p) => p.id == postId);
          if (index != -1) {
            _posts[index] = updatedPost;
          }
        });
        debugPrint('ShowcaseFeedScreen: Refreshed post $postId in feed');
      }
    } catch (e) {
      debugPrint('ShowcaseFeedScreen: Error refreshing post $postId: $e');
    }
  }

  /// Update a specific post in the feed (for external updates)
  void updatePostInFeed(ShowcasePostModel updatedPost) {
    if (mounted) {
      setState(() {
        final index = _posts.indexWhere((p) => p.id == updatedPost.id);
        if (index != -1) {
          _posts[index] = updatedPost;
        }
      });
      debugPrint('ShowcaseFeedScreen: Updated post ${updatedPost.id} in feed');
    }
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
