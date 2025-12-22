import 'package:flutter/material.dart';
import '../../models/showcase_models.dart';
import '../../utils/app_theme.dart';

/// LinkedIn-style post analytics widget
class PostAnalyticsWidget extends StatelessWidget {
  final ShowcasePostModel post;
  final bool showDetailed;

  const PostAnalyticsWidget({
    super.key,
    required this.post,
    this.showDetailed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildEngagementMetrics(),
          if (showDetailed) ...[
            const SizedBox(height: 16),
            _buildDetailedAnalytics(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(
          Icons.analytics_outlined,
          size: 20,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 8),
        const Text(
          'Post Analytics',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const Spacer(),
        Text(
          post.timeAgo,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEngagementMetrics() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use Grid layout for small screens, Row for larger screens
        if (constraints.maxWidth < 280) {
          // Very small screen - use 2x2 grid
          return Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.spaceEvenly,
            children: [
              _buildMetricItem(
                icon: Icons.visibility,
                label: 'Views',
                value: post.viewCount,
                color: Colors.blue,
              ),
              _buildMetricItem(
                icon: Icons.favorite,
                label: 'Reactions',
                value: post.totalReactions,
                color: Colors.red,
              ),
              _buildMetricItem(
                icon: Icons.chat_bubble,
                label: 'Comments',
                value: post.commentsCount,
                color: Colors.green,
              ),
              _buildMetricItem(
                icon: Icons.share,
                label: 'Shares',
                value: post.sharesCount,
                color: Colors.orange,
              ),
            ],
          );
        }
        // Normal row layout for larger screens
        return Row(
          children: [
            _buildMetricItem(
              icon: Icons.visibility,
              label: 'Views',
              value: post.viewCount,
              color: Colors.blue,
            ),
            const SizedBox(width: 16),
            _buildMetricItem(
              icon: Icons.favorite,
              label: 'Reactions',
              value: post.totalReactions,
              color: Colors.red,
            ),
            const SizedBox(width: 16),
            _buildMetricItem(
              icon: Icons.chat_bubble,
              label: 'Comments',
              value: post.commentsCount,
              color: Colors.green,
            ),
            const SizedBox(width: 16),
            _buildMetricItem(
              icon: Icons.share,
              label: 'Shares',
              value: post.sharesCount,
              color: Colors.orange,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$value',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedAnalytics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (post.hasTags) _buildTagsSection(),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: post.tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '#$tag',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Compact analytics for feed view
class CompactAnalyticsWidget extends StatelessWidget {
  final ShowcasePostModel post;

  const CompactAnalyticsWidget({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (post.viewCount > 0) ...[
          Icon(
            Icons.visibility,
            size: 14,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            '${post.viewCount}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
        ],
        if (post.totalReactions > 0) ...[
          Icon(
            Icons.favorite,
            size: 14,
            color: Colors.red[400],
          ),
          const SizedBox(width: 4),
          Text(
            '${post.totalReactions}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red[400],
            ),
          ),
          const SizedBox(width: 12),
        ],
        if (post.commentsCount > 0) ...[
          Icon(
            Icons.chat_bubble,
            size: 14,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            '${post.commentsCount}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
}
