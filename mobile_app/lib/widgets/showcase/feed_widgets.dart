import 'package:flutter/material.dart';
import '../../models/showcase_models.dart';

/// Filter bottom sheet for showcase feed
class FilterBottomSheet extends StatefulWidget {
  final PostCategory? selectedCategory;
  final Function(PostCategory?) onCategoryChanged;

  const FilterBottomSheet({
    super.key,
    this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  PostCategory? _tempSelectedCategory;

  @override
  void initState() {
    super.initState();
    _tempSelectedCategory = widget.selectedCategory;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Title
          const Text(
            'Filter Posts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Category filter
          const Text(
            'Category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          // All categories option
          _buildCategoryOption(null, 'All Categories', Icons.apps),
          
          // Individual categories
          ...PostCategory.values.map((category) {
            return _buildCategoryOption(
              category,
              _getCategoryDisplayName(category),
              _getCategoryIcon(category),
            );
          }),
          
          const SizedBox(height: 20),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _tempSelectedCategory = null;
                    });
                  },
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onCategoryChanged(_tempSelectedCategory);
                  },
                  child: const Text('Apply Filter'),
                ),
              ),
            ],
          ),
          
          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildCategoryOption(PostCategory? category, String title, IconData icon) {
    final isSelected = _tempSelectedCategory == category;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _tempSelectedCategory = category;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300]!,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected 
                    ? Theme.of(context).primaryColor
                    : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected 
                        ? Theme.of(context).primaryColor
                        : Colors.grey[800],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
            ],
          ),
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

  IconData _getCategoryIcon(PostCategory category) {
    switch (category) {
      case PostCategory.academic:
        return Icons.school;
      case PostCategory.creative:
        return Icons.palette;
      case PostCategory.technical:
        return Icons.code;
      case PostCategory.sports:
        return Icons.sports;
      case PostCategory.volunteer:
        return Icons.volunteer_activism;
      case PostCategory.achievement:
        return Icons.emoji_events;
      case PostCategory.project:
        return Icons.work;
      case PostCategory.general:
        return Icons.chat;
    }
  }
}

/// Loading shimmer widget for posts
class PostLoadingShimmer extends StatelessWidget {
  const PostLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white, // Always white for showcase cards
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header shimmer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildShimmerBox(48, 48, isCircle: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmerBox(120, 16),
                      const SizedBox(height: 4),
                      _buildShimmerBox(80, 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Content shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(double.infinity, 16),
                const SizedBox(height: 4),
                _buildShimmerBox(200, 16),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Media shimmer
          _buildShimmerBox(double.infinity, 200),
          
          const SizedBox(height: 12),
          
          // Action buttons shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildShimmerBox(60, 32),
                const SizedBox(width: 16),
                _buildShimmerBox(80, 32),
                const SizedBox(width: 16),
                _buildShimmerBox(60, 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBox(double width, double height, {bool isCircle = false}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: isCircle 
            ? BorderRadius.circular(height / 2)
            : BorderRadius.circular(4),
      ),
    );
  }
}

/// Empty state widget for feed
class FeedEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onActionPressed;
  final String? actionText;

  const FeedEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onActionPressed,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (onActionPressed != null && actionText != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.add),
                label: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
