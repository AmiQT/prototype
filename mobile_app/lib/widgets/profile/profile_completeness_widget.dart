import 'package:flutter/material.dart';
import '../../models/profile_model.dart';
import '../../utils/app_theme.dart';

/// Widget that shows profile completeness with progress indicator
class ProfileCompletenessWidget extends StatelessWidget {
  final ProfileModel profile;
  final VoidCallback? onTap;
  final bool showDetails;

  const ProfileCompletenessWidget({
    super.key,
    required this.profile,
    this.onTap,
    this.showDetails = true,
  });

  /// Calculate profile completeness percentage
  ProfileCompletenessData _calculateCompleteness() {
    final List<ProfileField> fields = [];

    // Required fields (more weight)
    fields.add(ProfileField(
      name: 'Nama',
      isComplete: profile.fullName.isNotEmpty,
      weight: 2,
    ));

    fields.add(ProfileField(
      name: 'Email',
      isComplete: profile.academicInfo?.studentId.isNotEmpty ?? false,
      weight: 2,
    ));

    fields.add(ProfileField(
      name: 'Gambar Profil',
      isComplete: profile.profileImageUrl != null &&
          profile.profileImageUrl!.isNotEmpty,
      weight: 1,
    ));

    fields.add(ProfileField(
      name: 'Bio',
      isComplete: profile.bio != null && profile.bio!.isNotEmpty,
      weight: 1,
    ));

    fields.add(ProfileField(
      name: 'Program',
      isComplete: profile.academicInfo?.program != null &&
          profile.academicInfo!.program.isNotEmpty,
      weight: 1,
    ));

    fields.add(ProfileField(
      name: 'Fakulti',
      isComplete: profile.academicInfo?.faculty != null &&
          profile.academicInfo!.faculty.isNotEmpty,
      weight: 1,
    ));

    fields.add(ProfileField(
      name: 'Semester',
      isComplete: profile.academicInfo?.currentSemester != null,
      weight: 1,
    ));

    fields.add(ProfileField(
      name: 'Kemahiran',
      isComplete: profile.skills.isNotEmpty,
      weight: 1,
    ));

    fields.add(ProfileField(
      name: 'Minat',
      isComplete: profile.interests.isNotEmpty,
      weight: 1,
    ));

    // Calculate totals
    int totalWeight = 0;
    int completedWeight = 0;
    final incompleteFields = <ProfileField>[];

    for (final field in fields) {
      totalWeight += field.weight;
      if (field.isComplete) {
        completedWeight += field.weight;
      } else {
        incompleteFields.add(field);
      }
    }

    final percentage = (completedWeight / totalWeight * 100).round();

    return ProfileCompletenessData(
      percentage: percentage,
      completedFields: fields.where((f) => f.isComplete).length,
      totalFields: fields.length,
      incompleteFields: incompleteFields,
    );
  }

  Color _getProgressColor(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  String _getStatusMessage(int percentage) {
    if (percentage >= 100) return 'Profil lengkap! 🎉';
    if (percentage >= 80) return 'Hampir siap!';
    if (percentage >= 50) return 'Teruskan usaha!';
    return 'Lengkapkan profil anda';
  }

  @override
  Widget build(BuildContext context) {
    final data = _calculateCompleteness();
    final progressColor = _getProgressColor(data.percentage);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              progressColor.withValues(alpha: 0.1),
              progressColor.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: progressColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Circular progress
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: data.percentage / 100,
                        strokeWidth: 6,
                        backgroundColor: progressColor.withValues(alpha: 0.2),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                      Text(
                        '${data.percentage}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: progressColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kelengkapan Profil',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusMessage(data.percentage),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: progressColor,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${data.completedFields}/${data.totalFields} medan dilengkapkan',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),

                if (onTap != null && data.percentage < 100)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: progressColor,
                  ),
              ],
            ),

            // Linear progress bar
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: data.percentage / 100,
                backgroundColor: progressColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 8,
              ),
            ),

            // Incomplete fields list
            if (showDetails && data.incompleteFields.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: data.incompleteFields.take(3).map((field) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: progressColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 14,
                          color: progressColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          field.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: progressColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              if (data.incompleteFields.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '+${data.incompleteFields.length - 3} lagi',
                    style: TextStyle(
                      fontSize: 12,
                      color: progressColor,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact version for smaller spaces
class ProfileCompletenessCompact extends StatelessWidget {
  final ProfileModel profile;
  final VoidCallback? onTap;

  const ProfileCompletenessCompact({
    super.key,
    required this.profile,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileCompletenessWidget(
      profile: profile,
      onTap: onTap,
      showDetails: false,
    );
  }
}

/// Mini badge showing just the percentage
class ProfileCompletenessBadge extends StatelessWidget {
  final ProfileModel profile;
  final double size;

  const ProfileCompletenessBadge({
    super.key,
    required this.profile,
    this.size = 40,
  });

  int _calculatePercentage() {
    int completed = 0;
    int total = 9;

    if (profile.fullName.isNotEmpty) completed++;
    if (profile.academicInfo?.studentId.isNotEmpty ?? false) completed++;
    if (profile.profileImageUrl != null &&
        profile.profileImageUrl!.isNotEmpty) {
      completed++;
    }
    if (profile.bio != null && profile.bio!.isNotEmpty) completed++;
    if (profile.academicInfo?.program != null &&
        profile.academicInfo!.program.isNotEmpty) {
      completed++;
    }
    if (profile.academicInfo?.faculty.isNotEmpty ?? false) completed++;
    if (profile.academicInfo?.currentSemester != null) completed++;
    if (profile.skills.isNotEmpty) completed++;
    if (profile.interests.isNotEmpty) completed++;

    return (completed / total * 100).round();
  }

  Color _getColor(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = _calculatePercentage();
    final color = _getColor(percentage);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percentage / 100,
            strokeWidth: 3,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Text(
            '$percentage',
            style: TextStyle(
              fontSize: size * 0.3,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Data class for profile completeness calculation
class ProfileCompletenessData {
  final int percentage;
  final int completedFields;
  final int totalFields;
  final List<ProfileField> incompleteFields;

  ProfileCompletenessData({
    required this.percentage,
    required this.completedFields,
    required this.totalFields,
    required this.incompleteFields,
  });
}

/// Represents a profile field
class ProfileField {
  final String name;
  final bool isComplete;
  final int weight;

  ProfileField({
    required this.name,
    required this.isComplete,
    this.weight = 1,
  });
}
