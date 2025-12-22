import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/profile_service.dart';
import '../../../models/profile_model.dart';
import '../../../utils/error_handler.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool _isLoading = false;

  // Missing variables that were causing compilation errors
  List<ProfileModel> _allProfiles = [];
  List<ProfileModel> _filteredProfiles = [];
  String? _selectedCategory;
  String? _selectedFilterValue;

  // Categories for filtering
  final List<String> _categories = [
    'Skills',
    'Department',
    'Semester',
    'Program'
  ];

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    try {
      final profileService =
          Provider.of<ProfileService>(context, listen: false);
      final profiles = await profileService.getAllProfiles();

      if (mounted) {
        setState(() {
          _allProfiles = profiles;
          _filteredProfiles = profiles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show user-friendly error message
        ErrorHandler.showErrorSnackBar(
          context,
          'Failed to load profiles. Please check your connection and try again.',
        );
      }
    }
  }

  // Helper to get unique values for dropdowns
  List<String> get _dropdownOptions {
    if (_selectedCategory == 'Skills') {
      final skills =
          _allProfiles.expand((profile) => profile.skills).toSet().toList();
      skills.sort();
      return skills;
    } else if (_selectedCategory == 'Department') {
      final departments =
          _allProfiles.map((profile) => profile.department).toSet().toList();
      departments.sort();
      return departments.where((dept) => dept != null).map((dept) => dept!).toList();
    } else if (_selectedCategory == 'Semester') {
      final semesters = _allProfiles
          .map((profile) => profile.semester.toString())
          .toSet()
          .toList();
      semesters.sort();
      return semesters;
    } else if (_selectedCategory == 'Program') {
      final programs =
          _allProfiles.map((profile) => profile.program).toSet().toList();
      programs.sort();
      return programs.whereType<String>().toList();
    }
    return [];
  }

  void _applyFilter() {
    if (_selectedFilterValue == null || _selectedFilterValue!.isEmpty) {
      setState(() {
        _filteredProfiles = _allProfiles;
      });
      return;
    }

    List<ProfileModel> filtered = [];
    if (_selectedCategory == 'Skills') {
      filtered = _allProfiles
          .where((profile) => profile.skills.any((skill) => skill
              .toLowerCase()
              .contains(_selectedFilterValue!.toLowerCase())))
          .toList();
    } else if (_selectedCategory == 'Department') {
      filtered = _allProfiles
          .where((profile) => profile.department == _selectedFilterValue)
          .toList();
    } else if (_selectedCategory == 'Semester') {
      filtered = _allProfiles
          .where(
              (profile) => profile.semester.toString() == _selectedFilterValue)
          .toList();
    } else if (_selectedCategory == 'Program') {
      filtered = _allProfiles
          .where((profile) => profile.program == _selectedFilterValue)
          .toList();
    }

    setState(() {
      _filteredProfiles = filtered;
    });
  }

  void _navigateToProfile(ProfileModel profile) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfileDetailScreen(profile: profile)),
    );
  }

  Future<void> _refreshUsers() async {
    await _loadProfiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Profiles'),
        centerTitle: true,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories
                    .map((cat) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat,
                                style: TextStyle(
                                    color: _selectedCategory == cat
                                        ? Colors.white
                                        : Colors.blue[900])),
                            selected: _selectedCategory == cat,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = cat;
                                _selectedFilterValue = null;
                              });
                            },
                            selectedColor: Colors.blue[700],
                            backgroundColor: Colors.white,
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            // Dropdown for filter value
            DropdownButton<String>(
              value: _selectedFilterValue,
              hint: Text(
                  'Select ${_selectedCategory?.toLowerCase() ?? 'category'}'),
              isExpanded: true,
              items: _dropdownOptions
                  .map((val) => DropdownMenuItem(
                        value: val,
                        child: Text(val),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedFilterValue = val;
                });
                _applyFilter();
              },
            ),
            const SizedBox(height: 8),
            // Results
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshUsers,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredProfiles.isEmpty
                        ? const Center(
                            child: Text(
                                'No profiles found. Try adjusting your filters.',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey)))
                        : ListView.builder(
                            itemCount: _filteredProfiles.length,
                            itemBuilder: (context, index) {
                              final profile = _filteredProfiles[index];
                              return Card(
                                color: Colors.white,
                                elevation: 2,
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                child: ListTile(
                                  onTap: () => _navigateToProfile(profile),
                                  leading: CircleAvatar(
                                    backgroundImage: profile.profileImageUrl !=
                                                null &&
                                            profile.profileImageUrl!.isNotEmpty
                                        ? NetworkImage(profile.profileImageUrl!)
                                        : null,
                                    radius: 28,
                                    child: profile.profileImageUrl == null ||
                                            profile.profileImageUrl!.isEmpty
                                        ? Text(profile.fullName.isNotEmpty
                                            ? profile.fullName[0].toUpperCase()
                                            : 'U')
                                        : null,
                                  ),
                                  title: Text(profile.fullName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black)),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (profile.bio != null &&
                                          profile.bio!.isNotEmpty)
                                        Text(profile.bio!,
                                            style: TextStyle(
                                                color: Colors.blue[700],
                                                fontWeight: FontWeight.w500)),
                                      Text(
                                          'Skills: ${profile.skills.join(', ')}',
                                          style: const TextStyle(
                                              color: Colors.black)),
                                      Text('Program: ${profile.program}',
                                          style: const TextStyle(
                                              color: Colors.grey)),
                                      Text('Department: ${profile.department}',
                                          style: const TextStyle(
                                              color: Colors.grey)),
                                    ],
                                  ),
                                  isThreeLine: true,
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileDetailScreen extends StatelessWidget {
  final ProfileModel profile;
  const ProfileDetailScreen({required this.profile, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(profile.fullName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundImage: profile.profileImageUrl != null &&
                      profile.profileImageUrl!.isNotEmpty
                  ? NetworkImage(profile.profileImageUrl!)
                  : null,
              radius: 50,
              child: profile.profileImageUrl == null ||
                      profile.profileImageUrl!.isEmpty
                  ? Text(
                      profile.fullName.isNotEmpty
                          ? profile.fullName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(fontSize: 24))
                  : null,
            ),
            const SizedBox(height: 18),
            Text(profile.fullName,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
            if (profile.bio != null && profile.bio!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(profile.bio!,
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500)),
              ),
            const SizedBox(height: 18),
            Card(
              color: Colors.blue[50],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Student ID: ${profile.studentId}',
                        style: const TextStyle(fontSize: 16)),
                    Text('Program: ${profile.program}',
                        style: const TextStyle(fontSize: 16)),
                    Text('Department: ${profile.department}',
                        style: const TextStyle(fontSize: 16)),
                    Text('Semester: ${profile.semester}',
                        style: const TextStyle(fontSize: 16)),
                    Text('Skills: ${profile.skills.join(', ')}',
                        style: const TextStyle(fontSize: 16)),
                    Text('Interests: ${profile.interests.join(', ')}',
                        style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
