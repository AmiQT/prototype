import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../services/auth_service.dart';
import '../../../services/profile_service.dart';
import '../../../models/user_model.dart';
import '../../../models/profile_model.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import 'package:share_plus/share_plus.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({Key? key}) : super(key: key);

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  String profileImage = 'assets/images/profile.png';
  String name = 'Muhammad Noor Azami Bin Wahid';
  String year = 'Year 3';
  String headline = 'Expert Prompt Engineer | IT Profession';
  double gpa = 4.00;
  double coCurriculum = 80; // out of 100
  String about = 'A little angel born with dream over the heaven';
  List<Map<String, String>> experience = [
    {
      'title': 'ITC Co-President',
      'desc': '',
    },
  ];
  List<Map<String, String>> projects = [
    {
      'title': 'Dean List',
      'desc': '',
    },
  ];
  List<Map<String, String>> achievements = [
    {
      'title': 'Dean List',
      'desc': '',
    },
  ];

  double get performanceScore {
    // Combine GPA (out of 4.0) and co-curriculum (out of 100) for a balanced metric
    return ((gpa / 4.0) * 0.6 + (coCurriculum / 100) * 0.4) * 100;
  }

  String get performanceMessage {
    if (performanceScore > 80) return 'Excellent, keep up the work!';
    if (performanceScore > 60) return 'Good, keep up the work';
    if (performanceScore > 40) return 'Balance your activities and studies!';
    return 'Needs improvement. Focus on both academics and activities.';
  }

  @override
  Widget build(BuildContext context) {
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
            message: 'Edit profile',
            child: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfilePage(
                        name: name,
                        year: year,
                        headline: headline,
                        about: about,
                        experience: experience,
                        projects: projects,
                        achievements: achievements,
                        gpa: gpa,
                        coCurriculum: coCurriculum,
                        profileImage: profileImage,
                      ),
                    ));
                if (result != null) {
                  setState(() {
                    // Update all fields from result map
                    name = result['name'];
                    year = result['year'];
                    headline = result['headline'];
                    about = result['about'];
                    experience =
                        List<Map<String, String>>.from(result['experience']);
                    projects =
                        List<Map<String, String>>.from(result['projects']);
                    achievements =
                        List<Map<String, String>>.from(result['achievements']);
                    gpa = result['gpa'];
                    coCurriculum = result['coCurriculum'];
                    profileImage = result['profileImage'];
                  });
                }
              },
            ),
          ),
          Tooltip(
            message: 'Share profile',
            child: IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                final summary =
                    'Check out my profile!\nName: $name\nHeadline: $headline\nYear: $year';
                Share.share(summary, subject: 'Student Talent Profile');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile shared!')),
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    child: _buildProfileImage(),
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
                                name,
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
                                year,
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
                          headline,
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
            // Performance Meter
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => MetricDetailPage())),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: Colors.white,
                child: Column(
                  children: [
                    const Text('Performance Status',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              Container(
                                height: 18,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.red,
                                      Colors.yellow,
                                      Colors.green
                                    ],
                                  ),
                                ),
                              ),
                              // Indicator thumb
                              Positioned(
                                left: (performanceScore.clamp(0, 100) / 100) *
                                    (MediaQuery.of(context).size.width -
                                        64 -
                                        18),
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                        color: Colors.blue[700]!, width: 2),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Bad',
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 12)),
                              Text('Good',
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(performanceMessage,
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                            fontSize: 15)),
                  ],
                ),
              ),
            ),
            // Details Cards
            _buildSectionCard('About', about,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AboutDetailPage(about: about)))),
            _buildSectionCard('Experience', null,
                items: experience,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ExperienceDetailPage(experience: experience)))),
            _buildSectionCard('Project', null,
                items: projects,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ProjectDetailPage(projects: projects)))),
            _buildSectionCard('Achievements', null,
                items: achievements,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AchievementsDetailPage(
                            achievements: achievements)))),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    if (profileImage.startsWith('http')) {
      return Tooltip(
        message: 'Profile image',
        child: CircleAvatar(
          radius: 33,
          backgroundImage: NetworkImage(profileImage),
          onBackgroundImageError: (_, __) {},
          child: Image.network(
            profileImage,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image, size: 48, color: Colors.grey),
            semanticLabel: 'Profile image',
          ),
        ),
      );
    } else {
      return Tooltip(
        message: 'Profile image',
        child: CircleAvatar(
          radius: 33,
          backgroundImage: AssetImage(profileImage),
          child: Image.asset(
            profileImage,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image, size: 48, color: Colors.grey),
            semanticLabel: 'Profile image',
          ),
        ),
      );
    }
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
}

class AboutDetailPage extends StatelessWidget {
  final String about;
  const AboutDetailPage({required this.about, Key? key}) : super(key: key);
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
  const ExperienceDetailPage({required this.experience, Key? key})
      : super(key: key);
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
  const ProjectDetailPage({required this.projects, Key? key}) : super(key: key);
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
  final List<Map<String, String>> achievements;
  const AchievementsDetailPage({required this.achievements, Key? key})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: achievements
            .map((item) => ListTile(
                  title: Text(item['title'] ?? ''),
                  subtitle: Text(item['desc'] ?? ''),
                ))
            .toList(),
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
      Key? key})
      : super(key: key);
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

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = image.path;
      });
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
                backgroundImage: _profileImage.startsWith('http')
                    ? NetworkImage(_profileImage)
                    : FileImage(File(_profileImage)) as ImageProvider,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    decoration: BoxDecoration(
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Performance Metric Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
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
