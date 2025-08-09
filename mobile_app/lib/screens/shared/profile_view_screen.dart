import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import '../../models/profile_model.dart';
import '../../models/user_model.dart';
import '../../models/search_models.dart';

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
                      // TODO: Navigate to profile setup/edit screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Go to your profile tab to complete your profile'),
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(_profile!.fullName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: true,
        actions: [
          if (!_isCurrentUser && !widget.isViewOnly)
            IconButton(
              icon: const Icon(Icons.message),
              onPressed: () {
                // TODO: Implement messaging (for future)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Messaging feature coming soon!')),
                );
              },
            ),
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
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Picture and Basic Info
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: _profile!.profileImageUrl != null &&
                        _profile!.profileImageUrl!.isNotEmpty
                    ? NetworkImage(_profile!.profileImageUrl!)
                    : null,
                backgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.1),
                child: _profile!.profileImageUrl == null ||
                        _profile!.profileImageUrl!.isEmpty
                    ? Text(
                        _profile!.fullName.isNotEmpty
                            ? _profile!.fullName[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _profile!.fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getRoleColor(_user!.role).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
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
                    if (_profile!.headline != null &&
                        _profile!.headline!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _profile!.headline!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Profile Completeness
              Flexible(
                child: Column(
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        value: completeness / 100,
                        strokeWidth: 3,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getCompletenessColor(completeness),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${completeness.round()}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(
                      'Complete',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Bio
          if (_profile!.bio != null && _profile!.bio!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                _profile!.bio!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          // Contact Info
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(Icons.email, _user!.email),
              if (_profile!.academicInfo?.department != null)
                _buildInfoChip(
                    Icons.school, _profile!.academicInfo!.department!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
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
          if (academic.program != null)
            _buildInfoRow('Program', academic.program!),
          if (academic.department != null)
            _buildInfoRow('Department', academic.department!),
          if (academic.currentSemester != null)
            _buildInfoRow('Semester', academic.currentSemester.toString()),
          if (academic.cgpa != null)
            _buildInfoRow('CGPA', academic.cgpa!.toStringAsFixed(2)),
          if (academic.studentId != null)
            _buildInfoRow('Student ID', academic.studentId!),
        ],
      ),
    );
  }

  Widget _buildSkillsSection() {
    return _buildSection(
      title: 'Skills',
      icon: Icons.build,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _profile!.skills
            .map((skill) => Chip(
                  label: Text(skill),
                  backgroundColor: Colors.blue[50],
                  labelStyle: TextStyle(color: Colors.blue[700]),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildInterestsSection() {
    return _buildSection(
      title: 'Interests',
      icon: Icons.favorite,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _profile!.interests
            .map((interest) => Chip(
                  label: Text(interest),
                  backgroundColor: Colors.green[50],
                  labelStyle: TextStyle(color: Colors.green[700]),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
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
    if (_profile!.headline != null && _profile!.headline!.isNotEmpty)
      completedFields++;
    if (_profile!.profileImageUrl != null &&
        _profile!.profileImageUrl!.isNotEmpty) completedFields++;
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
