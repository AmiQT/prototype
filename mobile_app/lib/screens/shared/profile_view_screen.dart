import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import '../../models/profile_model.dart';
import '../../models/user_model.dart';
import '../../models/search_models.dart';
import '../../utils/app_theme.dart';
import '../auth/comprehensive_profile_setup_screen.dart';

class ProfileViewScreen extends StatefulWidget {
  final String userId;
  final bool isViewOnly;
  final SearchResult? searchResult; // Optional: if coming from search

  const ProfileViewScreen({
    super.key,
    required this.userId,
    this.isViewOnly = true,
    this.searchResult,
  });

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  ProfileModel? _profile;
  UserModel? _user;
  bool _isLoading = true;
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      debugPrint(
          'ProfileViewScreen: Loading profile data for userId: ${widget.userId}');

      final authService = Provider.of<AuthService>(context, listen: false);
      final profileService =
          Provider.of<ProfileService>(context, listen: false);

      // Check if this is the current user's profile
      _isCurrentUser = authService.currentUserId == widget.userId;
      debugPrint('ProfileViewScreen: Is current user: $_isCurrentUser');

      // Load user data first
      UserModel? user;
      if (widget.searchResult != null) {
        user = widget.searchResult!.user;
        debugPrint(
            'ProfileViewScreen: Using user from search result: ${user.name}');
      } else {
        debugPrint('ProfileViewScreen: Fetching user data from auth service');
        user = await authService.getUserData(widget.userId);
      }

      debugPrint('ProfileViewScreen: User loaded: ${user?.name ?? 'null'}');

      // Load profile data
      ProfileModel? profile;
      try {
        debugPrint('ProfileViewScreen: Attempting to load profile');
        profile = await profileService.getProfileByUserId(widget.userId);
        debugPrint(
            'ProfileViewScreen: Profile loaded: ${profile?.fullName ?? 'null'}');

        // Additional debugging - check if profile from search result exists
        if (widget.searchResult?.profile != null) {
          debugPrint(
              'ProfileViewScreen: Search result has profile: ${widget.searchResult!.profile!.fullName}');
          debugPrint(
              'ProfileViewScreen: Search profile userId: ${widget.searchResult!.profile!.userId}');
          debugPrint('ProfileViewScreen: Current userId: ${widget.userId}');

          // If we have a profile from search but not from service, there might be a sync issue
          if (profile == null) {
            debugPrint(
                'ProfileViewScreen: WARNING - Search has profile but service doesn\'t find it!');
            debugPrint(
                'ProfileViewScreen: Using profile from search result as fallback');
            profile = widget.searchResult!.profile;
          }
        }
      } catch (e) {
        debugPrint('ProfileViewScreen: Error loading profile: $e');
        // Profile might not exist yet, that's okay
        profile = null;

        // Check if we can use profile from search result as fallback
        if (widget.searchResult?.profile != null) {
          debugPrint(
              'ProfileViewScreen: Using profile from search result as fallback after error');
          profile = widget.searchResult!.profile;
        }
      }

