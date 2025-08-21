import 'package:flutter/material.dart';
import '../../models/profile_model.dart';
import '../../utils/app_theme.dart';

class ModernUserCard extends StatefulWidget {
  final ProfileModel profile;
  final VoidCallback? onTap;
  final VoidCallback? onFollow;
  final VoidCallback? onMessage;
  final bool showFollowButton;
  final bool showMessageButton;
  final bool isFollowing;

  const ModernUserCard({
    super.key,
    required this.profile,
    this.onTap,
    this.onFollow,
    this.onMessage,
    this.showFollowButton = true,
    this.showMessageButton = false,
    this.isFollowing = false,
  });

  @override
  State<ModernUserCard> createState() => _ModernUserCardState();
}

class _ModernUserCardState extends State<ModernUserCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;


  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: widget.onTap,
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: Container(
              margin: const EdgeInsets.only(bottom: AppTheme.spaceMd),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: Column(
                  children: [
                    _buildUserHeader(),
                    if (widget.profile.bio != null &&
                        widget.profile.bio!.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spaceSm),
                      _buildBio(),
                    ],
                    if (widget.profile.skills.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spaceMd),
                      _buildSkills(),
                    ],
                    if (widget.showFollowButton ||
                        widget.showMessageButton) ...[
                      const SizedBox(height: AppTheme.spaceMd),
                      _buildActionButtons(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserHeader() {
    return Row(
      children: [
        _buildAvatar(),
        const SizedBox(width: AppTheme.spaceMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.profile.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                    ),
                  ),
                  _buildRoleBadge(),
                ],
              ),
              const SizedBox(height: 2),
              if (widget.profile.department != null && widget.profile.department!.isNotEmpty)
                Text(
                  widget.profile.department!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                ),
              if (widget.profile.academicInfo?.currentSemester != null)
                Text(
                  'Semester ${widget.profile.academicInfo!.currentSemester}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: _getRoleColor().withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: CircleAvatar(
        radius: 28,
        backgroundColor: _getRoleColor().withValues(alpha: 0.1),
        backgroundImage: (widget.profile.profileImageUrl?.isNotEmpty ?? false)
            ? (Uri.tryParse(widget.profile.profileImageUrl!)?.hasAbsolutePath == true ? NetworkImage(widget.profile.profileImageUrl!) : null)
            : null,
        child: (widget.profile.profileImageUrl?.isEmpty ?? true)
            ? Text(
                _getInitials(),
                style: TextStyle(
                  color: _getRoleColor(),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildRoleBadge() {
    final roleColor = _getRoleColor();
    final roleText = _getRoleText();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceXs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: roleColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
      ),
      child: Text(
        roleText,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: roleColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildBio() {
    return Text(
      widget.profile.bio!,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondaryColor,
            height: 1.4,
          ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSkills() {
    final displaySkills = widget.profile.skills.take(3).toList();
    final remainingCount = widget.profile.skills.length - 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skills',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spaceXs),
        Wrap(
          spacing: AppTheme.spaceXs,
          runSpacing: AppTheme.spaceXs,
          children: [
            ...displaySkills.map((skill) => _buildSkillChip(skill)),
            if (remainingCount > 0) _buildMoreSkillsChip(remainingCount),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
      ),
      child: Text(
        skill,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  Widget _buildMoreSkillsChip(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
      ),
      child: Text(
        '+$count more',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (widget.showFollowButton) ...[
          Expanded(
            child: _buildFollowButton(),
          ),
          if (widget.showMessageButton) const SizedBox(width: AppTheme.spaceSm),
        ],
        if (widget.showMessageButton)
          Expanded(
            child: _buildMessageButton(),
          ),
      ],
    );
  }

  Widget _buildFollowButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: widget.isFollowing ? null : AppTheme.primaryGradient,
        color: widget.isFollowing ? AppTheme.surfaceVariant : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: ElevatedButton(
        onPressed: widget.onFollow,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
        ),
        child: Text(
          widget.isFollowing ? 'Following' : 'Follow',
          style: TextStyle(
            color:
                widget.isFollowing ? AppTheme.textSecondaryColor : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageButton() {
    return OutlinedButton(
      onPressed: widget.onMessage,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppTheme.primaryColor),
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
      ),
      child: const Text(
        'Message',
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getInitials() {
    final names = widget.profile.fullName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0][0].toUpperCase();
    }
    return 'U';
  }

  Color _getRoleColor() {
    // Since ProfileModel doesn't have userRole, we'll use a default approach
    // In a real app, you'd get this from the UserModel or add it to ProfileModel
    if (widget.profile.academicInfo?.studentId != null) {
      return AppTheme.primaryColor; // Student
    } else {
      return AppTheme.successColor; // Lecturer (default)
    }
  }

  String _getRoleText() {
    // Since ProfileModel doesn't have userRole, we'll use a default approach
    // In a real app, you'd get this from the UserModel or add it to ProfileModel
    if (widget.profile.academicInfo?.studentId != null) {
      return 'Student';
    } else {
      return 'Lecturer';
    }
  }
}
