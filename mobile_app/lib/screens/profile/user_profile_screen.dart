import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/profile_model.dart';
import '../../models/showcase_models.dart';
import '../../services/profile_service.dart';
import '../../services/showcase_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/showcase/post_card_widget.dart';
import '../student/showcase/post_detail_screen.dart';

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

  Widget _buildContent() {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
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

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProfileHeader(),
            ),
            actions: [
              if (_currentUser != null && _user!.uid != _currentUser!.uid)
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: _showProfileMenu,
                ),
            ],
          ),
          SliverPersistentHeader(
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).primaryColor,
                tabs: const [
                  Tab(text: 'Posts'),
                  Tab(text: 'About'),
                  Tab(text: 'Skills'),
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
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3B82F6),
            const Color(0xFF1D4ED8),
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
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
        child: Column(
          children: [
            // Profile Image with modern styling
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 56,
                  backgroundImage: _profile?.profileImageUrl != null
                      ? NetworkImage(_profile!.profileImageUrl!)
                      : null,
                  backgroundColor:
                      const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  child: _profile?.profileImageUrl == null
                      ? Text(
                          _user!.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3B82F6),
                          ),
                        )
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Name and role with modern styling
            Text(
              _user!.name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                '${_user!.role.toString().split('.').last.toUpperCase()} • ${_user!.department}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            if (_profile?.bio != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _profile!.bio!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Modern Stats Row
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildModernStatItem('Posts', _userPosts.length.toString(),
                      Icons.article_rounded),
                  _buildModernStatItem('Department', _user!.department ?? 'N/A',
                      Icons.business_rounded),
                  _buildModernStatItem(
                      'Semester',
                      _profile?.semester?.toString() ?? 'N/A',
                      Icons.school_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildModernStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
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
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPostsTab() {
    if (_isLoadingPosts) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_userPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.post_add,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _user!.uid == _currentUser?.uid
                  ? 'You haven\'t posted anything yet'
                  : '${_user!.name} hasn\'t posted anything yet',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        final post = _userPosts[index];
        return PostCardWidget(
          post: post,
          currentUser: _currentUser,
          onLike: _handleLike,
          onComment: _handleComment,
          onShare: _handleShare,
          onUserTap: (_) {}, // Already on user profile
          onPostTap: _handlePostTap,
        );
      },
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_profile?.bio != null) ...[
            const Text(
              'Bio',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _profile!.bio!,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
          ],
          const Text(
            'Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoItem(Icons.school, 'Role',
              _user!.role.toString().split('.').last.toUpperCase()),
          _buildInfoItem(Icons.business, 'Department',
              _user!.department ?? 'Not specified'),
          _buildInfoItem(Icons.email, 'Email', _user!.email),
          if (_profile?.academicInfo?.program != null)
            _buildInfoItem(
                Icons.grade, 'Program', _profile!.academicInfo!.program),
          if (_profile?.phoneNumber != null)
            _buildInfoItem(Icons.phone, 'Phone', _profile!.phoneNumber!),
          if (_profile?.address != null)
            _buildInfoItem(Icons.location_on, 'Address', _profile!.address!),
          if (_profile?.achievements != null &&
              _profile!.achievements!.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Achievements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._profile!.achievements!.map((achievement) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber),
                    const SizedBox(width: 12),
                    Expanded(child: Text(achievement.title)),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSkillsTab() {
    if (_profile?.skills == null || _profile!.skills!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No skills listed yet',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Skills & Expertise',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _profile!.skills!.map((skill) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  skill,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
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

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Follow'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Follow feature coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Message'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Messaging feature coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report feature coming soon!')),
                );
              },
            ),
          ],
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
