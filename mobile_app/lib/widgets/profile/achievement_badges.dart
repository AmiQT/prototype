import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// Achievement badge types
enum BadgeType {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
}

/// Achievement categories
enum AchievementCategory {
  social, // Likes, shares, connections
  content, // Posts, comments
  engagement, // Daily active, streaks
  skills, // Skills verified
  events, // Event participation
  special, // Special achievements
}

/// Achievement data model
class Achievement {
  final String id;
  final String title;
  final String titleBm;
  final String description;
  final String descriptionBm;
  final IconData icon;
  final BadgeType badgeType;
  final AchievementCategory category;
  final int progressCurrent;
  final int progressTarget;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.titleBm,
    required this.description,
    required this.descriptionBm,
    required this.icon,
    required this.badgeType,
    required this.category,
    this.progressCurrent = 0,
    this.progressTarget = 1,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  double get progressPercentage => progressCurrent / progressTarget;
}

/// Single achievement badge widget
class AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  final bool showProgress;
  final double size;
  final VoidCallback? onTap;

  const AchievementBadge({
    super.key,
    required this.achievement,
    this.showProgress = true,
    this.size = 80,
    this.onTap,
  });

  Color _getBadgeColor() {
    if (!achievement.isUnlocked) {
      return Colors.grey;
    }

    switch (achievement.badgeType) {
      case BadgeType.bronze:
        return const Color(0xFFCD7F32);
      case BadgeType.silver:
        return const Color(0xFFC0C0C0);
      case BadgeType.gold:
        return const Color(0xFFFFD700);
      case BadgeType.platinum:
        return const Color(0xFFE5E4E2);
      case BadgeType.diamond:
        return const Color(0xFFB9F2FF);
    }
  }

  Color _getGlowColor() {
    if (!achievement.isUnlocked) {
      return Colors.transparent;
    }
    return _getBadgeColor().withValues(alpha: 0.5);
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _getBadgeColor();

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge icon with glow effect
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: achievement.isUnlocked
                  ? LinearGradient(
                      colors: [
                        badgeColor,
                        badgeColor.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: achievement.isUnlocked ? null : Colors.grey.shade300,
              boxShadow: achievement.isUnlocked
                  ? [
                      BoxShadow(
                        color: _getGlowColor(),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Progress ring for locked achievements
                if (!achievement.isUnlocked && showProgress)
                  SizedBox(
                    width: size,
                    height: size,
                    child: CircularProgressIndicator(
                      value: achievement.progressPercentage,
                      strokeWidth: 3,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),

                // Badge icon
                Icon(
                  achievement.icon,
                  size: size * 0.5,
                  color: achievement.isUnlocked
                      ? Colors.white
                      : Colors.grey.shade500,
                ),

                // Lock icon for locked badges
                if (!achievement.isUnlocked)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade600,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock,
                        size: size * 0.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Badge title
          SizedBox(
            width: size + 20,
            child: Text(
              achievement.titleBm,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: achievement.isUnlocked ? null : Colors.grey.shade500,
              ),
            ),
          ),

          // Progress text for locked
          if (!achievement.isUnlocked && showProgress)
            Text(
              '${achievement.progressCurrent}/${achievement.progressTarget}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
        ],
      ),
    );
  }
}

/// Achievement card with full details
class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback? onTap;

  const AchievementCard({
    super.key,
    required this.achievement,
    this.onTap,
  });

  Color _getBadgeColor() {
    if (!achievement.isUnlocked) return Colors.grey;

    switch (achievement.badgeType) {
      case BadgeType.bronze:
        return const Color(0xFFCD7F32);
      case BadgeType.silver:
        return const Color(0xFFC0C0C0);
      case BadgeType.gold:
        return const Color(0xFFFFD700);
      case BadgeType.platinum:
        return const Color(0xFFE5E4E2);
      case BadgeType.diamond:
        return const Color(0xFFB9F2FF);
    }
  }

  String _getBadgeTypeName() {
    switch (achievement.badgeType) {
      case BadgeType.bronze:
        return 'Gangsa';
      case BadgeType.silver:
        return 'Perak';
      case BadgeType.gold:
        return 'Emas';
      case BadgeType.platinum:
        return 'Platinum';
      case BadgeType.diamond:
        return 'Berlian';
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _getBadgeColor();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(
          color: achievement.isUnlocked
              ? badgeColor.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Badge
              AchievementBadge(
                achievement: achievement,
                size: 60,
                showProgress: false,
              ),

              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with badge type
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            achievement.titleBm,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getBadgeTypeName(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: achievement.isUnlocked
                                  ? badgeColor
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Description
                    Text(
                      achievement.descriptionBm,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Progress bar
                    if (!achievement.isUnlocked)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: achievement.progressPercentage,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor,
                              ),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${achievement.progressCurrent}/${achievement.progressTarget}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Dicapai',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (achievement.unlockedAt != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '• ${_formatDate(achievement.unlockedAt!)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mac',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ogo',
      'Sep',
      'Okt',
      'Nov',
      'Dis'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// Grid view of achievement badges
class AchievementBadgesGrid extends StatelessWidget {
  final List<Achievement> achievements;
  final int crossAxisCount;
  final Function(Achievement)? onBadgeTap;

  const AchievementBadgesGrid({
    super.key,
    required this.achievements,
    this.crossAxisCount = 4,
    this.onBadgeTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return AchievementBadge(
          achievement: achievement,
          onTap: onBadgeTap != null ? () => onBadgeTap!(achievement) : null,
        );
      },
    );
  }
}

/// Predefined achievements for the app
class AppAchievements {
  static const List<Achievement> all = [
    // Social achievements
    Achievement(
      id: 'first_like',
      title: 'First Like',
      titleBm: 'Like Pertama',
      description: 'Give your first like to a post',
      descriptionBm: 'Berikan like pertama anda',
      icon: Icons.thumb_up,
      badgeType: BadgeType.bronze,
      category: AchievementCategory.social,
      progressTarget: 1,
    ),
    Achievement(
      id: 'social_butterfly',
      title: 'Social Butterfly',
      titleBm: 'Sosial Aktif',
      description: 'Like 50 posts',
      descriptionBm: 'Like 50 pos',
      icon: Icons.favorite,
      badgeType: BadgeType.silver,
      category: AchievementCategory.social,
      progressTarget: 50,
    ),
    Achievement(
      id: 'influencer',
      title: 'Influencer',
      titleBm: 'Pengaruh',
      description: 'Get 100 likes on your posts',
      descriptionBm: 'Dapatkan 100 like pada pos anda',
      icon: Icons.star,
      badgeType: BadgeType.gold,
      category: AchievementCategory.social,
      progressTarget: 100,
    ),

    // Content achievements
    Achievement(
      id: 'first_post',
      title: 'First Post',
      titleBm: 'Pos Pertama',
      description: 'Create your first post',
      descriptionBm: 'Cipta pos pertama anda',
      icon: Icons.edit_note,
      badgeType: BadgeType.bronze,
      category: AchievementCategory.content,
      progressTarget: 1,
    ),
    Achievement(
      id: 'storyteller',
      title: 'Storyteller',
      titleBm: 'Pencerita',
      description: 'Create 10 posts',
      descriptionBm: 'Cipta 10 pos',
      icon: Icons.auto_stories,
      badgeType: BadgeType.silver,
      category: AchievementCategory.content,
      progressTarget: 10,
    ),
    Achievement(
      id: 'content_creator',
      title: 'Content Creator',
      titleBm: 'Pencipta Kandungan',
      description: 'Create 50 posts',
      descriptionBm: 'Cipta 50 pos',
      icon: Icons.movie_creation,
      badgeType: BadgeType.gold,
      category: AchievementCategory.content,
      progressTarget: 50,
    ),

    // Engagement achievements
    Achievement(
      id: 'daily_visitor',
      title: 'Daily Visitor',
      titleBm: 'Pengunjung Harian',
      description: 'Log in for 7 consecutive days',
      descriptionBm: 'Log masuk 7 hari berturut-turut',
      icon: Icons.calendar_today,
      badgeType: BadgeType.bronze,
      category: AchievementCategory.engagement,
      progressTarget: 7,
    ),
    Achievement(
      id: 'dedicated_user',
      title: 'Dedicated User',
      titleBm: 'Pengguna Setia',
      description: 'Log in for 30 consecutive days',
      descriptionBm: 'Log masuk 30 hari berturut-turut',
      icon: Icons.event_available,
      badgeType: BadgeType.gold,
      category: AchievementCategory.engagement,
      progressTarget: 30,
    ),

    // Event achievements
    Achievement(
      id: 'first_event',
      title: 'Event Joiner',
      titleBm: 'Penyertai Acara',
      description: 'Join your first event',
      descriptionBm: 'Sertai acara pertama anda',
      icon: Icons.event,
      badgeType: BadgeType.bronze,
      category: AchievementCategory.events,
      progressTarget: 1,
    ),
    Achievement(
      id: 'event_enthusiast',
      title: 'Event Enthusiast',
      titleBm: 'Pencinta Acara',
      description: 'Join 10 events',
      descriptionBm: 'Sertai 10 acara',
      icon: Icons.celebration,
      badgeType: BadgeType.gold,
      category: AchievementCategory.events,
      progressTarget: 10,
    ),

    // Special achievements
    Achievement(
      id: 'profile_complete',
      title: 'Complete Profile',
      titleBm: 'Profil Lengkap',
      description: 'Complete your profile 100%',
      descriptionBm: 'Lengkapkan profil anda 100%',
      icon: Icons.person_outline,
      badgeType: BadgeType.silver,
      category: AchievementCategory.special,
      progressTarget: 100,
    ),
    Achievement(
      id: 'early_adopter',
      title: 'Early Adopter',
      titleBm: 'Pengguna Awal',
      description: 'One of the first users',
      descriptionBm: 'Salah seorang pengguna pertama',
      icon: Icons.rocket_launch,
      badgeType: BadgeType.diamond,
      category: AchievementCategory.special,
      progressTarget: 1,
      isUnlocked: true, // Given to early users
    ),
  ];
}
