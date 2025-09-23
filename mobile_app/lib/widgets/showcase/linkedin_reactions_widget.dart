import 'package:flutter/material.dart';
import '../../models/showcase_models.dart';
import '../../utils/app_theme.dart';

/// LinkedIn-style reactions widget
class LinkedInReactionsWidget extends StatefulWidget {
  final ShowcasePostModel post;
  final Function(ReactionType, String postId) onReaction;
  final String? currentUserReaction; // Current user's reaction type
  final bool showCounts;

  const LinkedInReactionsWidget({
    super.key,
    required this.post,
    required this.onReaction,
    this.currentUserReaction,
    this.showCounts = true,
  });

  @override
  State<LinkedInReactionsWidget> createState() =>
      _LinkedInReactionsWidgetState();
}

class _LinkedInReactionsWidgetState extends State<LinkedInReactionsWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _showReactions = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100), // FAST: Reduced from 200ms
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOut), // FAST: Removed slow elasticOut
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Reaction counts display
        if (widget.showCounts && widget.post.totalReactions > 0)
          _buildReactionCounts(),

        // Reaction buttons
        _buildReactionButtons(),
      ],
    );
  }

  Widget _buildReactionCounts() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top reactions display
          ...() {
            final sortedReactions = widget.post.reactions.entries
                .where((entry) => entry.value > 0)
                .toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return sortedReactions.take(3).map((entry) {
              final type = ReactionType.values.firstWhere(
                (t) => t.name == entry.key,
                orElse: () => ReactionType.like,
              );
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '${type.emoji}${entry.value}',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }).toList();
          }(),

          if (widget.post.totalReactions > 3)
            Text(
              '+${widget.post.totalReactions - 3}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReactionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildReactionButton(ReactionType.like),
        _buildReactionButton(ReactionType.love),
        _buildReactionButton(ReactionType.celebrate),
        _buildReactionButton(ReactionType.insightful),
        _buildReactionButton(ReactionType.funny),
        _buildReactionButton(ReactionType.support),
      ],
    );
  }

  Widget _buildReactionButton(ReactionType type) {
    final count = widget.post.getReactionCount(type);
    final isUserReacted = widget.currentUserReaction == type.name;
    final isActive = count > 0;

    return GestureDetector(
      onTap: () {
        debugPrint(
            '🎯 LinkedInReactionsWidget: ${type.name} tapped for post ${widget.post.id}');
        widget.onReaction(type, widget.post.id);
        _animationController.forward().then((_) {
          _animationController.reverse();
        });
      },
      onLongPress: () {
        setState(() {
          _showReactions = !_showReactions;
        });
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _showReactions ? _scaleAnimation.value : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isUserReacted
                    ? AppTheme.primaryColor.withValues(alpha: 0.2)
                    : isActive
                        ? AppTheme.primaryColor.withValues(alpha: 0.1)
                        : null,
                borderRadius: BorderRadius.circular(16),
                border: isUserReacted
                    ? Border.all(color: AppTheme.primaryColor, width: 1.5)
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    type.emoji,
                    style: TextStyle(
                      fontSize: 16,
                      color: isUserReacted || isActive
                          ? AppTheme.primaryColor
                          : Colors.grey[600],
                    ),
                  ),
                  if (widget.showCounts && count > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 12,
                        color: isUserReacted || isActive
                            ? AppTheme.primaryColor
                            : Colors.grey[600],
                        fontWeight:
                            isUserReacted ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Compact reactions widget for feed view
class CompactReactionsWidget extends StatelessWidget {
  final ShowcasePostModel post;
  final Function(ReactionType, String postId) onReaction;
  final String? currentUserReaction; // Current user's reaction type

  const CompactReactionsWidget({
    super.key,
    required this.post,
    required this.onReaction,
    this.currentUserReaction,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint(
        '🔍 CompactReactionsWidget build: post ${post.id}, totalReactions: ${post.totalReactions}');

    if (post.totalReactions == 0) {
      debugPrint(
          '🔍 CompactReactionsWidget: Using simple like button for post ${post.id}');
      return _buildSimpleLikeButton();
    }

    debugPrint(
        '🔍 CompactReactionsWidget: Using reaction buttons for post ${post.id}');

    return Row(
      children: [
        // Show top 2 reactions
        ...() {
          final sortedReactions = post.reactions.entries
              .where((entry) => entry.value > 0)
              .toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return sortedReactions.take(2).map((entry) {
            final type = ReactionType.values.firstWhere(
              (t) => t.name == entry.key,
              orElse: () => ReactionType.like,
            );
            final isUserReacted = currentUserReaction == type.name;

            return GestureDetector(
              onTap: () {
                debugPrint(
                    '🎯 CompactReactionsWidget: ${type.name} tapped for post ${post.id}');
                onReaction(type, post.id);
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isUserReacted
                      ? AppTheme.primaryColor.withValues(alpha: 0.2)
                      : AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: isUserReacted
                      ? Border.all(color: AppTheme.primaryColor, width: 1.5)
                      : null,
                ),
                child: Text(
                  '${type.emoji}${entry.value}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isUserReacted ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList();
        }(),

        // Show total count if more than 2
        if (post.totalReactions > 2)
          Text(
            '+${post.totalReactions - 2}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }

  Widget _buildSimpleLikeButton() {
    debugPrint(
        '🔧 CompactReactionsWidget: Building simple like button for post ${post.id}');
    return GestureDetector(
      onTap: () {
        debugPrint(
            '🎯 CompactReactionsWidget: Simple like tapped for post ${post.id}');
        debugPrint('🔧 CompactReactionsWidget: Calling onReaction callback...');
        onReaction(ReactionType.like, post.id);
        debugPrint('🔧 CompactReactionsWidget: onReaction callback completed');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ReactionType.like.emoji,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Like',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
