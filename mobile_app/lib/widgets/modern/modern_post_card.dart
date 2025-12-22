import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';
import '../../models/showcase_models.dart';
import '../../models/user_model.dart';
import '../../services/showcase_service.dart';
import '../../screens/student/showcase/post_creation_screen.dart';
import '../../utils/app_theme.dart';
import '../showcase/media_display_widget.dart';

class ModernPostCard extends StatefulWidget {
  final ShowcasePostModel post;
  final UserModel? currentUser;
  final Function(ShowcasePostModel) onLike;
  final Function(ShowcasePostModel) onComment;
  final Function(ShowcasePostModel) onShare;
  final Function(ShowcasePostModel) onUserTap;
  final Function(ShowcasePostModel) onPostTap;
  final VoidCallback? onPostDeleted;

  const ModernPostCard({
    super.key,
    required this.post,
    this.currentUser,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onUserTap,
    required this.onPostTap,
    this.onPostDeleted,
  });

  @override
  State<ModernPostCard> createState() => _ModernPostCardState();
}

class _ModernPostCardState extends State<ModernPostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _isLiked = widget.post.likes.contains(widget.currentUser?.uid);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ModernPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ✅ FIX: Use list length comparison instead of reference equality
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.likes.length != widget.post.likes.length ||
        oldWidget.currentUser?.uid != widget.currentUser?.uid) {
      setState(() {
        _isLiked = widget.post.likes.contains(widget.currentUser?.uid);
      });
    }
  }

  void _handleLike() {
    setState(() {
      _isLiked = !_isLiked;
    });

    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    widget.onLike(widget.post);
  }

  ImageProvider? _getProfileImageProvider(String? imageUrl) {
    if (imageUrl == null ||
        imageUrl.isEmpty ||
        imageUrl.trim().isEmpty ||
        imageUrl == 'null' ||
        imageUrl == 'file:///' ||
        Uri.tryParse(imageUrl)?.hasAbsolutePath != true) {
      return null;
    }

    try {
      if (imageUrl.startsWith('data:image')) {
        final base64String = imageUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        return MemoryImage(bytes);
      } else if (imageUrl.startsWith('http')) {
        return CachedNetworkImageProvider(imageUrl);
      } else if (imageUrl.startsWith('/') || imageUrl.contains('cache')) {
        return FileImage(File(imageUrl));
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error loading profile image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => widget.onPostTap(widget.post),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMd,
                vertical: AppTheme.spaceXs,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? colorScheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPostHeader(context),
                  if (widget.post.content.isNotEmpty)
                    _buildPostContent(context),
                  if (widget.post.hasMedia) ...[
                    _buildMediaContent(),
                  ] else ...[
                    const SizedBox.shrink(),
                  ],
                  _buildEngagementSection(context),
                  _buildActionButtons(context),
                  _buildCommentsSection(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => widget.onUserTap(widget.post),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                backgroundImage:
                    _getProfileImageProvider(widget.post.userProfileImage),
                child: _getProfileImageProvider(widget.post.userProfileImage) ==
                        null
                    ? Text(
                        widget.post.userName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.post.userName,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (widget.post.userRole == 'lecturer')
                      Container(
                        margin: const EdgeInsets.only(left: AppTheme.spaceXs),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceXs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusXs),
                        ),
                        child: Text(
                          'Lecturer',
                          style: textTheme.labelSmall?.copyWith(
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                if (widget.post.userHeadline != null &&
                    widget.post.userHeadline!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.post.userHeadline!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  _formatTimeAgo(widget.post.createdAt),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _buildMoreButton(context),
        ],
      ),
    );
  }

  Widget _buildMoreButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: IconButton(
        icon: Icon(
          Icons.more_horiz_rounded,
          color: colorScheme.onSurfaceVariant,
        ),
        onPressed: () {
          _showPostOptions(context);
        },
        iconSize: 20,
        constraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
      ),
    );
  }

  void _showPostOptions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppTheme.radiusLg),
            topRight: Radius.circular(AppTheme.radiusLg),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: AppTheme.spaceSm),
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            _buildOptionTile(
              context,
              icon: Icons.share_rounded,
              title: 'Share Post',
              onTap: () {
                Navigator.pop(context);
                widget.onShare(widget.post);
              },
            ),
            _buildOptionTile(
              context,
              icon: Icons.bookmark_border_rounded,
              title: 'Save Post',
              onTap: () {
                Navigator.pop(context);
                _savePostToBookmarks();
              },
            ),
            _buildOptionTile(
              context,
              icon: Icons.report_outlined,
              title: 'Report Post',
              onTap: () {
                Navigator.pop(context);
                _showReportDialog();
              },
            ),
            if (widget.currentUser?.id == widget.post.userId) ...[
              _buildOptionTile(
                context,
                icon: Icons.edit_rounded,
                title: 'Edit Post',
                onTap: () {
                  Navigator.pop(context);
                  _navigateToEditPost();
                },
              ),
              _buildOptionTile(
                context,
                icon: Icons.delete_rounded,
                title: 'Delete Post',
                color: AppTheme.errorColor,
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context);
                },
              ),
            ],
            SizedBox(
                height:
                    MediaQuery.of(context).padding.bottom + AppTheme.spaceMd),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        icon,
        color: color ?? colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        title: const Text('Delete Post'),
        content: const Text(
            'Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePost();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Deleting post...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // ✅ FIX: Use Provider instead of creating new instance
      final showcaseService =
          Provider.of<ShowcaseService>(context, listen: false);
      await showcaseService.deleteShowcasePost(widget.post.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        if (widget.onPostDeleted != null) {
          widget.onPostDeleted!();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete post: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _navigateToEditPost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostCreationScreen(
          editingPost: widget.post,
        ),
      ),
    );
  }

  void _showReportDialog() {
    final List<String> reportReasons = [
      'Inappropriate content',
      'Spam or misleading',
      'Harassment or bullying',
      'Hate speech',
      'Violence or dangerous content',
      'Copyright infringement',
      'False information',
      'Other',
    ];

    String? selectedReason;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          title: const Text('Report Post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Why are you reporting this post?',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              RadioGroup<String>(
                groupValue: selectedReason,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedReason = value;
                    });
                  }
                },
                child: Column(
                  children: reportReasons
                      .map(
                        (reason) => RadioListTile<String>(
                          title: Text(reason),
                          value: reason,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedReason != null
                  ? () {
                      Navigator.pop(context);
                      _submitReport(selectedReason!);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              child:
                  const Text('Report', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport(String reason) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post reported for: $reason'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _savePostToBookmarks() async {
    try {
      if (widget.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to save posts'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final savedPosts =
          prefs.getStringList('saved_posts_${widget.currentUser!.uid}') ?? [];

      if (!savedPosts.contains(widget.post.id)) {
        savedPosts.add(widget.post.id);
        await prefs.setStringList(
            'saved_posts_${widget.currentUser!.uid}', savedPosts);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post saved to bookmarks!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post already saved'),
              backgroundColor: AppTheme.infoColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save post: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildPostContent(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
      child: Text(
        widget.post.content,
        style: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildMediaContent() {
    if (widget.post.media.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: AppTheme.spaceMd),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: MediaDisplayWidget(
          media: widget.post.media,
          height: 250,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onMediaTap: (index) {
            widget.onPostTap(widget.post);
          },
        ),
      ),
    );
  }

  Widget _buildEngagementSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      child: Row(
        children: [
          _buildEngagementItem(
            context,
            icon: Icons.favorite_rounded,
            count: widget.post.likes.length,
            color: AppTheme.secondaryColor,
          ),
          const SizedBox(width: AppTheme.spaceLg),
          _buildEngagementItem(
            context,
            icon: Icons.chat_bubble_rounded,
            count: widget.post.comments.length,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: AppTheme.spaceLg),
          _buildEngagementItem(
            context,
            icon: Icons.visibility_rounded,
            count: widget.post.viewCount,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementItem(
    BuildContext context, {
    required IconData icon,
    required int count,
    required Color color,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: AppTheme.spaceXs),
        Text(
          _formatCount(count),
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMd,
        vertical: AppTheme.spaceSm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: widget.post.comments.isEmpty
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(AppTheme.radiusLg),
                bottomRight: Radius.circular(AppTheme.radiusLg),
              )
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            context,
            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
            label: 'Like',
            color: _isLiked
                ? AppTheme.secondaryColor
                : colorScheme.onSurfaceVariant,
            onTap: _handleLike,
          ),
          _buildActionButton(
            context,
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Comment',
            color: colorScheme.onSurfaceVariant,
            onTap: () {
              widget.onComment(widget.post);
            },
          ),
          _buildActionButton(
            context,
            icon: Icons.share_rounded,
            label: 'Share',
            color: colorScheme.onSurfaceVariant,
            onTap: () => widget.onShare(widget.post),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMd,
          vertical: AppTheme.spaceXs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: color,
            ),
            const SizedBox(width: AppTheme.spaceXs),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection(BuildContext context) {
    if (widget.post.comments.isEmpty) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Show only last 3 comments
    final commentsToShow = widget.post.comments.length > 3
        ? widget.post.comments.sublist(widget.post.comments.length - 3)
        : widget.post.comments;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMd,
        vertical: AppTheme.spaceSm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppTheme.radiusLg),
          bottomRight: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: AppTheme.spaceSm),
          ...commentsToShow.map((comment) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage:
                          _getProfileImageProvider(comment.userProfileImage),
                      child:
                          _getProfileImageProvider(comment.userProfileImage) ==
                                  null
                              ? Text(
                                  comment.userName
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(fontSize: 10),
                                )
                              : null,
                    ),
                    const SizedBox(width: AppTheme.spaceSm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                comment.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spaceXs),
                              Text(
                                comment.timeAgo,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            comment.content,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          if (widget.post.comments.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: GestureDetector(
                onTap: () => widget.onComment(widget.post),
                child: Text(
                  'View all ${widget.post.comments.length} comments',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
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

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
}
