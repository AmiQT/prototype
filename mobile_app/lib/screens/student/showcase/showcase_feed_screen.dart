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
// Using native Flutter widgets for competition simplicity
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

  // Track current user reactions for each post (LinkedIn-style)
  final Map<String, String?> _userReactions = {};

  // Pagination - OPTIMIZED for faster initial load
  static const int _postsPerPage =
      6; // Reduced from 10 for faster homepage loading

  // Stream subscription with lifecycle management
  StreamSubscription<List<ShowcasePostModel>>? _postsSubscription;
  bool _isSubscriptionActive = false; // Prevent multiple subscriptions

  /// Batch state updates to reduce setState calls and improve performance
  void _updateFeedState({
    List<ShowcasePostModel>? posts,
    bool? isLoading,
    bool? hasMore,
    String? error,
    bool? clearPosts = false,
    PostCategory? selectedCategory,
  }) {
    if (!mounted) return;

    setState(() {
      if (clearPosts == true) _posts.clear();
      if (posts != null) _posts = posts;
      if (isLoading != null) _isLoading = isLoading;
      if (hasMore != null) _hasMore = hasMore;
      if (error != null) _error = error;
      if (selectedCategory != null) _selectedCategory = selectedCategory;
    });
  }

  // Loading progress
  // Removed unused _loadingProgress field

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.filterCategory;
    _setupScrollListener();

    // Show loading state initially for better UX
    _updateFeedState(isLoading: true);

    // Initialize with proper auth loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWithAuth();
    });
  }

  Future<void> _initializeWithAuth() async {
    // Load current user with retry mechanism
    await _loadCurrentUserWithRetry();

    // FIXED: Start real-time subscription immediately for instant data
    if (_enableRealTimeUpdates) {
      _setupRealTimeSubscription();
    } else {
      _smartRefresh();
    }
  }

  // REMOVED: Unused methods _initializeDataLoading and _preloadData to eliminate duplicate API calls

  /// Setup real-time subscription with smart management
  void _setupRealTimeSubscription() {
    // Prevent multiple subscription creation
    if (_isSubscriptionActive) {
      debugPrint(
          'ShowcaseFeedScreen: Subscription already active, skipping...');
      return;
    }

    debugPrint(
        'ShowcaseFeedScreen: Setting up smart real-time subscription...');

    try {
      // Cancel any existing subscription first to prevent memory leaks
      _postsSubscription?.cancel();
      _isSubscriptionActive = true;

      // FIXED: Don't show loading state immediately - let subscription handle it
      // _updateFeedState(isLoading: true, clearPosts: true); // REMOVED

      // Setup ULTRA-FAST real-time subscription - OPTIMIZED for 5-second refresh
      _postsSubscription = _showcaseService
          .getShowcasePostsRealtimeStream(
        limit: 6, // Slightly larger batch for better content variety
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
            // SMART UPDATE: Only rebuild UI if data actually changed
            final hasChanges = _posts.length != posts.length ||
                _posts.asMap().entries.any((entry) {
                  final index = entry.key;
                  final oldPost = entry.value;
                  final newPost = index < posts.length ? posts[index] : null;

                  return newPost == null ||
                      oldPost.id != newPost.id ||
                      oldPost.likes.length != newPost.likes.length ||
                      oldPost.comments.length != newPost.comments.length ||
                      oldPost.reactions != newPost.reactions;
                });

            if (hasChanges || _posts.isEmpty) {
              debugPrint(
                  'ShowcaseFeedScreen: 🔄 Real-time changes detected - updating UI');
              setState(() {
                _posts = posts;
                _isLoading = false; // Force loading state to false
                _hasMore = posts.length >= _postsPerPage;
                _error = null;
              });

              // Only log feed update every 20th time
              if (_updateCount % 20 == 1) {
                debugPrint(
                    'ShowcaseFeedScreen: Feed updated with ${posts.length} posts [Update #$_updateCount] - Loading dismissed');
              }
            } else {
              debugPrint(
                  'ShowcaseFeedScreen: No real-time changes detected - UI stays the same');
            }
          }
        },
        onError: (error) {
          debugPrint(
              'ShowcaseFeedScreen: Ultra-fast real-time subscription error: $error');
          _isSubscriptionActive = false; // Reset flag on error
          if (mounted) {
            _updateFeedState(
              error: error.toString(),
              isLoading: false,
            );
          }
        },
        onDone: () {
          _isSubscriptionActive = false; // Reset flag when subscription ends
          debugPrint('ShowcaseFeedScreen: Real-time subscription ended');
          // Smart fallback - only if no posts loaded
          if (_posts.isEmpty && mounted) {
            _smartRefresh(); // Remove await from onDone callback
          }
        },
      );
    } catch (e) {
      _isSubscriptionActive = false; // Reset flag on exception
      debugPrint('ShowcaseFeedScreen: Error setting up subscription: $e');
      // Smart fallback - only if no posts loaded and mounted
      if (_posts.isEmpty && mounted) {
        _smartRefresh(); // Remove await from catch block
      }
    }
  }

  /// Smart manual refresh to prevent redundant calls
  void refreshFeed() {
    debugPrint('ShowcaseFeedScreen: Smart manual refresh requested');

    if (_enableRealTimeUpdates) {
      // Real-time mode - setup subscription (handles internal checks)
      _setupRealTimeSubscription();
    } else {
      // Manual mode - use smart refresh
      _smartRefresh(clearPosts: true); // Remove await from void method
    }
  }

  /// Smart refresh with priority system
  Future<void> _refreshFeedWithLoading() async {
    debugPrint('ShowcaseFeedScreen: Smart refresh initiated');

    _updateFeedState(
      isLoading: true,
      error: null,
    );

    // Smart refresh - use existing subscription if active, otherwise load directly
    if (_enableRealTimeUpdates && _isSubscriptionActive) {
      // Real-time subscription is active - just wait for natural update
      await Future.delayed(const Duration(milliseconds: 100));
    } else {
      // Load directly without redundant calls
      await _loadInitialPosts();
    }
  }

  /// Smart priority loading system - replaces redundant methods
  Future<void> _smartRefresh({bool clearPosts = false}) async {
    debugPrint(
        'ShowcaseFeedScreen: Smart refresh initiated (clear: $clearPosts)');

    if (clearPosts) {
      _updateFeedState(
        clearPosts: true,
        isLoading: true,
        error: null,
        hasMore: true,
      );
    } else {
      _updateFeedState(isLoading: true, error: null);
    }

    try {
      // Priority 1: Use real-time subscription if enabled and active
      if (_enableRealTimeUpdates) {
        if (!_isSubscriptionActive) {
          _setupRealTimeSubscription();
        }
        // Let subscription handle the data loading
        return;
      }

      // Priority 2: Direct API call for manual mode
      final posts = await _showcaseService
          .getShowcasePosts(
            limit: _postsPerPage,
            category: _selectedCategory,
          )
          .timeout(const Duration(seconds: 10)); // Reasonable timeout

      if (mounted) {
        _updateFeedState(
          posts: posts,
          isLoading: false,
          hasMore: posts.length >= _postsPerPage,
        );
      }
    } catch (e) {
      debugPrint('ShowcaseFeedScreen: Smart refresh error: $e');
      if (mounted) {
        _updateFeedState(
          error: e.toString(),
          isLoading: false,
        );
      }
    }
  }

  /// Update category filter with smart refresh
  void _updateCategoryFilter(PostCategory? category) {
    _updateFeedState(selectedCategory: category);

    // Smart refresh - avoid redundant calls
    if (_enableRealTimeUpdates) {
      _setupRealTimeSubscription(); // This handles subscription reset internally
    } else {
      _smartRefresh(); // Remove await
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
      // Cancel existing subscription to prevent memory leaks
      await _postsSubscription?.cancel();
      _isSubscriptionActive = false;

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
    _postsSubscription = null;
    _isSubscriptionActive = false; // Reset subscription flag
    super.dispose();
  }

  // REMOVED: _loadCurrentUser - replaced with _loadCurrentUserWithRetry

  Future<void> _loadCurrentUserWithRetry() async {
    final authService =
        Provider.of<SupabaseAuthService>(context, listen: false);

    // Try up to 3 times with delay
    for (int i = 0; i < 3; i++) {
      _currentUser = authService.currentUser;
      debugPrint(
          '🔄 ShowcaseFeedScreen: Retry $i - Current user: ${_currentUser?.uid ?? "NULL"}');

      if (_currentUser != null) {
        debugPrint('✅ ShowcaseFeedScreen: Current user loaded successfully');
        break;
      }

      // Wait and try again
      await Future.delayed(Duration(milliseconds: 500 * (i + 1)));

      // Force reload auth service
      try {
        await authService.initialize();
      } catch (e) {
        debugPrint('⚠️ ShowcaseFeedScreen: Auth service init error: $e');
      }
    }

    if (_currentUser == null) {
      debugPrint(
          '❌ ShowcaseFeedScreen: Failed to load current user after retries');
    }
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

  /// Load current user reactions for a list of posts (LinkedIn-style)
  Future<void> _loadUserReactions(List<ShowcasePostModel> posts) async {
    if (_currentUser == null) return;

    try {
      // Load user reactions for all posts in parallel for better performance
      final reactionFutures = posts.map((post) async {
        try {
          final reaction = await _showcaseService.getUserReaction(post.id);
          return MapEntry(post.id, reaction);
        } catch (e) {
          debugPrint('Error loading reaction for post ${post.id}: $e');
          return MapEntry(post.id, null);
        }
      });

      final reactions = await Future.wait(reactionFutures);

      // Update user reactions map
      for (final entry in reactions) {
        _userReactions[entry.key] = entry.value;
      }

      debugPrint(
          'ShowcaseFeedScreen: Loaded ${reactions.length} user reactions');
    } catch (e) {
      debugPrint('ShowcaseFeedScreen: Error loading user reactions: $e');
    }
  }

  Future<void> _loadInitialPosts() async {
    if (_isLoading) return;

    _updateFeedState(
      isLoading: true,
      error: null,
      clearPosts: true,
      hasMore: true,
      // Reset progress removed
    );

    try {
      // Cancel and reset subscription state
      _postsSubscription?.cancel();
      _isSubscriptionActive = false;

      // Update progress to show loading started
      // Progress tracking removed for simplicity

      // Use ultra-optimized method with service-level timeout for homepage
      final posts = await _showcaseService
          .getShowcasePosts(
            limit: _postsPerPage,
            category: _selectedCategory,
          )
          .timeout(const Duration(
              seconds: 15)); // Add reasonable timeout for better UX

      // Load current user reactions for these posts
      await _loadUserReactions(posts);

      // Update progress to show data loaded
      if (mounted) {
        // Progress tracking removed for simplicity
      }

      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
          _hasMore = posts.length >= _postsPerPage;
          // Progress tracking removed
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          // Progress tracking removed
        });
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMore) return;

    _updateFeedState(isLoading: true);

    try {
      // For now, just reload all posts since backend doesn't support pagination yet
      final allPosts = await _showcaseService.getShowcasePosts(
        limit: _postsPerPage * 2, // Get more posts for pagination
        category: _selectedCategory,
      );

      // Simple pagination simulation - skip already loaded posts
      final newPosts =
          allPosts.skip(_posts.length).take(_postsPerPage).toList();

      // Load user reactions for new posts
      await _loadUserReactions(newPosts);

      if (mounted) {
        // Add new posts to existing posts
        final updatedPosts = List<ShowcasePostModel>.from(_posts)
          ..addAll(newPosts);
        _updateFeedState(
          posts: updatedPosts,
          isLoading: false,
          hasMore: newPosts.length >= _postsPerPage,
        );
      }
    } catch (e) {
      if (mounted) {
        _updateFeedState(
          error: e.toString(),
          isLoading: false,
        );
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

    // RESTORED: Loading state for better UX (now that data loads properly)
    if (_posts.isEmpty && _isLoading) {
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
                  return ModernPostCard(
                    post: _posts[index],
                    currentUser: _currentUser,
                    currentUserReaction: _userReactions[
                        _posts[index].id], // Pass current user reaction
                    onLike: _handleLike,
                    onComment: _handleComment,
                    onShare: _handleShare,
                    onUserTap: _handleUserTap,
                    onPostTap: _handlePostTap,
                    onReaction: _handleReaction,
                    onPostDeleted: _handlePostDeleted,
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
        // Loading animation (now optimized with fast data loading)
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            child: Column(
              children: [
                // Fast loading animation
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
                      const CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: AppTheme.spaceMd),
                      Text(
                        'Loading your showcase...', // Updated text
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textSecondaryColor,
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

        // Minimal skeleton loading
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return _buildPostSkeleton();
            },
            childCount: 2, // Keep minimal for fast loading
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
            GestureDetector(
              onTap: () {
                debugPrint('ShowcaseFeedScreen: Post creation button pressed');
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
            const SizedBox(height: AppTheme.spaceLg),
            // Debug section
            _buildDebugSection(),
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
            const CircularProgressIndicator(
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

  Future<void> _handleLike(ShowcasePostModel post) async {
    if (_currentUser == null) return;

    // Add haptic feedback
    HapticFeedback.lightImpact();

    // Prevent multiple rapid clicks
    final postIndex = _posts.indexWhere((p) => p.id == post.id);
    if (postIndex == -1) return;

    final isCurrentlyLiked = post.isLikedBy(_currentUser!.uid);

    try {
      // Optimistic update with better state management
      final updatedLikes = isCurrentlyLiked
          ? post.likes.where((id) => id != _currentUser!.uid).toList()
          : [...post.likes, _currentUser!.uid];

      final optimisticPost = post.copyWith(likes: updatedLikes);

      // Update UI immediately with batch update system
      final updatedPosts = List<ShowcasePostModel>.from(_posts);
      updatedPosts[postIndex] = optimisticPost;
      _updateFeedState(posts: updatedPosts);

      // Single API call - no unnecessary refresh needed
      await _showcaseService.toggleLike(post.id, _currentUser!.uid);

      // ✅ FIX: Refresh with actual database state after API success
      final freshPost = await _showcaseService.getPostById(post.id);
      if (freshPost != null && mounted) {
        final updatedPosts = List<ShowcasePostModel>.from(_posts);
        updatedPosts[postIndex] = freshPost; // Update with real DB data
        _updateFeedState(posts: updatedPosts);
        debugPrint('Feed like UI refreshed with fresh database data');
      }

      // Success - optimistic update was correct, no additional operations needed
      debugPrint(
          'Like toggle successful for post ${post.id} (${isCurrentlyLiked ? 'unliked' : 'liked'})');
    } catch (e) {
      // Only revert on actual API errors
      final revertedPosts = List<ShowcasePostModel>.from(_posts);
      revertedPosts[postIndex] = post; // Revert to original state
      _updateFeedState(posts: revertedPosts);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update like: $e')),
        );
      }
    }
  }

  Future<void> _handleReaction(ReactionType reactionType, String postId) async {
    debugPrint(
        '🎯 _handleReaction called: ${reactionType.name} for post $postId');
    debugPrint('🔍 Current user: ${_currentUser?.uid ?? "NULL"}');

    if (_currentUser == null) {
      debugPrint('❌ _handleReaction: Current user is null, aborting');
      return;
    }

    // Find the post to update
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    final originalPost = _posts[postIndex];
    final previousUserReaction =
        _userReactions[postId]; // Track previous reaction

    try {
      // Add haptic feedback
      HapticFeedback.lightImpact();

      // Check if user is clicking on their current reaction (remove it)
      if (previousUserReaction == reactionType.name) {
        // User is removing their reaction
        _userReactions[postId] = null;

        // Decrement reaction count
        final updatedReactions = Map<String, int>.from(originalPost.reactions);
        final currentCount = updatedReactions[reactionType.name] ?? 0;
        if (currentCount > 0) {
          updatedReactions[reactionType.name] = currentCount - 1;
          if (updatedReactions[reactionType.name] == 0) {
            updatedReactions.remove(reactionType.name);
          }
        }

        final optimisticPost =
            originalPost.copyWith(reactions: updatedReactions);
        final updatedPosts = List<ShowcasePostModel>.from(_posts);
        updatedPosts[postIndex] = optimisticPost;
        _updateFeedState(posts: updatedPosts);

        // API call to remove reaction
        await _showcaseService.removeReaction(postId, reactionType.name);

        debugPrint('Reaction ${reactionType.name} removed from post $postId');
        return;
      }

      // User is adding/changing reaction
      _userReactions[postId] = reactionType.name;

      // Optimistic reaction update (count-based system)
      final updatedReactions = Map<String, int>.from(originalPost.reactions);

      // If user had a previous reaction, decrement it
      if (previousUserReaction != null) {
        final previousCount = updatedReactions[previousUserReaction] ?? 0;
        if (previousCount > 0) {
          updatedReactions[previousUserReaction] = previousCount - 1;
          if (updatedReactions[previousUserReaction] == 0) {
            updatedReactions.remove(previousUserReaction);
          }
        }
      }

      // Increment new reaction count
      final currentCount = updatedReactions[reactionType.name] ?? 0;
      updatedReactions[reactionType.name] = currentCount + 1;

      final optimisticPost = originalPost.copyWith(reactions: updatedReactions);

      // Update UI immediately with batch update
      final updatedPosts = List<ShowcasePostModel>.from(_posts);
      updatedPosts[postIndex] = optimisticPost;
      _updateFeedState(posts: updatedPosts);

      // API call - no unnecessary refresh needed
      await _showcaseService.addReaction(postId, reactionType.name);

      debugPrint(
          'Reaction ${reactionType.name} added successfully to post $postId');
    } catch (e) {
      // Revert optimistic updates on error
      _userReactions[postId] = previousUserReaction; // Revert user reaction
      final revertedPosts = List<ShowcasePostModel>.from(_posts);
      revertedPosts[postIndex] = originalPost;
      _updateFeedState(posts: revertedPosts);

      debugPrint('ShowcaseFeedScreen: Error adding reaction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add reaction: $e')),
        );
      }
    }
  }

  void _handleComment(ShowcasePostModel post) {
    debugPrint('💬 _handleComment called for post: ${post.id}');
    debugPrint('🔍 Current user: ${_currentUser?.uid ?? "NULL"}');

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
    debugPrint('🗑️ _handlePostDeleted called');
    debugPrint('🔍 Current user: ${_currentUser?.uid ?? "NULL"}');
    debugPrint('ShowcaseFeedScreen: Post deleted, refreshing feed...');
    // Refresh the feed to remove the deleted post
    _smartRefresh(clearPosts: true);
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
