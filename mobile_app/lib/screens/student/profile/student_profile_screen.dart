import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../services/profile_service.dart';
import '../../../models/profile_model.dart';
import '../../../models/achievement_model.dart';
import '../../../models/experience_model.dart';
import '../../../models/project_model.dart';
import 'package:share_plus/share_plus.dart';
import '../achievements/achievements_screen.dart';
import '../../settings/settings_screen.dart';
import '../../debug/sample_data_debug_screen.dart';
import '../../debug/migrate_profile_documents_screen.dart';
import '../../auth/comprehensive_profile_setup_screen.dart';
import '../../profile/comprehensive_edit_profile_screen.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  ProfileModel? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  ImageProvider _getProfileImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      // Return default asset image
      return const AssetImage('assets/images/default_profile.png');
    } else if (imageUrl.startsWith('data:image')) {
      // Handle base64 images
      final base64String = imageUrl.split(',')[1];
      final bytes = base64Decode(base64String);
      return MemoryImage(bytes);
    } else if (imageUrl.startsWith('http')) {
      // Handle network images
      return NetworkImage(imageUrl);
    } else if (imageUrl.startsWith('/') || imageUrl.contains('cache')) {
      // Handle local file images
      return FileImage(File(imageUrl));
    } else {
      // Default fallback for invalid URLs
      return const AssetImage('assets/images/default_profile.png');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh profile when returning to this screen
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final profileService =
          Provider.of<ProfileService>(context, listen: false);

      final userId = authService.currentUserId;
      if (userId != null) {
        final profile = await profileService.getProfileByUserId(userId);
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _migrateProfile() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUserId;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user authenticated')),
        );
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Migrating profile...'),
            ],
          ),
        ),
      );

      // Search for profiles with this userId in the data (old structure)
      final oldProfilesQuery = await FirebaseFirestore.instance
          .collection('profiles')
          .where('userId', isEqualTo: userId)
          .get();

      if (oldProfilesQuery.docs.isEmpty) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No profile found to migrate')),
        );
        return;
      }

      // Migrate the first profile found
      final doc = oldProfilesQuery.docs.first;
      final data = doc.data();
      final oldDocId = doc.id;

      // Check if target document already exists
      final targetDoc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(userId)
          .get();

      if (targetDoc.exists) {
        // Delete old document only
        await FirebaseFirestore.instance
            .collection('profiles')
            .doc(oldDocId)
            .delete();
      } else {
        // Create new document with userId as document ID
        await FirebaseFirestore.instance
            .collection('profiles')
            .doc(userId)
            .set(data);

        // Delete old document
        await FirebaseFirestore.instance
            .collection('profiles')
            .doc(oldDocId)
            .delete();
      }

      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile migrated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload profile
      _loadProfile();
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Migration failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_off,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No profile found',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your profile may need to be migrated to the new format.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _migrateProfile,
                  icon: const Icon(Icons.sync),
                  label: const Text('Migrate Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ComprehensiveProfileSetupScreen(),
                      ),
                    );
                  },
                  child: const Text('Create New Profile'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final profile = _profile!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0.5,
        foregroundColor: Colors.black,
        actions: [
          Tooltip(
            message: 'Debug Tools',
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.bug_report),
              onSelected: (value) {
                switch (value) {
                  case 'sample_data':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SampleDataDebugScreen(),
                      ),
                    );
                    break;
                  case 'migrate_profile':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const MigrateProfileDocumentsScreen(),
                      ),
                    );
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'migrate_profile',
                  child: ListTile(
                    leading: Icon(Icons.sync),
                    title: Text('Migrate Profile'),
                    subtitle: Text('Fix profile document structure'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'sample_data',
                  child: ListTile(
                    leading: Icon(Icons.data_object),
                    title: Text('Sample Data Manager'),
                    subtitle: Text('Create/manage sample data'),
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Settings',
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ),
          Tooltip(
            message: 'Edit profile',
            child: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ComprehensiveEditProfileScreen(
                      profile: profile,
                    ),
                  ),
                );
                if (result != null && result is ProfileModel) {
                  setState(() {
                    _profile = result;
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Profile updated successfully!')),
                    );
                  }
                }
              },
            ),
          ),
          Tooltip(
            message: 'Share profile',
            child: IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                _shareProfile(context);
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modern Profile Header
            _buildModernProfileHeader(profile),
            const SizedBox(height: 24),
            // About Section
            if (profile.bio?.isNotEmpty == true)
              _buildModernInfoCard(
                title: 'About',
                icon: Icons.info_outline,
                child: Text(
                  profile.bio!,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),

            // Academic Information Card
            _buildModernInfoCard(
              title: 'Academic Information',
              icon: Icons.school_rounded,
              child: Column(
                children: [
                  _buildModernInfoItem(
                    Icons.badge_rounded,
                    'Student ID',
                    profile.academicInfo?.studentId ?? 'Not specified',
                  ),
                  _buildModernInfoItem(
                    Icons.business_rounded,
                    'Faculty',
                    profile.academicInfo?.faculty ?? 'Not specified',
                  ),
                  _buildModernInfoItem(
                    Icons.apartment_rounded,
                    'Department',
                    profile.academicInfo?.department ?? 'Not specified',
                  ),
                  _buildModernInfoItem(
                    Icons.book_rounded,
                    'Program',
                    profile.academicInfo?.program ?? 'Not specified',
                  ),
                  _buildModernInfoItem(
                    Icons.calendar_today_rounded,
                    'Semester',
                    'Semester ${profile.academicInfo?.currentSemester ?? 'N/A'}',
                  ),
                  if (profile.academicInfo?.cgpa != null)
                    _buildModernInfoItem(
                      Icons.grade_rounded,
                      'CGPA',
                      profile.academicInfo!.cgpa!.toStringAsFixed(2),
                    ),
                  if (profile.academicInfo?.totalCredits != null)
                    _buildModernInfoItem(
                      Icons.credit_score_rounded,
                      'Total Credits',
                      profile.academicInfo!.totalCredits.toString(),
                    ),
                ],
              ),
            ),
            // Contact Information
            if (profile.phoneNumber?.isNotEmpty == true ||
                profile.address?.isNotEmpty == true)
              _buildModernInfoCard(
                title: 'Contact Information',
                icon: Icons.contact_phone_rounded,
                child: Column(
                  children: [
                    if (profile.phoneNumber?.isNotEmpty == true)
                      _buildModernInfoItem(
                        Icons.phone_rounded,
                        'Phone',
                        profile.phoneNumber!,
                      ),
                    if (profile.address?.isNotEmpty == true)
                      _buildModernInfoItem(
                        Icons.location_on_rounded,
                        'Address',
                        profile.address!,
                      ),
                  ],
                ),
              ),

            // Skills Section
            if (profile.skills.isNotEmpty)
              _buildModernInfoCard(
                title: 'Skills & Expertise',
                icon: Icons.psychology_rounded,
                child: _buildSkillsGrid(profile.skills),
              ),

            // Interests Section
            if (profile.interests.isNotEmpty)
              _buildModernInfoCard(
                title: 'Interests',
                icon: Icons.favorite_outline_rounded,
                child: _buildInterestsGrid(profile.interests),
              ),
            // Experience Section
            if (profile.experiences.isNotEmpty)
              _buildModernInfoCard(
                title: 'Experience',
                icon: Icons.work_rounded,
                child: Column(
                  children: profile.experiences.map((exp) {
                    return _buildExperienceItem(exp);
                  }).toList(),
                ),
              ),

            // Projects Section
            if (profile.projects.isNotEmpty)
              _buildModernInfoCard(
                title: 'Projects',
                icon: Icons.code_rounded,
                child: Column(
                  children: profile.projects.map((proj) {
                    return _buildProjectItem(proj);
                  }).toList(),
                ),
              ),

            // Achievements Section
            if (profile.achievements.isNotEmpty)
              _buildModernInfoCard(
                title: 'Achievements',
                icon: Icons.emoji_events_rounded,
                child: Column(
                  children: profile.achievements.map((ach) {
                    return _buildAchievementItem(ach);
                  }).toList(),
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _shareProfile(BuildContext context) {
    // For demo, just share a string
    Share.share('Check out my profile!');
  }

  Widget _buildModernProfileHeader(ProfileModel profile) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade600,
            Colors.purple.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Image with enhanced styling
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _getProfileImage(profile.profileImageUrl),
              ),
            ),

            const SizedBox(height: 16),

            // Name and role with improved layout
            Text(
              profile.fullName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 4),

            Text(
              profile.bio ?? 'No bio available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            Text(
              profile.academicInfo?.program ?? 'Program not specified',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Enhanced Stats Row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    'Student ID',
                    profile.academicInfo?.studentId ?? 'N/A',
                    Icons.badge_rounded,
                  ),
                  _buildStatDivider(),
                  _buildStatItem(
                    'Faculty',
                    profile.academicInfo?.faculty.split(' ').first ?? 'N/A',
                    Icons.business_rounded,
                  ),
                  _buildStatDivider(),
                  _buildStatItem(
                    'Semester',
                    profile.academicInfo?.currentSemester.toString() ?? 'N/A',
                    Icons.school_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }

  Widget _buildModernInfoCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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

  Widget _buildModernInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsGrid(List<String> skills) {
    if (skills.isEmpty) {
      return const Text(
        'No skills added yet',
        style: TextStyle(
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.map((skill) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.blue.shade200,
              width: 1,
            ),
          ),
          child: Text(
            skill,
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInterestsGrid(List<String> interests) {
    if (interests.isEmpty) {
      return const Text(
        'No interests added yet',
        style: TextStyle(
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: interests.map((interest) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.purple.shade200,
              width: 1,
            ),
          ),
          child: Text(
            interest,
            style: TextStyle(
              color: Colors.purple.shade700,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExperienceItem(ExperienceModel experience) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            experience.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            experience.company,
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (experience.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              experience.description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProjectItem(ProjectModel project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (project.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              project.description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ],
          if (project.technologies.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: project.technologies.map((tech) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.shade200,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    tech,
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

  Widget _buildAchievementItem(AchievementModel achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: Colors.amber.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  achievement.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          if (achievement.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              achievement.description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AboutDetailPage extends StatelessWidget {
  final String about;
  const AboutDetailPage({required this.about, super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(about, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

class ExperienceDetailPage extends StatelessWidget {
  final List<Map<String, String>> experience;
  const ExperienceDetailPage({required this.experience, super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Experience Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: experience
            .map((item) => ListTile(
                  title: Text(item['title'] ?? ''),
                  subtitle: Text(item['desc'] ?? ''),
                ))
            .toList(),
      ),
    );
  }
}

class ProjectDetailPage extends StatelessWidget {
  final List<Map<String, String>> projects;
  const ProjectDetailPage({required this.projects, super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Project Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: projects
            .map((item) => ListTile(
                  title: Text(item['title'] ?? ''),
                  subtitle: Text(item['desc'] ?? ''),
                ))
            .toList(),
      ),
    );
  }
}

class AchievementsDetailPage extends StatelessWidget {
  final List<Map<String, dynamic>> achievements;
  const AchievementsDetailPage({required this.achievements, super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements Details')),
      body: achievements.isEmpty
          ? const Center(
              child: Text(
                'No achievements yet.\nAdd some achievements to showcase your talents!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                final isVerified = achievement['status'] == 'Verified';
                final achievementModel =
                    achievement['achievement'] as AchievementModel?;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                achievement['title'] ?? '',
                                style: const TextStyle(
                                  fontSize: 18,
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
                                color:
                                    isVerified ? Colors.green : Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                achievement['status'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          achievement['desc'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${achievement['points'] ?? '0'} points',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.amber[600],
                              ),
                            ),
                            const Spacer(),
                            if (achievementModel != null && !isVerified)
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const AchievementsScreen(),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  final String name;
  final String year;
  final String headline;
  final String about;
  final List<Map<String, String>> experience;
  final List<Map<String, String>> projects;
  final List<Map<String, String>> achievements;
  final double gpa;
  final double coCurriculum;
  final String profileImage;
  const EditProfilePage(
      {required this.name,
      required this.year,
      required this.headline,
      required this.about,
      required this.experience,
      required this.projects,
      required this.achievements,
      required this.gpa,
      required this.coCurriculum,
      required this.profileImage,
      super.key});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _yearController;
  late TextEditingController _headlineController;
  late TextEditingController _aboutController;
  late TextEditingController _gpaController;
  late TextEditingController _coCurriculumController;
  late String _profileImage;
  List<Map<String, String>> _experience = [];
  List<Map<String, String>> _projects = [];
  List<Map<String, String>> _achievements = [];
  final ImagePicker _picker = ImagePicker();
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _yearController = TextEditingController(text: widget.year);
    _headlineController = TextEditingController(text: widget.headline);
    _aboutController = TextEditingController(text: widget.about);
    _gpaController = TextEditingController(text: widget.gpa.toString());
    _coCurriculumController =
        TextEditingController(text: widget.coCurriculum.toString());
    _profileImage = widget.profileImage;
    _experience = List<Map<String, String>>.from(widget.experience);
    _projects = List<Map<String, String>>.from(widget.projects);
    _achievements = List<Map<String, String>>.from(widget.achievements);
  }

  ImageProvider _getEditProfileImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const AssetImage('assets/images/default_profile.png');
    } else if (imageUrl.startsWith('data:image')) {
      // Handle base64 images
      final base64String = imageUrl.split(',')[1];
      final bytes = base64Decode(base64String);
      return MemoryImage(bytes);
    } else if (imageUrl.startsWith('http')) {
      // Handle network images
      return NetworkImage(imageUrl);
    } else if (imageUrl.startsWith('/') || imageUrl.contains('cache')) {
      // Handle local file images
      return FileImage(File(imageUrl));
    } else {
      // Default fallback
      return const AssetImage('assets/images/default_profile.png');
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 70,
    );
    if (image != null) {
      try {
        debugPrint('ProfileScreen: Image picked from path: ${image.path}');

        // Convert image to base64 for free storage
        final bytes = await image.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        debugPrint(
            'ProfileScreen: Image converted to base64, length: ${base64String.length}');

        setState(() {
          _profileImage = base64String;
        });

        debugPrint('ProfileScreen: Profile image updated successfully');
      } catch (e) {
        debugPrint('ProfileScreen: Error processing image: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error processing image: $e')),
          );
        }
      }
    }
  }

  void _editList(List<Map<String, String>> list, String title,
      Function(List<Map<String, String>>) onSave) {
    TextEditingController titleController = TextEditingController();
    TextEditingController descController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Add $title',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title')),
                    TextField(
                        controller: descController,
                        decoration:
                            const InputDecoration(labelText: 'Description')),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (titleController.text.isNotEmpty) {
                          setState(() {
                            list.add({
                              'title': titleController.text,
                              'desc': descController.text
                            });
                          });
                          onSave(list);
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 40,
                backgroundImage: _getEditProfileImage(_profileImage),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 20, color: Colors.blue),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name')),
            TextField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: 'Year')),
            TextField(
                controller: _headlineController,
                decoration: const InputDecoration(labelText: 'Headline')),
            TextField(
                controller: _aboutController,
                decoration: const InputDecoration(labelText: 'About'),
                maxLines: 3),
            TextField(
                controller: _gpaController,
                decoration: const InputDecoration(labelText: 'GPA'),
                keyboardType: TextInputType.number),
            TextField(
                controller: _coCurriculumController,
                decoration: const InputDecoration(labelText: 'Co-curriculum'),
                keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Experience',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _editList(_experience, 'Experience',
                        (list) => setState(() => _experience = list))),
              ],
            ),
            ..._experience.map((item) => ListTile(
                title: Text(item['title'] ?? ''),
                subtitle: Text(item['desc'] ?? ''))),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Projects',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _editList(_projects, 'Project',
                        (list) => setState(() => _projects = list))),
              ],
            ),
            ..._projects.map((item) => ListTile(
                title: Text(item['title'] ?? ''),
                subtitle: Text(item['desc'] ?? ''))),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Achievements',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _editList(_achievements, 'Achievement',
                        (list) => setState(() => _achievements = list))),
              ],
            ),
            ..._achievements.map((item) => ListTile(
                title: Text(item['title'] ?? ''),
                subtitle: Text(item['desc'] ?? ''))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'name': _nameController.text,
                  'year': _yearController.text,
                  'headline': _headlineController.text,
                  'about': _aboutController.text,
                  'experience': _experience,
                  'projects': _projects,
                  'achievements': _achievements,
                  'gpa': double.tryParse(_gpaController.text) ?? 0.0,
                  'coCurriculum':
                      double.tryParse(_coCurriculumController.text) ?? 0.0,
                  'profileImage': _profileImage,
                });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class MetricDetailPage extends StatelessWidget {
  const MetricDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Performance Metric Details')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How is your performance measured?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 12),
            Text(
                'Your performance metric is a combination of your GPA (60%) and your co-curriculum score (40%).',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 12),
            Text(
                'A balanced GPA and active co-curriculum participation will result in a higher performance score.',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 12),
            Text(
                'GPA is measured out of 4.00.\nCo-curriculum is measured out of 100.\nThe final score is calculated as:\n\nPerformance = (GPA / 4.0) * 0.6 + (Co-curriculum / 100) * 0.4',
                style: TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
