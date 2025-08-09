import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
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
    } else {
      // Handle file images
      return FileImage(File(imageUrl));
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
        body: const Center(
          child: Text(
            'No profile found. Please complete your profile setup.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
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
            message: 'Sample Data Manager',
            child: IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SampleDataDebugScreen(),
                  ),
                );
              },
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
                    builder: (_) => EditProfilePage(
                      name: profile.fullName,
                      year: 'Year ${profile.semester}',
                      headline: profile.headline ?? '',
                      about: profile.bio ?? '',
                      experience: profile.experiences
                          .map((exp) => {
                                'title': exp.title,
                                'desc': exp.description,
                              })
                          .toList(),
                      projects: profile.projects
                          .map((proj) => {
                                'title': proj.title,
                                'desc': proj.description,
                              })
                          .toList(),
                      achievements: profile.achievements
                          .map((ach) => {
                                'title': ach.title,
                                'desc': ach.description,
                              })
                          .toList(),
                      gpa: profile.academicInfo?.cgpa ?? 0.0,
                      coCurriculum: 80.0,
                      profileImage: profile.profileImageUrl ?? '',
                    ),
                  ),
                );
                if (result != null) {
                  // Update the profile in Firebase
                  try {
                    if (!mounted) return;
                    final profileService =
                        Provider.of<ProfileService>(context, listen: false);

                    // Convert experience data to ExperienceModel
                    final experiences =
                        (result['experience'] as List<Map<String, String>>)
                            .map((exp) => ExperienceModel(
                                  id: DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString(),
                                  title: exp['title'] ?? '',
                                  company: exp['company'] ?? 'Company',
                                  description: exp['desc'] ?? '',
                                  startDate: DateTime.now(),
                                  endDate: DateTime.now(),
                                ))
                            .toList();

                    // Convert projects data to ProjectModel
                    final projects =
                        (result['projects'] as List<Map<String, String>>)
                            .map((proj) => ProjectModel(
                                  id: DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString(),
                                  title: proj['title'] ?? '',
                                  description: proj['desc'] ?? '',
                                  technologies: [],
                                  startDate: DateTime.now(),
                                  endDate: DateTime.now(),
                                ))
                            .toList();

                    // Convert achievements data to AchievementModel
                    final achievements =
                        (result['achievements'] as List<Map<String, String>>)
                            .map((ach) => AchievementModel(
                                  id: DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString(),
                                  userId: profile.userId,
                                  title: ach['title'] ?? '',
                                  description: ach['desc'] ?? '',
                                  type: AchievementType.other,
                                  dateAchieved: DateTime.now(),
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                ))
                            .toList();

                    final updatedProfile = profile.copyWith(
                      fullName: result['name'],
                      bio: result['about'],
                      headline: result['headline'],
                      profileImageUrl: result['profileImage'],
                      experiences: experiences,
                      projects: projects,
                      achievements: achievements,
                      updatedAt: DateTime.now(),
                    );
                    await profileService.updateProfile(updatedProfile);
                    setState(() {
                      _profile = updatedProfile;
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Profile updated successfully!')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating profile: $e')),
                      );
                    }
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    child: Tooltip(
                      message: 'Profile image',
                      child: CircleAvatar(
                        radius: 33,
                        backgroundImage:
                            _getProfileImage(profile.profileImageUrl),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                profile.fullName,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Semester ${profile.academicInfo?.currentSemester ?? 'N/A'}',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.bio ?? '', // Headline as bio
                          style: const TextStyle(
                              fontSize: 15,
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.academicInfo?.program ??
                              'Program not specified',
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (profile.headline?.isNotEmpty == true)
              _buildSectionCard('Headline', profile.headline!, onTap: () {}),
            _buildSectionCard('About', profile.bio ?? '', onTap: () {}),
            _buildSectionCard('Academic Information', null,
                items: [
                  {
                    'title': 'Student ID',
                    'desc': profile.academicInfo?.studentId ?? 'Not specified'
                  },
                  {
                    'title': 'Faculty',
                    'desc': profile.academicInfo?.faculty ?? 'Not specified'
                  },
                  {
                    'title': 'Department',
                    'desc': profile.academicInfo?.department ?? 'Not specified'
                  },
                  {
                    'title': 'Program',
                    'desc': profile.academicInfo?.program ?? 'Not specified'
                  },
                  {
                    'title': 'Semester',
                    'desc':
                        'Semester ${profile.academicInfo?.currentSemester ?? 'N/A'}'
                  },
                  if (profile.academicInfo?.cgpa != null)
                    {
                      'title': 'CGPA',
                      'desc': profile.academicInfo!.cgpa!.toStringAsFixed(2)
                    },
                  if (profile.academicInfo?.totalCredits != null)
                    {
                      'title': 'Total Credits',
                      'desc': profile.academicInfo!.totalCredits.toString()
                    },
                ],
                onTap: () {}),
            if (profile.phoneNumber?.isNotEmpty == true ||
                profile.address?.isNotEmpty == true)
              _buildSectionCard('Contact Information', null,
                  items: [
                    if (profile.phoneNumber?.isNotEmpty == true)
                      {'title': 'Phone', 'desc': profile.phoneNumber!},
                    if (profile.address?.isNotEmpty == true)
                      {'title': 'Address', 'desc': profile.address!},
                  ],
                  onTap: () {}),
            _buildSectionCard('Skills', null,
                items: profile.skills
                    .map((s) => {'title': s, 'desc': ''})
                    .toList(),
                onTap: () {}),
            _buildSectionCard('Interests', null,
                items: profile.interests
                    .map((i) => {'title': i, 'desc': ''})
                    .toList(),
                onTap: () {}),
            if (profile.experiences.isNotEmpty)
              _buildSectionCard('Experience', null,
                  items: profile.experiences
                      .map((exp) => {
                            'title': exp.title,
                            'desc': '${exp.company} • ${exp.description}',
                          })
                      .toList(),
                  onTap: () {}),
            if (profile.projects.isNotEmpty)
              _buildSectionCard('Projects', null,
                  items: profile.projects
                      .map((proj) => {
                            'title': proj.title,
                            'desc': proj.description,
                          })
                      .toList(),
                  onTap: () {}),
            if (profile.achievements.isNotEmpty)
              _buildSectionCard('Achievements', null,
                  items: profile.achievements
                      .map((ach) => {
                            'title': ach.title,
                            'desc': ach.description,
                          })
                      .toList(),
                  onTap: () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, String? content,
      {List<Map<String, String>>? items, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black)),
              const SizedBox(height: 8),
              if (content != null)
                Text(content,
                    style: const TextStyle(fontSize: 15, color: Colors.black)),
              if (items != null)
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['title'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.black)),
                          if (item['desc'] != null)
                            Text(item['desc']!,
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.black87)),
                        ],
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  void _shareProfile(BuildContext context) {
    // For demo, just share a string
    Share.share('Check out my profile!');
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
    } else {
      // Handle file images
      return FileImage(File(imageUrl));
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
        // Convert image to base64 for free storage
        final bytes = await image.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        setState(() {
          _profileImage = base64String;
        });
      } catch (e) {
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
