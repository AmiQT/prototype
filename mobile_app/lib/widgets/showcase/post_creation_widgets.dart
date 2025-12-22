import 'package:flutter/material.dart';
import '../../models/showcase_models.dart';
import '../../models/post_creation_models.dart';

/// Reusable widgets for post creation functionality

/// Widget for displaying upload progress with file details
class UploadProgressWidget extends StatelessWidget {
  final Map<String, MediaUploadProgress> progressMap;
  final VoidCallback? onCancel;

  const UploadProgressWidget({
    super.key,
    required this.progressMap,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.cloud_upload, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Uploading Files',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (onCancel != null)
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...progressMap.entries.map((entry) {
            final progress = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          progress.fileName,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${(progress.progress * 100).toInt()}%',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progress.progress,
                    backgroundColor: Colors.blue[100],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress.hasError ? Colors.red : Colors.blue,
                    ),
                  ),
                  if (progress.hasError && progress.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        progress.error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Widget for category selection with icons
class CategorySelectorWidget extends StatelessWidget {
  final PostCategory selectedCategory;
  final Function(PostCategory) onCategoryChanged;

  const CategorySelectorWidget({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PostCategory.values.map((category) {
              final isSelected = category == selectedCategory;
              return GestureDetector(
                onTap: () => onCategoryChanged(category),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary 
                        : Colors.white, // Always white when not selected
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getCategoryDisplayName(category),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
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

/// Widget for privacy selection with descriptions
class PrivacySelectorWidget extends StatelessWidget {
  final PostPrivacy selectedPrivacy;
  final Function(PostPrivacy) onPrivacyChanged;

  const PrivacySelectorWidget({
    super.key,
    required this.selectedPrivacy,
    required this.onPrivacyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Who can see this post?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          RadioGroup<PostPrivacy>(
            groupValue: selectedPrivacy,
            onChanged: (value) {
              if (value != null) onPrivacyChanged(value);
            },
            child: Column(
              children: PostPrivacy.values.map((privacy) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: RadioListTile<PostPrivacy>(
                    value: privacy,
                    title: Row(
                      children: [
                        Icon(_getPrivacyIcon(privacy), size: 20),
                        const SizedBox(width: 8),
                        Text(_getPrivacyDisplayName(privacy)),
                      ],
                    ),
                    subtitle: Text(
                      _getPrivacyDescription(privacy),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPrivacyIcon(PostPrivacy privacy) {
    switch (privacy) {
      case PostPrivacy.public:
        return Icons.public;
      case PostPrivacy.department:
        return Icons.business;
      case PostPrivacy.friends:
        return Icons.people;
    }
  }

  String _getPrivacyDisplayName(PostPrivacy privacy) {
    switch (privacy) {
      case PostPrivacy.public:
        return 'Public';
      case PostPrivacy.department:
        return 'Department Only';
      case PostPrivacy.friends:
        return 'Friends Only';
    }
  }

  String _getPrivacyDescription(PostPrivacy privacy) {
    switch (privacy) {
      case PostPrivacy.public:
        return 'Anyone can see this post';
      case PostPrivacy.department:
        return 'Only people in your department can see this';
      case PostPrivacy.friends:
        return 'Only your connections can see this';
    }
  }
}

/// Widget for displaying post templates
class PostTemplateWidget extends StatelessWidget {
  final PostTemplate template;
  final VoidCallback onTap;

  const PostTemplateWidget({
    super.key,
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          template.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (template.description != null) ...[
              const SizedBox(height: 4),
              Text(
                template.description!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: template.suggestedTags.take(3).map((tag) {
                return Chip(
                  label: Text('#$tag'),
                  labelStyle: const TextStyle(fontSize: 10),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