      if (mounted) {
        setState(() {
          _profile = profile;
          _user = user;
          _isLoading = false;
        });
        debugPrint(
            'ProfileViewScreen: State updated - Profile: ${_profile != null}, User: ${_user != null}');
      }
    } catch (e) {
      debugPrint('ProfileViewScreen: Error in _loadProfileData: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0.5,
        ),
        body: const Center(
          child: Text(
            'User not found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    // If profile is null but user exists, show basic user info with message
    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_user!.name),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0.5,
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Text(
                    _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _user!.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getRoleColor(_user!.role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getRoleDisplayName(_user!.role),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _getRoleColor(_user!.role),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _user!.email,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),
                const Icon(
                  Icons.info_outline,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Profile not set up yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isCurrentUser
                      ? 'Complete your profile to showcase your skills and experience'
                      : 'This user hasn\'t completed their profile yet',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_isCurrentUser) ...[
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to comprehensive profile setup screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ComprehensiveProfileSetupScreen(),
                        ),
                      );
                    },
                    child: const Text('Complete Profile'),
                  ),
                  const SizedBox(height: 16),
                  // Debug button to check database directly
                  OutlinedButton(
                    onPressed: () async {
                      final profileService =
                          Provider.of<ProfileService>(context, listen: false);

                      try {
                        // Try to get profile by direct document ID
                        final directProfile = await profileService
                            .getProfileById('profile_${widget.userId}');
                        debugPrint(
                            'DEBUG: Direct profile lookup: ${directProfile?.fullName ?? 'null'}');

                        // Try to get all profiles and find this user
                        final allProfiles =
                            await profileService.getAllProfiles();
                        final userProfile = allProfiles
                            .where((p) => p.userId == widget.userId)
                            .toList();
                        debugPrint(
                            'DEBUG: Found ${userProfile.length} profiles for this user');
                        debugPrint(
                            'DEBUG: Total profiles in database: ${allProfiles.length}');

                        if (userProfile.isNotEmpty) {
                          debugPrint(
                              'DEBUG: Profile found in all profiles: ${userProfile.first.fullName}');
                          debugPrint(
                              'DEBUG: Profile ID: ${userProfile.first.id}');
                          debugPrint(
                              'DEBUG: Profile userId: ${userProfile.first.userId}');
                        }

                        // Show all user IDs in database for comparison
                        debugPrint('DEBUG: All user IDs in database:');
                        for (final profile in allProfiles) {
                          debugPrint(
                              '  - ${profile.fullName}: ${profile.userId}');
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Debug: Direct=${directProfile != null}, All=${userProfile.length}, Total=${allProfiles.length}'),
                          ),
                        );
                      } catch (e) {
                        debugPrint('DEBUG: Error checking profiles: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Debug error: $e')),
                        );
                      }
                    },
                    child: const Text('Debug: Check Database'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          _profile!.fullName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (!_isCurrentUser && !widget.isViewOnly) ...[
            IconButton(
              icon: const Icon(
                Icons.message_rounded,
                color: AppTheme.primaryColor,
              ),
              onPressed: () {
                // TODO: Implement messaging (for future)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Messaging feature coming soon!')),
                );
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: AppTheme.textSecondaryColor,
              ),
              onPressed: () {
                // TODO: Show more options menu
              },
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Profile Header
            _buildProfileHeader(),

            const SizedBox(height: 24),

            // Profile Sections
            _buildProfileSections(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final completeness = _calculateProfileCompleteness();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Cover Photo Area (LinkedIn-style)
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.8),
                  AppTheme.primaryColor.withValues(alpha: 0.6),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusLg),
                topRight: Radius.circular(AppTheme.radiusLg),
              ),
            ),
          ),

          // Profile Content
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            child: Column(
              children: [
                // Profile Picture positioned over cover
                Transform.translate(
                  offset: const Offset(0, -60),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.surfaceColor,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: _profile!.profileImageUrl != null &&
                                  _profile!.profileImageUrl!.isNotEmpty
                              ? NetworkImage(_profile!.profileImageUrl!)
                              : null,
                          backgroundColor:
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                          child: _profile!.profileImageUrl == null ||
                                  _profile!.profileImageUrl!.isEmpty
                              ? Text(
                                  _profile!.fullName.isNotEmpty
                                      ? _profile!.fullName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                )
                              : null,
                        ),
                      ),

                      const SizedBox(height: AppTheme.spaceMd),

                      // Name and Title
                      Text(
                        _profile!.fullName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppTheme.spaceXs),

                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceMd,
                          vertical: AppTheme.spaceXs,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _getRoleColor(_user!.role).withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                          border: Border.all(
                            color: _getRoleColor(_user!.role)
                                .withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getRoleDisplayName(_user!.role),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getRoleColor(_user!.role),
                          ),
                        ),
                      ),

                      // Headline
                      if (_profile!.headline != null &&
                          _profile!.headline!.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.spaceSm),
                        Text(
                          _profile!.headline!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Profile Stats and Completeness
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Column(
                    children: [
                      // Profile Completeness Card
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spaceMd),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                value: completeness / 100,
                                strokeWidth: 3,
                                backgroundColor: AppTheme.textSecondaryColor
                                    .withValues(alpha: 0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getCompletenessColor(completeness),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spaceSm),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${completeness.round()}% Complete',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                                const Text(
                                  'Profile Strength',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Quick Info Chips
                      const SizedBox(height: AppTheme.spaceMd),
                      Wrap(
                        spacing: AppTheme.spaceXs,
                        runSpacing: AppTheme.spaceXs,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildInfoChip(Icons.email_rounded, _user!.email),
                          if (_profile!.academicInfo?.department != null)
                            _buildInfoChip(Icons.school_rounded,
                                _profile!.academicInfo!.department),
                          if (_profile!.skills.isNotEmpty)
                            _buildInfoChip(Icons.star_rounded,
                                '${_profile!.skills.length} Skills'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSm,
        vertical: AppTheme.spaceXs,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: AppTheme.spaceXs),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSections() {
    return Column(
      children: [
        // Academic Information
        if (_profile!.academicInfo != null) _buildAcademicSection(),

        // Skills
        if (_profile!.skills.isNotEmpty) _buildSkillsSection(),

        // Interests
        if (_profile!.interests.isNotEmpty) _buildInterestsSection(),

        // Experience
        if (_profile!.experiences.isNotEmpty) _buildExperienceSection(),

        // Projects
        if (_profile!.projects.isNotEmpty) _buildProjectsSection(),

        // Achievements
        if (_profile!.achievements.isNotEmpty) _buildAchievementsSection(),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildAcademicSection() {
    final academic = _profile!.academicInfo!;
    return _buildSection(
      title: 'Academic Information',
      icon: Icons.school,
      child: Column(
        children: [
          _buildInfoRow('Program', academic.program!),
          _buildInfoRow('Department', academic.department!),
          _buildInfoRow('Semester', academic.currentSemester.toString()),
          if (academic.cgpa != null)
            _buildInfoRow('CGPA', academic.cgpa!.toStringAsFixed(2)),
          _buildInfoRow('Student ID', academic.studentId!),
        ],
      ),
    );
  }

  Widget _buildSkillsSection() {
    return _buildSection(
      title: 'Skills',
      icon: Icons.psychology_rounded,
      child: Wrap(
        spacing: AppTheme.spaceXs,
        runSpacing: AppTheme.spaceXs,
        children: _profile!.skills
            .map((skill) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceSm,
                    vertical: AppTheme.spaceXs,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withValues(alpha: 0.1),
                        AppTheme.primaryColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: AppTheme.spaceXs),
                      Text(
                        skill,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildInterestsSection() {
    return _buildSection(
      title: 'Interests',
      icon: Icons.favorite_rounded,
      child: Wrap(
        spacing: AppTheme.spaceXs,
        runSpacing: AppTheme.spaceXs,
        children: _profile!.interests
            .map((interest) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceSm,
                    vertical: AppTheme.spaceXs,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withValues(alpha: 0.1),
                        Colors.green.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        size: 14,
                        color: Colors.green,
                      ),
                      const SizedBox(width: AppTheme.spaceXs),
                      Text(
                        interest,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildExperienceSection() {
    return _buildSection(
      title: 'Experience',
      icon: Icons.work,
      child: Column(
        children: _profile!.experiences
            .map((exp) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exp.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (exp.company.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          exp.company,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                      if (exp.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          exp.description,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildProjectsSection() {
    return _buildSection(
      title: 'Projects',
      icon: Icons.code,
      child: Column(
        children: _profile!.projects
            .map((project) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (project.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          project.description,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                      if (project.technologies.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: project.technologies
                              .map((tech) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      tech,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildAchievementsSection() {
    return _buildSection(
      title: 'Achievements',
      icon: Icons.emoji_events,
      child: Column(
        children: _profile!.achievements
            .map((achievement) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events, color: Colors.amber[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              achievement.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            if (achievement.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                achievement.description,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMd,
        vertical: AppTheme.spaceXs,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusLg),
                topRight: Radius.circular(AppTheme.radiusLg),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spaceXs),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Section Content
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateProfileCompleteness() {
    int totalFields = 10;
    int completedFields = 0;

    if (_profile!.fullName.isNotEmpty) completedFields++;
    if (_profile!.bio != null && _profile!.bio!.isNotEmpty) completedFields++;
    if (_profile!.headline != null && _profile!.headline!.isNotEmpty) {
      completedFields++;
    }
    if (_profile!.profileImageUrl != null &&
        _profile!.profileImageUrl!.isNotEmpty) {
      completedFields++;
    }
    if (_profile!.skills.isNotEmpty) completedFields++;
    if (_profile!.interests.isNotEmpty) completedFields++;
    if (_profile!.experiences.isNotEmpty) completedFields++;
    if (_profile!.projects.isNotEmpty) completedFields++;
    if (_profile!.achievements.isNotEmpty) completedFields++;
    if (_profile!.academicInfo != null) completedFields++;

    return (completedFields / totalFields) * 100;
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.student:
        return Colors.blue;
      case UserRole.lecturer:
        return Colors.green;
      case UserRole.admin:
        return Colors.red;
    }
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'Student';
      case UserRole.lecturer:
        return 'Lecturer';
      case UserRole.admin:
        return 'Admin';
    }
  }

  Color _getCompletenessColor(double completeness) {
    if (completeness >= 80) return Colors.green;
    if (completeness >= 50) return Colors.orange;
    return Colors.red;
  }
}
