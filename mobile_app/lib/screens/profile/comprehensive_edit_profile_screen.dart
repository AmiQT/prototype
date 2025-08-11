import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../models/profile_model.dart';
import '../../models/academic_info_model.dart';
import '../../models/experience_model.dart';
import '../../models/project_model.dart';
import '../../services/profile_service.dart';
import '../../utils/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/modern/modern_text_field.dart';
import '../../widgets/modern/modern_button.dart';
import '../../widgets/profile/skills_selector.dart';
import '../../widgets/profile/interests_selector.dart';
import '../../widgets/profile/experience_editor.dart';
import '../../widgets/profile/projects_editor.dart';

class ComprehensiveEditProfileScreen extends StatefulWidget {
  final ProfileModel profile;

  const ComprehensiveEditProfileScreen({
    super.key,
    required this.profile,
  });

  @override
  State<ComprehensiveEditProfileScreen> createState() =>
      _ComprehensiveEditProfileScreenState();
}

class _ComprehensiveEditProfileScreenState
    extends State<ComprehensiveEditProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers for basic info
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _bioController;
  late TextEditingController _headlineController;

  // Academic info controllers
  late TextEditingController _studentIdController;
  late TextEditingController _programController;
  late TextEditingController _departmentController;
  late TextEditingController _facultyController;
  late TextEditingController _cgpaController;

  // Profile data
  String? _profileImageUrl;
  List<String> _selectedSkills = [];
  List<String> _selectedInterests = [];
  List<ExperienceModel> _experiences = [];
  List<ProjectModel> _projects = [];
  int _currentSemester = 1;

  final ImagePicker _picker = ImagePicker();

  ImageProvider? _getProfileImageProvider(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    } else if (imageUrl.startsWith('data:image')) {
      // Handle base64 images
      final base64String = imageUrl.split(',')[1];
      final bytes = base64Decode(base64String);
      return MemoryImage(bytes);
    } else if (imageUrl.startsWith('http')) {
      // Handle network images
      return NetworkImage(imageUrl);
    } else if (imageUrl.startsWith('/') || imageUrl.contains('cache')) {
      // Handle local file images (fallback)
      return FileImage(File(imageUrl));
    } else {
      // Invalid URL, return null to show fallback
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeControllers();
    _loadProfileData();
  }

  void _initializeControllers() {
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _bioController = TextEditingController();
    _headlineController = TextEditingController();
    _studentIdController = TextEditingController();
    _programController = TextEditingController();
    _departmentController = TextEditingController();
    _facultyController = TextEditingController();
    _cgpaController = TextEditingController();
  }

  void _loadProfileData() {
    final profile = widget.profile;

    // Basic info
    _fullNameController.text = profile.fullName;
    _phoneController.text = profile.phoneNumber ?? '';
    _addressController.text = profile.address ?? '';
    _bioController.text = profile.bio ?? '';
    _headlineController.text = profile.headline ?? '';
    _profileImageUrl = profile.profileImageUrl;

    // Academic info
    if (profile.academicInfo != null) {
      _studentIdController.text = profile.academicInfo!.studentId;
      _programController.text = profile.academicInfo!.program;
      _departmentController.text = profile.academicInfo!.department;
      _facultyController.text = profile.academicInfo!.faculty;
      _currentSemester = profile.academicInfo!.currentSemester;
      _cgpaController.text = profile.academicInfo!.cgpa?.toString() ?? '';
    }

    // Skills and interests
    _selectedSkills = List.from(profile.skills);
    _selectedInterests = List.from(profile.interests);

    // Experiences and projects
    _experiences = List.from(profile.experiences);
    _projects = List.from(profile.projects);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    _headlineController.dispose();
    _studentIdController.dispose();
    _programController.dispose();
    _departmentController.dispose();
    _facultyController.dispose();
    _cgpaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(l10n.editProfile),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(icon: Icon(Icons.person), text: l10n.basic),
            Tab(icon: Icon(Icons.school), text: l10n.academic),
            Tab(icon: Icon(Icons.star), text: l10n.skillsAndInterests),
            Tab(icon: Icon(Icons.work), text: l10n.experience),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBasicInfoTab(),
            _buildAcademicInfoTab(),
            _buildSkillsAndInterestsTab(),
            _buildExperienceTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Image Section
          Center(
            child: _buildProfileImageSection(),
          ),

          const SizedBox(height: AppTheme.spaceLg),

          // Basic Information
          Text(
            AppLocalizations.of(context).basicInformation,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
          ),

          const SizedBox(height: AppTheme.spaceMd),

          ModernTextField(
            controller: _fullNameController,
            label: AppLocalizations.of(context).fullName,
            icon: Icons.person,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return AppLocalizations.of(context).pleaseEnterFullName;
              }
              return null;
            },
          ),

          const SizedBox(height: AppTheme.spaceMd),

          ModernTextField(
            controller: _headlineController,
            label: AppLocalizations.of(context).headline,
            icon: Icons.title,
            hintText: 'e.g., Computer Science Student',
          ),

          const SizedBox(height: AppTheme.spaceMd),

          ModernTextField(
            controller: _phoneController,
            label: AppLocalizations.of(context).phoneNumber,
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),

          const SizedBox(height: AppTheme.spaceMd),

          ModernTextField(
            controller: _addressController,
            label: AppLocalizations.of(context).address,
            icon: Icons.location_on,
            maxLines: 2,
          ),

          const SizedBox(height: AppTheme.spaceMd),

          ModernTextField(
            controller: _bioController,
            label: AppLocalizations.of(context).bio,
            icon: Icons.description,
            maxLines: 4,
            hintText: AppLocalizations.of(context).tellUsAboutYourself,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.primaryColor,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            CircleAvatar(
              radius: 57,
              backgroundColor: AppTheme.lightGrayColor,
              backgroundImage: _getProfileImageProvider(_profileImageUrl),
              child: _getProfileImageProvider(_profileImageUrl) == null
                  ? Icon(
                      Icons.person,
                      size: 50,
                      color: AppTheme.grayColor,
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).academicInformation,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
          ),

          const SizedBox(height: AppTheme.spaceMd),

          ModernTextField(
            controller: _studentIdController,
            label: AppLocalizations.of(context).studentId,
            icon: Icons.badge,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return AppLocalizations.of(context).pleaseEnterStudentId;
              }
              return null;
            },
          ),

          const SizedBox(height: AppTheme.spaceMd),

          ModernTextField(
            controller: _programController,
            label: AppLocalizations.of(context).program,
            icon: Icons.school,
          ),

          const SizedBox(height: AppTheme.spaceMd),

          ModernTextField(
            controller: _departmentController,
            label: AppLocalizations.of(context).department,
            icon: Icons.business,
          ),

          const SizedBox(height: AppTheme.spaceMd),

          ModernTextField(
            controller: _facultyController,
            label: AppLocalizations.of(context).faculty,
            icon: Icons.account_balance,
          ),

          const SizedBox(height: AppTheme.spaceMd),

          // Semester Selector
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.lightGrayColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).currentSemester,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppTheme.spaceSm),
                DropdownButtonFormField<int>(
                  value: _currentSemester,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: List.generate(8, (index) => index + 1)
                      .map((semester) => DropdownMenuItem(
                            value: semester,
                            child: Text('Semester $semester'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _currentSemester = value ?? 1;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spaceMd),

          ModernTextField(
            controller: _cgpaController,
            label: AppLocalizations.of(context).cgpa,
            icon: Icons.grade,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsAndInterestsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skills Section
          SkillsSelector(
            selectedSkills: _selectedSkills,
            onSkillsChanged: (skills) {
              setState(() {
                _selectedSkills = skills;
              });
            },
          ),

          const SizedBox(height: AppTheme.spaceLg),

          // Interests Section
          InterestsSelector(
            selectedInterests: _selectedInterests,
            onInterestsChanged: (interests) {
              setState(() {
                _selectedInterests = interests;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      child: Column(
        children: [
          // Experience Section
          ExperienceEditor(
            experiences: _experiences,
            onExperiencesChanged: (experiences) {
              setState(() {
                _experiences = experiences;
              });
            },
          ),

          const SizedBox(height: AppTheme.spaceLg),

          // Projects Section
          ProjectsEditor(
            projects: _projects,
            onProjectsChanged: (projects) {
              setState(() {
                _projects = projects;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ModernButton(
          text: AppLocalizations.of(context).saveProfile,
          onPressed: _isLoading ? null : _saveProfile,
          isLoading: _isLoading,
          icon: Icons.save,
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        // Convert image to base64 for storage
        final bytes = await image.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        setState(() {
          _profileImageUrl = base64String;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context).imageSelectedSuccessfully),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).errorSelectingImage),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final profileService =
          Provider.of<ProfileService>(context, listen: false);

      // Create academic info
      final academicInfo = AcademicInfoModel(
        studentId: _studentIdController.text.trim(),
        program: _programController.text.trim(),
        department: _departmentController.text.trim(),
        faculty: _facultyController.text.trim(),
        currentSemester: _currentSemester,
        cgpa: double.tryParse(_cgpaController.text.trim()),
        enrollmentDate:
            widget.profile.academicInfo?.enrollmentDate ?? DateTime.now(),
      );

      // Create updated profile
      final updatedProfile = widget.profile.copyWith(
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        headline: _headlineController.text.trim().isEmpty
            ? null
            : _headlineController.text.trim(),
        profileImageUrl: _profileImageUrl,
        academicInfo: academicInfo,
        skills: _selectedSkills,
        interests: _selectedInterests,
        experiences: _experiences,
        projects: _projects,
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await profileService.saveProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context).profileUpdatedSuccessfully),
            backgroundColor: AppTheme.successColor,
          ),
        );

        Navigator.pop(context, updatedProfile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppLocalizations.of(context).errorUpdatingProfile}: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
