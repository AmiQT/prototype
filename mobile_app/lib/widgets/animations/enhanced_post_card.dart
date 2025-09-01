import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/showcase_models.dart';
import '../../models/user_model.dart';
import '../../utils/animation_system.dart';
import '../../utils/app_theme.dart';
import 'micro_interactions.dart';
import 'loading_animations.dart';

/// Enhanced post card with rich animations and interactions
class EnhancedPostCard extends StatefulWidget {
  final ShowcasePostModel post;
  final UserModel? currentUser;
  final Function(ShowcasePostModel) onLike;
  final Function(ShowcasePostModel) onComment;
  final Function(ShowcasePostModel) onShare;
  final Function(ShowcasePostModel) onUserTap;
  final Function(ShowcasePostModel) onPostTap;
  final VoidCallback? onPostDeleted;
  final int index; // For staggered animation

  const EnhancedPostCard({
    super.key,
    required this.post,
    this.currentUser,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onUserTap,
    required this.onPostTap,
    this.onPostDeleted,
    this.index = 0,
  });

  @override
  State<EnhancedPostCard> createState() => _EnhancedPostCardState();
}

class _EnhancedPostCardState extends State<EnhancedPostCard>
    with TickerProviderStateMixin {
  late AnimationController _cardController;
  late AnimationController _interactionController;
  late AnimationController _mediaController;

  late Animation<double> _cardAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _mediaAnimation;

  bool _isLiked = false;
  bool _isBookmarked = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLikedBy(widget.currentUser?.uid ?? '');
    _isBookmarked = false; // Add bookmark functionality later

    // Card entrance animation
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Interaction animations
    _interactionController = AnimationController(
      duration: AnimationSystem.fast,
      vsync: this,
    );

    // Media loading animation
    _mediaController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _setupAnimations();
    _startCardAnimation();
  }

  void _setupAnimations() {
    // Staggered card entrance
    final delay = widget.index * 100;
    final totalDuration = _cardController.duration!.inMilliseconds;
    final startTime = (delay / totalDuration).clamp(0.0, 1.0);

    _cardAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Interval(
        startTime,
        1.0,
        curve: AnimationSystem.smoothIn,
      ),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Interval(
        startTime,
        1.0,
        curve: Curves.easeOut,
      ),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Interval(
        startTime,
        1.0,
        curve: AnimationSystem.slideIn,
      ),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Interval(
        startTime,
        1.0,
        curve: AnimationSystem.bounceIn,
      ),
    ));

    _mediaAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mediaController,
      curve: Curves.easeOut,
    ));
  }

  void _startCardAnimation() {
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) {
        _cardController.forward();
      }
    });
  }

  void _handleLike() {
    // Update local state optimistically
    setState(() {
      _isLiked = !_isLiked;
    });

    // Call the parent's like handler
    widget.onLike(widget.post);
  }

  void _handleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    AnimationSystem.lightImpact();
  }

  void _handleCardTap() {
    _interactionController.forward().then((_) {
      _interactionController.reverse();
    });
    widget.onPostTap(widget.post);
  }

  @override
  void dispose() {
    _cardController.dispose();
    _interactionController.dispose();
    _mediaController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EnhancedPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update _isLiked when the post data changes
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.likes != widget.post.likes ||
        oldWidget.currentUser?.uid != widget.currentUser?.uid) {
      setState(() {
        _isLiked = widget.post.isLikedBy(widget.currentUser?.uid ?? '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _cardAnimation,
        _fadeAnimation,
        _slideAnimation,
        _scaleAnimation,
        _interactionController,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value *
              (1.0 - (_interactionController.value * 0.02)),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildCard(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMd,
        vertical: AppTheme.spaceXs,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildContent(),
          _buildMedia(),
          _buildInteractions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      child: Row(
        children: [
          _buildProfileImage(),
          const SizedBox(width: AppTheme.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserName(),
                _buildPostMeta(),
              ],
            ),
          ),
          _buildMoreButton(),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: () => widget.onUserTap(widget.post),
      child: Hero(
        tag: 'profile_${widget.post.userId}',
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: widget.post.userProfileImageUrl != null
                ? CachedNetworkImage(
                    imageUrl: widget.post.userProfileImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        LoadingAnimations.pulsingDots(
                      color: Theme.of(context).colorScheme.primary,
                      size: 4,
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.person,
                      color: Colors.grey,
                    ),
                  )
                : const Icon(
                    Icons.person,
                    color: Colors.grey,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserName() {
    return Text(
      widget.post.userName,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildPostMeta() {
    return Row(
      children: [
        Text(
          _formatTimeAgo(widget.post.createdAt),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color:
                _getCategoryColor(widget.post.category).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _getCategoryName(widget.post.category),
            style: TextStyle(
              color: _getCategoryColor(widget.post.category),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoreButton() {
    return MicroInteractions.rippleEffect(
      onTap: () => _showMoreOptions(),
      rippleColor: Colors.grey.withValues(alpha: 0.1),
      borderRadius: 20,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: const Icon(
          Icons.more_horiz,
          color: Colors.grey,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.post.content.isNotEmpty)
            GestureDetector(
              onTap: _handleCardTap,
              child: AnimatedCrossFade(
                duration: AnimationSystem.fast,
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: Text(
                  widget.post.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                secondChild: Text(
                  widget.post.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          if (widget.post.content.length > 100)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _isExpanded ? 'Show less' : 'Show more',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMedia() {
    if (widget.post.mediaUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      child: AnimatedBuilder(
        animation: _mediaAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.8 + (_mediaAnimation.value * 0.2),
            child: Opacity(
              opacity: _mediaAnimation.value,
              child: _buildMediaGrid(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMediaGrid() {
    if (widget.post.mediaUrls.length == 1) {
      return _buildSingleMedia(widget.post.mediaUrls.first);
    } else if (widget.post.mediaUrls.length == 2) {
      return _buildTwoMedia();
    } else {
      return _buildMultipleMedia();
    }
  }

  Widget _buildSingleMedia(String url) {
    return GestureDetector(
      onTap: _handleCardTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (context, url) => LoadingAnimations.skeletonCard(
              height: 200,
              padding: EdgeInsets.zero,
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTwoMedia() {
    return Row(
      children: [
        Expanded(
          child: _buildSingleMedia(widget.post.mediaUrls[0]),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _buildSingleMedia(widget.post.mediaUrls[1]),
        ),
      ],
    );
  }

  Widget _buildMultipleMedia() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSingleMedia(widget.post.mediaUrls[0]),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildSingleMedia(widget.post.mediaUrls[1]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _buildSingleMedia(widget.post.mediaUrls[2]),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Stack(
                children: [
                  _buildSingleMedia(widget.post.mediaUrls[3]),
                  if (widget.post.mediaUrls.length > 4)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Center(
                        child: Text(
                          '+${widget.post.mediaUrls.length - 4}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInteractions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
      child: Row(
        children: [
          _buildLikeButton(),
          const SizedBox(width: AppTheme.spaceLg),
          _buildCommentButton(),
          const SizedBox(width: AppTheme.spaceLg),
          _buildShareButton(),
          const Spacer(),
          _buildBookmarkButton(),
        ],
      ),
    );
  }

  Widget _buildLikeButton() {
    return Row(
      children: [
        MicroInteractions.animatedLikeButton(
          isLiked: _isLiked,
          onTap: _handleLike,
          size: 20,
          likedColor: Colors.red,
          unlikedColor: Colors.grey,
        ),
        const SizedBox(width: 4),
        MicroInteractions.animatedCounter(
          value: widget.post.likes.length,
          color: Colors.grey[600]!,
          textStyle: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentButton() {
    return Row(
      children: [
        MicroInteractions.rippleEffect(
          onTap: () => widget.onComment(widget.post),
          rippleColor: Colors.blue.withValues(alpha: 0.1),
          borderRadius: 20,
          child: const Icon(
            Icons.chat_bubble_outline,
            size: 20,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 4),
        MicroInteractions.animatedCounter(
          value: widget.post.comments.length,
          color: Colors.grey[600]!,
          textStyle: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildShareButton() {
    return MicroInteractions.rippleEffect(
      onTap: () => widget.onShare(widget.post),
      rippleColor: Colors.green.withValues(alpha: 0.1),
      borderRadius: 20,
      child: const Icon(
        Icons.share_outlined,
        size: 20,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildBookmarkButton() {
    return MicroInteractions.animatedBookmarkButton(
      isBookmarked: _isBookmarked,
      onTap: _handleBookmark,
      size: 20,
      bookmarkedColor: Colors.blue,
      unbookmarkedColor: Colors.grey,
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(context);
                // Handle report
              },
            ),
            if (widget.currentUser?.uid == widget.post.userId)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onPostDeleted?.call();
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  Color _getCategoryColor(PostCategory category) {
    switch (category) {
      case PostCategory.academic:
        return Colors.blue;
      case PostCategory.creative:
        return Colors.purple;
      case PostCategory.technical:
        return Colors.green;
      case PostCategory.sports:
        return Colors.orange;
      case PostCategory.volunteer:
        return Colors.teal;
      case PostCategory.achievement:
        return Colors.amber;
      case PostCategory.project:
        return Colors.indigo;
      case PostCategory.general:
        return Colors.grey;
    }
  }

  String _getCategoryName(PostCategory category) {
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
