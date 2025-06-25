import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final List<String> _categories = ['Talent', 'Course', 'Year', 'Gender'];
  String _selectedCategory = 'Talent';
  String? _selectedFilterValue;
  bool _isRefreshing = false;

  // Expanded mock user data for all filter categories
  final List<Map<String, String>> _users = [
    {
      'name': 'Ahmad Zaki',
      'headline': 'Professional IoT',
      'talent': 'IoT, Robotics',
      'course': 'Computer Science',
      'year': '3',
      'gender': 'Male',
      'image': 'https://randomuser.me/api/portraits/men/11.jpg',
    },
    {
      'name': 'Nur Aina',
      'headline': 'Data Science Enthusiast',
      'talent': 'Data Analysis, Python',
      'course': 'Data Science',
      'year': '2',
      'gender': 'Female',
      'image': 'https://randomuser.me/api/portraits/women/12.jpg',
    },
    {
      'name': 'Lim Wei',
      'headline': 'Mobile App Developer',
      'talent': 'Flutter, UI/UX',
      'course': 'Software Engineering',
      'year': '4',
      'gender': 'Male',
      'image': 'https://randomuser.me/api/portraits/men/13.jpg',
    },
    {
      'name': 'Siti Aminah',
      'headline': 'AI Researcher',
      'talent': 'AI, Machine Learning',
      'course': 'Artificial Intelligence',
      'year': '1',
      'gender': 'Female',
      'image': 'https://randomuser.me/api/portraits/women/14.jpg',
    },
    {
      'name': 'John Tan',
      'headline': 'Cybersecurity Specialist',
      'talent': 'Cybersecurity, Networking',
      'course': 'Information Security',
      'year': '2',
      'gender': 'Male',
      'image': 'https://randomuser.me/api/portraits/men/15.jpg',
    },
    {
      'name': 'Aisyah Rahman',
      'headline': 'Cloud Computing',
      'talent': 'Cloud, DevOps',
      'course': 'Computer Science',
      'year': '3',
      'gender': 'Female',
      'image': 'https://randomuser.me/api/portraits/women/16.jpg',
    },
    {
      'name': 'Faizal Hassan',
      'headline': 'Game Developer',
      'talent': 'Game Dev, Unity',
      'course': 'Software Engineering',
      'year': '1',
      'gender': 'Male',
      'image': 'https://randomuser.me/api/portraits/men/17.jpg',
    },
    {
      'name': 'Chong Mei Ling',
      'headline': 'Web Developer',
      'talent': 'Web, JavaScript',
      'course': 'Information Technology',
      'year': '4',
      'gender': 'Female',
      'image': 'https://randomuser.me/api/portraits/women/18.jpg',
    },
  ];

  // Helper to get unique values for dropdowns
  List<String> get _dropdownOptions {
    if (_selectedCategory == 'Talent') {
      final skills = _users
          .expand((u) => u['talent']!.split(','))
          .map((s) => s.trim())
          .toSet()
          .toList();
      skills.sort();
      return skills;
    } else if (_selectedCategory == 'Course') {
      final courses = _users.map((u) => u['course']!).toSet().toList();
      courses.sort();
      return courses;
    } else if (_selectedCategory == 'Year') {
      final years = _users.map((u) => u['year']!).toSet().toList();
      years.sort();
      return years;
    } else if (_selectedCategory == 'Gender') {
      return ['Male', 'Female'];
    }
    return [];
  }

  List<Map<String, String>> get _filteredUsers {
    if (_selectedFilterValue == null || _selectedFilterValue!.isEmpty)
      return _users;
    if (_selectedCategory == 'Talent') {
      return _users
          .where((user) => user['talent']!
              .split(',')
              .map((s) => s.trim().toLowerCase())
              .contains(_selectedFilterValue!.toLowerCase()))
          .toList();
    } else if (_selectedCategory == 'Course') {
      return _users
          .where((user) => user['course'] == _selectedFilterValue)
          .toList();
    } else if (_selectedCategory == 'Year') {
      return _users
          .where((user) => user['year'] == _selectedFilterValue)
          .toList();
    } else if (_selectedCategory == 'Gender') {
      return _users
          .where((user) => user['gender'] == _selectedFilterValue)
          .toList();
    }
    return _users;
  }

  void _navigateToProfile(Map<String, String> user) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfileDetailScreen(user: user)),
    );
  }

  Future<void> _refreshUsers() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isRefreshing = false);
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
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 12),
            // Dropdown for filter value
            DropdownButton<String>(
              value: _selectedFilterValue,
              hint: Text('Select ${_selectedCategory.toLowerCase()}'),
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
              },
            ),
            const SizedBox(height: 16),
            // Results
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshUsers,
                child: _isRefreshing
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredUsers.isEmpty
                        ? const Center(
                            child: Text(
                                'No users found. Try adjusting your filters or search.',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey)))
                        : ListView.builder(
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              return Card(
                                color: Colors.white,
                                elevation: 2,
                                margin: const EdgeInsets.only(bottom: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                child: ListTile(
                                  onTap: () => _navigateToProfile(user),
                                  leading: CircleAvatar(
                                    backgroundImage:
                                        NetworkImage(user['image']!),
                                    radius: 28,
                                  ),
                                  title: Text(user['name']!,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black)),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (user['headline'] != null)
                                        Text(user['headline']!,
                                            style: TextStyle(
                                                color: Colors.blue[700],
                                                fontWeight: FontWeight.w500)),
                                      Text('Talent: ${user['talent']}',
                                          style: const TextStyle(
                                              color: Colors.black)),
                                      Text('Course: ${user['course']}',
                                          style: const TextStyle(
                                              color: Colors.black)),
                                      Text('Year: ${user['year']}',
                                          style: const TextStyle(
                                              color: Colors.black)),
                                      Text('Gender: ${user['gender']}',
                                          style: const TextStyle(
                                              color: Colors.black)),
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
  final Map<String, String> user;
  const ProfileDetailScreen({required this.user, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(user['name'] ?? 'Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(user['image']!),
              radius: 50,
            ),
            const SizedBox(height: 18),
            Text(user['name']!,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
            if (user['headline'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(user['headline']!,
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
                    Text('Talent: ${user['talent']}',
                        style: const TextStyle(fontSize: 16)),
                    Text('Course: ${user['course']}',
                        style: const TextStyle(fontSize: 16)),
                    Text('Year: ${user['year']}',
                        style: const TextStyle(fontSize: 16)),
                    Text('Gender: ${user['gender']}',
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
