import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/profile_model.dart';
import '../../models/showcase_models.dart';
import '../../models/achievement_model.dart';
import '../../models/experience_model.dart';
import '../../models/project_model.dart';
import '../../services/profile_service.dart';
import '../../services/showcase_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/showcase/post_card_widget.dart';
import '../student/showcase/post_detail_screen.dart';
import '../../utils/app_theme.dart';
import 'package:flutter/services.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final UserModel? initialUser;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.initialUser,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  final ProfileService _profileService = ProfileService();
  final ShowcaseService _showcaseService = ShowcaseService();
  final AuthService _authService = AuthService();
  late TabController _tabController;

  UserModel? _user;
  ProfileModel? _profile;
  List<ShowcasePostModel> _userPosts = [];
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isLoadingPosts = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCurrentUser();
    _loadUserProfile();
    _loadUserPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadCurrentUser() {
    final authService = Provider.of<AuthService>(context, listen: false);
    _currentUser = authService.currentUser;
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.initialUser != null) {
        _user = widget.initialUser;
      } else {
        _user = await _authService.getUserData(widget.userId);
      }

      if (_user != null) {
        _profile = await _profileService.getProfileByUserId(widget.userId);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserPosts() async {
    setState(() {
      _isLoadingPosts = true;
    });

    try {
      final posts = await _showcaseService
          .getShowcasePostsStream(
            userId: widget.userId,
            limit: 20,
          )
          .first;

      setState(() {
        _userPosts = posts;
        _isLoadingPosts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPosts = false;
      });
      debugPrint('Error loading user posts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading profile...'),
        ],
      ),
    );
  }

  // Enhanced error state with better UX
  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _error ??
                'Unable to load profile. Please check your connection and try again.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _error = null;
                    _isLoading = true;
                  });
                  _loadUserProfile();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        body: _buildErrorState(),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        body: const Center(
          child: Text('User not found'),
        ),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280, // Reduced from 300 to 280
              floating: false,
              pinned: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildEnhancedProfileHeader(),
              ),
              actions: const [
                // Moved actions to floating buttons for better UX
                SizedBox(width: 16),
              ],
            ),
            SliverPersistentHeader(
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).primaryColor,
                  tabs: [
                    Semantics(
                      label: 'Posts tab',
                      child: const Tab(text: 'Posts'),
                    ),
                    Semantics(
                      label: 'About tab',
                      child: const Tab(text: 'About'),
                    ),
                    Semantics(
                      label: 'Skills tab',
                      child: const Tab(text: 'Skills'),
                    ),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostsTab(),
            _buildAboutTab(),
            _buildSkillsTab(),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionMenu(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Enhanced Profile Header with improved design
  Widget _buildEnhancedProfileHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3B82F6),
            Color(0xFF1D4ED8),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: 0.1),
            ],
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          AppTheme.getResponsiveSpacing(context,
              mobile: 20, tablet: 24, desktop: 32),
          60,
          AppTheme.getResponsiveSpacing(context,
              mobile: 20, tablet: 24, desktop: 32),
          AppTheme.getResponsiveSpacing(context,
              mobile: 20, tablet: 24, desktop: 28),
        ),
        child: Column(
          children: [
            // Profile Image with enhanced styling
            _buildEnhancedProfileImage(),

            const SizedBox(height: 16), // Reduced spacing

            // Name and role with improved layout
            _buildNameAndRole(),

            // Profile completion indicator
            if (_currentUser != null && _user!.uid == _currentUser!.uid)
              _buildProfileCompletionIndicator(),

            // Bio section with better typography
            if (_profile?.bio != null) ...[
              const SizedBox(height: 12),
              _buildBioSection(),
            ],

            const SizedBox(height: 20), // Reduced spacing

            // Enhanced Stats Row
            _buildEnhancedStatsRow(),
          ],
        ),
      ),
    );
  }

  // Enhanced Profile Image with better styling and accessibility
  Widget _buildEnhancedProfileImage() {
    return Semantics(
      label: 'Profile picture of ${_user?.name ?? 'user'}',
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            CircleAvatar(
              radius: 55, // Slightly smaller for better proportions
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 52,
                backgroundImage: _profile?.profileImageUrl != null
                    ? NetworkImage(_profile!.profileImageUrl!)
                    : null,
                backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                child: _profile?.profileImageUrl == null
                    ? Text(
                        _user!.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3B82F6),
                        ),
                      )
                    : null,
              ),
            ),
            // Verified badge for completed profiles
            if (_profile?.isProfileComplete == true)
              Positioned(
                bottom: 4,
                right: 4,
                child: Semantics(
                  label: 'Verified profile',
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Name and Role section with improved typography
  Widget _buildNameAndRole() {
    return Column(
      children: [
        Text(
          _user!.name,
          style: const TextStyle(
            fontSize: 26, // Slightly smaller
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _user!.role == UserRole.student ? Icons.school : Icons.work,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '${_user!.role.toString().split('.').last.toUpperCase()} • ${_user!.department ?? 'N/A'}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Profile Completion Indicator
  Widget _buildProfileCompletionIndicator() {
    final completionPercentage = _calculateProfileCompletion();
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            completionPercentage >= 80 ? Icons.verified : Icons.info_outline,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Profile ${completionPercentage.toInt()}% Complete',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Bio Section with better typography
  Widget _buildBioSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        _profile!.bio!,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.white,
          height: 1.4,
          fontWeight: FontWeight.w400,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // Enhanced Stats Row with better design
  Widget _buildEnhancedStatsRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildEnhancedStatItem(
              'Posts', _userPosts.length.toString(), Icons.article_rounded),
          _buildStatDivider(),
          _buildEnhancedStatItem(
              'Department',
              _user!.department?.split(' ').first ?? 'N/A',
              Icons.business_rounded),
          _buildStatDivider(),
          _buildEnhancedStatItem(
              'Semester',
              _profile?.academicInfo?.currentSemester.toString() ?? 'N/A',
              Icons.school_rounded),
        ],
      ),
    );
  }

  // Stat divider for better visual separation
  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }

  // Enhanced stat item with better design
  Widget _buildEnhancedStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Calculate profile completion percentage
  double _calculateProfileCompletion() {
    if (_profile == null) return 0.0;

    int completedFields = 0;
    int totalFields = 8; // Total number of profile fields to check

    // Check basic info
    if (_profile!.bio != null && _profile!.bio!.isNotEmpty) completedFields++;
    if (_profile!.phoneNumber != null && _profile!.phoneNumber!.isNotEmpty) {
      completedFields++;
    }
    if (_profile!.address != null && _profile!.address!.isNotEmpty) {
      completedFields++;
    }
    if (_profile!.profileImageUrl != null &&
        _profile!.profileImageUrl!.isNotEmpty) {
      completedFields++;
    }

    // Check academic info
    if (_profile!.academicInfo != null) completedFields++;

    // Check skills and interests
    if (_profile!.skills.isNotEmpty) completedFields++;
    if (_profile!.interests.isNotEmpty) completedFields++;

    // Check experiences/projects/achievements
    if (_profile!.experiences.isNotEmpty ||
        _profile!.projects.isNotEmpty ||
        _profile!.achievements.isNotEmpty) {
      completedFields++;
    }

    return (completedFields / totalFields) * 100;
  }

  // Floating Action Menu for profile actions with proper touch targets
  Widget _buildFloatingActionMenu() {
    if (_currentUser == null) return const SizedBox.shrink();

    final isOwnProfile = _user!.uid == _currentUser!.uid;
    final isMobile = AppTheme.isMobile(context);

    if (isOwnProfile) {
      // Show edit button for own profile with proper touch target
      return SizedBox(
        width: AppTheme.touchTargetComfortable,
        height: AppTheme.touchTargetComfortable,
        child: FloatingActionButton(
          onPressed: () {
            _showEditProfileOptions();
          },
          backgroundColor: Theme.of(context).primaryColor,
          elevation: AppTheme.elevationMd,
          tooltip: 'Edit profile',
          child: Semantics(
            label: 'Edit profile button',
            child: const Icon(Icons.edit, color: Colors.white, size: 24),
          ),
        ),
      );
    } else {
      // Show action menu for other profiles with responsive sizing
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionButton(
            heroTag: "message",
            icon: Icons.message,
            color: Colors.green,
            onPressed: () => _showMessageOptions(),
            size: isMobile
                ? AppTheme.touchTargetMin
                : AppTheme.touchTargetComfortable,
          ),
          const SizedBox(height: AppTheme.spaceSm),
          _buildActionButton(
            heroTag: "follow",
            icon: Icons.person_add,
            color: Theme.of(context).primaryColor,
            onPressed: () => _showFollowOptions(),
            size: isMobile
                ? AppTheme.touchTargetMin
                : AppTheme.touchTargetComfortable,
          ),
          const SizedBox(height: AppTheme.spaceSm),
          _buildActionButton(
            heroTag: "share",
            icon: Icons.share,
            color: Colors.orange,
            onPressed: () => _showShareOptions(),
            size: isMobile
                ? AppTheme.touchTargetMin
                : AppTheme.touchTargetComfortable,
          ),
        ],
      );
    }
  }

  // Helper method for action buttons with proper touch targets
  Widget _buildActionButton({
    required String heroTag,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required double size,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: FloatingActionButton(
        heroTag: heroTag,
        onPressed: onPressed,
        backgroundColor: color,
        elevation: AppTheme.elevationSm,
        mini: size < AppTheme.touchTargetComfortable,
        tooltip: _getActionTooltip(heroTag),
        child: Semantics(
          label: _getActionLabel(heroTag),
          child: Icon(
            icon,
            color: Colors.white,
            size: size < AppTheme.touchTargetComfortable ? 18 : 22,
          ),
        ),
      ),
    );
  }

  // Accessibility helper methods
  String _getActionTooltip(String heroTag) {
    switch (heroTag) {
      case 'message':
        return 'Send message to ${_user?.name ?? 'user'}';
      case 'follow':
        return 'Follow ${_user?.name ?? 'user'}';
      case 'share':
        return 'Share ${_user?.name ?? 'user'}\'s profile';
      default:
        return 'Action button';
    }
  }

  String _getActionLabel(String heroTag) {
    switch (heroTag) {
      case 'message':
        return 'Message ${_user?.name ?? 'user'} button';
      case 'follow':
        return 'Follow ${_user?.name ?? 'user'} button';
      case 'share':
        return 'Share profile button';
      default:
        return 'Action button';
    }
  }

  // Action handlers with proper feedback and haptic response
  void _showEditProfileOptions() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('Edit profile feature coming soon!')),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showMessageOptions() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.message_outlined, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('Message feature coming soon!')),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showFollowOptions() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.person_add_outlined, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('Follow feature coming soon!')),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showShareOptions() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.share_outlined, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('Share profile feature coming soon!')),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.orange,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildPostsTab() {
    if (_isLoadingPosts) {
      return _buildPostsLoadingState();
    }

    if (_userPosts.isEmpty) {
      return _buildPostsEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshPosts,
      child: ListView.builder(
        padding: EdgeInsets.all(
          AppTheme.getResponsiveSpacing(context,
              mobile: 16, tablet: 20, desktop: 24),
        ),
        itemCount: _userPosts.length,
        itemBuilder: (context, index) {
          final post = _userPosts[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: PostCardWidget(
              post: post,
              currentUser: _currentUser,
              onLike: _handleLike,
              onComment: _handleComment,
              onShare: _handleShare,
              onUserTap: (_) {}, // Already on user profile
              onPostTap: _handlePostTap,
            ),
          );
        },
      ),
    );
  }

  // Enhanced loading state for posts
  Widget _buildPostsLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Skeleton loading cards
          ...List.generate(3, (index) => _buildPostSkeletonCard()),
        ],
      ),
    );
  }

  // Skeleton card for loading state
  Widget _buildPostSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Content skeleton
          Container(
            width: double.infinity,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 200,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),
          // Actions skeleton
          Row(
            children: [
              Container(
                width: 60,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 60,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Enhanced empty state for posts
  Widget _buildPostsEmptyState() {
    final isOwnProfile = _user!.uid == _currentUser?.uid;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.post_add_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isOwnProfile ? 'No Posts Yet' : 'No Posts from ${_user!.name}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isOwnProfile
                ? 'Share your achievements, projects, and experiences with the community.'
                : 'This user hasn\'t shared any posts yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              height: 1.4,
            ),
          ),
          if (isOwnProfile) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to create post
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Create post feature coming soon!')),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Post'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Refresh posts method
  Future<void> _refreshPosts() async {
    await _loadUserPosts();
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        AppTheme.getResponsiveSpacing(context,
            mobile: 16, tablet: 20, desktop: 24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bio Card
          if (_profile?.bio != null) ...[
            _buildModernInfoCard(
              title: 'About',
              icon: Icons.person_outline,
              child: Text(
                _profile!.bio!,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Basic Information Card
          _buildModernInfoCard(
            title: 'Basic Information',
            icon: Icons.info_outline,
            child: Column(
              children: [
                _buildModernInfoItem(
                  Icons.school_rounded,
                  'Role',
                  _user!.role.toString().split('.').last.toUpperCase(),
                ),
                _buildModernInfoItem(
                  Icons.business_rounded,
                  'Department',
                  _user!.department ?? 'Not specified',
                ),
                _buildModernInfoItem(
                  Icons.email_rounded,
                  'Email',
                  _user!.email,
                ),
                if (_profile?.phoneNumber != null)
                  _buildModernInfoItem(
                    Icons.phone_rounded,
                    'Phone',
                    _profile!.phoneNumber!,
                  ),
                if (_profile?.address != null)
                  _buildModernInfoItem(
                    Icons.location_on_rounded,
                    'Address',
                    _profile!.address!,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Academic Information Card
          if (_profile?.academicInfo != null) ...[
            _buildModernInfoCard(
              title: 'Academic Information',
              icon: Icons.school,
              child: Column(
                children: [
                  _buildModernInfoItem(
                    Icons.badge_rounded,
                    'Student ID',
                    _profile!.academicInfo!.studentId,
                  ),
                  _buildModernInfoItem(
                    Icons.book_rounded,
                    'Program',
                    _profile!.academicInfo!.program,
                  ),
                  _buildModernInfoItem(
                    Icons.apartment_rounded,
                    'Faculty',
                    _profile!.academicInfo!.faculty,
                  ),
                  _buildModernInfoItem(
                    Icons.timeline_rounded,
                    'Current Semester',
                    'Semester ${_profile!.academicInfo!.currentSemester}',
                  ),
                  if (_profile!.academicInfo!.cgpa != null)
                    _buildModernInfoItem(
                      Icons.grade_rounded,
                      'CGPA',
                      _profile!.academicInfo!.cgpa!.toStringAsFixed(2),
                    ),
                  if (_profile!.academicInfo!.specialization != null)
                    _buildModernInfoItem(
                      Icons.star_rounded,
                      'Specialization',
                      _profile!.academicInfo!.specialization!,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Achievements Card
          if (_profile?.achievements != null &&
              _profile!.achievements.isNotEmpty) ...[
            _buildModernInfoCard(
              title: 'Achievements',
              icon: Icons.emoji_events,
              child: Column(
                children: _profile!.achievements.map((achievement) {
                  return _buildAchievementItem(achievement);
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Experiences Card
          if (_profile?.experiences != null &&
              _profile!.experiences.isNotEmpty) ...[
            _buildModernInfoCard(
              title: 'Experience',
              icon: Icons.work_outline,
              child: Column(
                children: _profile!.experiences.map((experience) {
                  return _buildExperienceItem(experience);
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Projects Card
          if (_profile?.projects != null && _profile!.projects.isNotEmpty) ...[
            _buildModernInfoCard(
              title: 'Projects',
              icon: Icons.code,
              child: Column(
                children: _profile!.projects.map((project) {
                  return _buildProjectItem(project);
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Modern Info Card with consistent styling
  Widget _buildModernInfoCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  // Modern Info Item with better styling
  Widget _buildModernInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Achievement Item with modern design
  Widget _buildAchievementItem(AchievementModel achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.amber,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (achievement.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (achievement.organization != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    achievement.organization!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.amber,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (achievement.isVerified)
            const Icon(
              Icons.verified,
              color: Colors.green,
              size: 20,
            ),
        ],
      ),
    );
  }

  // Experience Item with modern design
  Widget _buildExperienceItem(ExperienceModel experience) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.work,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      experience.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      experience.company,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (experience.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              experience.description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Project Item with modern design
  Widget _buildProjectItem(ProjectModel project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.code,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (project.category != null)
                      Text(
                        project.category!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              if (project.isOngoing)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Ongoing',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          if (project.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              project.description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.4,
              ),
            ),
          ],
          if (project.technologies.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: project.technologies.map((tech) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tech,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkillsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        AppTheme.getResponsiveSpacing(context,
            mobile: 16, tablet: 20, desktop: 24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skills Card
          if (_profile?.skills != null && _profile!.skills.isNotEmpty) ...[
            _buildModernInfoCard(
              title: 'Skills & Expertise',
              icon: Icons.psychology,
              child: _buildSkillsGrid(),
            ),
            const SizedBox(height: 16),
          ],

          // Interests Card
          if (_profile?.interests != null &&
              _profile!.interests.isNotEmpty) ...[
            _buildModernInfoCard(
              title: 'Interests',
              icon: Icons.favorite_outline,
              child: _buildInterestsGrid(),
            ),
            const SizedBox(height: 16),
          ],

          // Empty state
          if ((_profile?.skills == null || _profile!.skills.isEmpty) &&
              (_profile?.interests == null || _profile!.interests.isEmpty))
            _buildSkillsEmptyState(),
        ],
      ),
    );
  }

  // Skills Grid with modern design
  Widget _buildSkillsGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _profile!.skills.map((skill) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor.withValues(alpha: 0.1),
                Theme.of(context).primaryColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                skill,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Interests Grid with modern design
  Widget _buildInterestsGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _profile!.interests.map((interest) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.withValues(alpha: 0.1),
                Colors.orange.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.orange.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite,
                size: 16,
                color: Colors.orange,
              ),
              const SizedBox(width: 6),
              Text(
                interest,
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Empty state for skills tab
  Widget _buildSkillsEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Skills or Interests Listed',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Skills and interests help others understand your expertise and passions.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Event handlers
  Future<void> _handleLike(ShowcasePostModel post) async {
    if (_currentUser == null) return;

    try {
      await _showcaseService.toggleLike(post.id, _currentUser!.uid);
      // Update local post list
      setState(() {
        final index = _userPosts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          final updatedPost = post.copyWith(
            likes: post.isLikedBy(_currentUser!.uid)
                ? post.likes.where((id) => id != _currentUser!.uid).toList()
                : [...post.likes, _currentUser!.uid],
          );
          _userPosts[index] = updatedPost;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update like: $e')),
        );
      }
    }
  }

  void _handleComment(ShowcasePostModel post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(
          postId: post.id,
          initialPost: post,
        ),
      ),
    );
  }

  void _handleShare(ShowcasePostModel post) {
    // Show share dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }

  void _handlePostTap(ShowcasePostModel post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(
          postId: post.id,
          initialPost: post,
        ),
      ),
    );
  }
}

// Custom SliverPersistentHeaderDelegate for TabBar
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
