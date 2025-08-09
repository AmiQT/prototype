import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/profile_model.dart';
import '../models/search_models.dart';
import '../services/profile_service.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProfileService _profileService = ProfileService();

  static const String _searchHistoryKey = 'search_history';
  static const String _searchSuggestionsKey = 'search_suggestions';
  static const String _searchCacheKey = 'search_cache';
  static const String _savedFiltersKey = 'saved_filters';

  final SearchConfig config = const SearchConfig();

  // Cache for search results and suggestions
  final Map<String, List<SearchResult>> _searchCache = {};
  final Map<String, List<SearchSuggestion>> _suggestionCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Cache duration (5 minutes)
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Popular search terms for suggestions
  List<String> _popularSearchTerms = [];
  List<String> _allUserNames = [];
  List<String> _allSkills = [];
  List<String> _allDepartments = [];

  /// Search users and profiles with advanced filtering
  Future<List<SearchResult>> searchUsersAndProfiles({
    required String query,
    List<SearchFilter> filters = const [],
    int limit = 50,
  }) async {
    try {
      debugPrint(
          'SearchService: Searching for "$query" with ${filters.length} filters');

      // Get all users (students and lecturers only)
      final usersQuery = await _firestore
          .collection('users')
          .where('role', whereIn: ['student', 'lecturer'])
          .where('isActive', isEqualTo: true)
          .limit(limit)
          .get();

      List<SearchResult> results = [];

      for (final userDoc in usersQuery.docs) {
        try {
          final userData = userDoc.data();
          final user = UserModel.fromJson(userData);

          // Get profile for this user
          debugPrint(
              'SearchService: Loading profile for user: ${user.name} (${user.uid})');
          final profile = await _profileService.getProfileByUserId(user.uid);
          debugPrint(
              'SearchService: Profile loaded for ${user.name}: ${profile?.fullName ?? 'null'}');

          // Calculate relevance score
          final relevanceScore = _calculateRelevanceScore(query, user, profile);
          final matchedFields = _getMatchedFields(query, user, profile);

          // Apply filters
          if (_passesFilters(user, profile, filters)) {
            results.add(SearchResult(
              user: user,
              profile: profile,
              relevanceScore: relevanceScore,
              matchedFields: matchedFields,
            ));
          }
        } catch (e) {
          debugPrint('SearchService: Error processing user ${userDoc.id}: $e');
          continue;
        }
      }

      // Sort by relevance score (highest first)
      results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

      // Save search to history
      if (query.isNotEmpty) {
        await _saveSearchToHistory(query, results.length, filters);
      }

      debugPrint('SearchService: Found ${results.length} results');
      return results;
    } catch (e) {
      debugPrint('SearchService: Error searching: $e');
      return [];
    }
  }

  /// Initialize search data for better performance
  Future<void> initializeSearchData() async {
    try {
      // Load popular search terms and user data for suggestions
      await _loadPopularSearchTerms();
      await _loadUserDataForSuggestions();
    } catch (e) {
      debugPrint('SearchService: Error initializing search data: $e');
    }
  }

  /// Get real-time search suggestions as user types
  Future<List<SearchSuggestion>> getSearchSuggestions(String query) async {
    if (query.isEmpty) return [];

    final cacheKey = 'suggestions_$query';

    // Check cache first
    if (_suggestionCache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
      return _suggestionCache[cacheKey]!;
    }

    try {
      final suggestions = <SearchSuggestion>[];
      final q = query.toLowerCase();

      // Name suggestions
      for (final name in _allUserNames) {
        if (name.toLowerCase().contains(q) && suggestions.length < 5) {
          suggestions.add(SearchSuggestion(
            text: name,
            type: SearchSuggestionType.name,
            frequency: _getSearchFrequency(name),
          ));
        }
      }

      // Skill suggestions
      for (final skill in _allSkills) {
        if (skill.toLowerCase().contains(q) && suggestions.length < 8) {
          suggestions.add(SearchSuggestion(
            text: skill,
            type: SearchSuggestionType.skill,
            frequency: _getSearchFrequency(skill),
          ));
        }
      }

      // Department suggestions
      for (final dept in _allDepartments) {
        if (dept.toLowerCase().contains(q) && suggestions.length < 10) {
          suggestions.add(SearchSuggestion(
            text: dept,
            type: SearchSuggestionType.department,
            frequency: _getSearchFrequency(dept),
          ));
        }
      }

      // Sort by frequency and relevance
      suggestions.sort((a, b) => b.frequency.compareTo(a.frequency));

      // Cache the results
      _suggestionCache[cacheKey] = suggestions;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return suggestions;
    } catch (e) {
      debugPrint('SearchService: Error getting suggestions: $e');
      return [];
    }
  }

  /// Calculate relevance score for search result
  double _calculateRelevanceScore(
      String query, UserModel user, ProfileModel? profile) {
    if (query.isEmpty) return 1.0;

    final q = query.toLowerCase();
    double score = 0.0;

    // Name matches (highest priority)
    if (user.name.toLowerCase().contains(q)) score += 10.0;
    if (profile?.fullName.toLowerCase().contains(q) == true) score += 10.0;

    // Exact name match bonus
    if (user.name.toLowerCase() == q) score += 20.0;
    if (profile?.fullName.toLowerCase() == q) score += 20.0;

    // Bio and headline matches
    if (profile?.bio?.toLowerCase().contains(q) == true) score += 5.0;
    if (profile?.headline?.toLowerCase().contains(q) == true) score += 5.0;

    // Skills matches
    final skillMatches = profile?.skills
            .where((skill) => skill.toLowerCase().contains(q))
            .length ??
        0;
    score += skillMatches * 3.0;

    // Interests matches
    final interestMatches = profile?.interests
            .where((interest) => interest.toLowerCase().contains(q))
            .length ??
        0;
    score += interestMatches * 2.0;

    // Department matches
    if (user.department?.toLowerCase().contains(q) == true) score += 4.0;
    if (profile?.academicInfo?.department?.toLowerCase().contains(q) == true)
      score += 4.0;

    // Program matches
    if (profile?.academicInfo?.program?.toLowerCase().contains(q) == true)
      score += 3.0;

    // Student ID matches
    if (user.studentId?.toLowerCase().contains(q) == true) score += 6.0;
    if (profile?.academicInfo?.studentId?.toLowerCase().contains(q) == true)
      score += 6.0;

    // Experience and project matches
    final experienceMatches = profile?.experiences
            .where((exp) =>
                exp.title.toLowerCase().contains(q) ||
                exp.description.toLowerCase().contains(q))
            .length ??
        0;
    score += experienceMatches * 2.0;

    final projectMatches = profile?.projects
            .where((proj) =>
                proj.title.toLowerCase().contains(q) ||
                proj.description.toLowerCase().contains(q))
            .length ??
        0;
    score += projectMatches * 2.0;

    // Profile completeness bonus
    if (profile != null) {
      final completeness = _getProfileCompleteness(profile);
      score += completeness * 0.1; // Small bonus for complete profiles
    }

    return score;
  }

  /// Get fields that matched the search query
  List<String> _getMatchedFields(
      String query, UserModel user, ProfileModel? profile) {
    if (query.isEmpty) return [];

    final q = query.toLowerCase();
    List<String> matchedFields = [];

    if (user.name.toLowerCase().contains(q)) matchedFields.add('name');
    if (profile?.fullName.toLowerCase().contains(q) == true)
      matchedFields.add('fullName');
    if (profile?.bio?.toLowerCase().contains(q) == true)
      matchedFields.add('bio');
    if (profile?.headline?.toLowerCase().contains(q) == true)
      matchedFields.add('headline');
    if (user.department?.toLowerCase().contains(q) == true)
      matchedFields.add('department');
    if (user.studentId?.toLowerCase().contains(q) == true)
      matchedFields.add('studentId');

    // Check skills
    if (profile?.skills.any((skill) => skill.toLowerCase().contains(q)) ==
        true) {
      matchedFields.add('skills');
    }

    // Check interests
    if (profile?.interests
            .any((interest) => interest.toLowerCase().contains(q)) ==
        true) {
      matchedFields.add('interests');
    }

    return matchedFields;
  }

  /// Check if result passes all applied filters
  bool _passesFilters(
      UserModel user, ProfileModel? profile, List<SearchFilter> filters) {
    for (final filter in filters.where((f) => f.isSelected)) {
      switch (filter.category) {
        case 'role':
          if (user.role.toString().split('.').last != filter.id) return false;
          break;
        case 'department':
          final userDept = user.department ?? '';
          final profileDept = profile?.academicInfo?.department ?? '';
          if (!userDept.contains(filter.name) &&
              !profileDept.contains(filter.name)) {
            return false;
          }
          break;
        case 'skills':
          if (profile?.skills.contains(filter.name) != true) return false;
          break;
        case 'semester':
          if (profile?.academicInfo?.currentSemester.toString() != filter.id)
            return false;
          break;
        case 'program':
          if (profile?.academicInfo?.program != filter.name) return false;
          break;
      }
    }
    return true;
  }

  /// Get profile completeness percentage
  double _getProfileCompleteness(ProfileModel profile) {
    int totalFields = 10;
    int completedFields = 0;

    if (profile.fullName.isNotEmpty) completedFields++;
    if (profile.bio != null && profile.bio!.isNotEmpty) completedFields++;
    if (profile.headline != null && profile.headline!.isNotEmpty)
      completedFields++;
    if (profile.profileImageUrl != null && profile.profileImageUrl!.isNotEmpty)
      completedFields++;
    if (profile.skills.isNotEmpty) completedFields++;
    if (profile.interests.isNotEmpty) completedFields++;
    if (profile.experiences.isNotEmpty) completedFields++;
    if (profile.projects.isNotEmpty) completedFields++;
    if (profile.achievements.isNotEmpty) completedFields++;
    if (profile.academicInfo != null) completedFields++;

    return (completedFields / totalFields) * 100;
  }

  /// Save search to history
  Future<void> _saveSearchToHistory(
      String query, int resultCount, List<SearchFilter> filters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_searchHistoryKey) ?? '[]';
      final historyList = jsonDecode(historyJson) as List;

      final historyItems =
          historyList.map((item) => SearchHistoryItem.fromJson(item)).toList();

      // Remove existing entry with same query
      historyItems.removeWhere((item) => item.query == query);

      // Add new entry at the beginning
      historyItems.insert(
          0,
          SearchHistoryItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            query: query,
            searchedAt: DateTime.now(),
            resultCount: resultCount,
            appliedFilters: filters.where((f) => f.isSelected).toList(),
          ));

      // Keep only recent items
      if (historyItems.length > config.maxSearchHistory) {
        historyItems.removeRange(config.maxSearchHistory, historyItems.length);
      }

      // Save back to preferences
      final updatedJson =
          jsonEncode(historyItems.map((item) => item.toJson()).toList());
      await prefs.setString(_searchHistoryKey, updatedJson);
    } catch (e) {
      debugPrint('SearchService: Error saving search history: $e');
    }
  }

  /// Get search history
  Future<List<SearchHistoryItem>> getSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_searchHistoryKey) ?? '[]';
      final historyList = jsonDecode(historyJson) as List;

      return historyList
          .map((item) => SearchHistoryItem.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('SearchService: Error loading search history: $e');
      return [];
    }
  }

  /// Clear search history
  Future<void> clearSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_searchHistoryKey);
    } catch (e) {
      debugPrint('SearchService: Error clearing search history: $e');
    }
  }

  /// Get available filters
  Future<Map<String, List<SearchFilter>>> getAvailableFilters() async {
    try {
      // Get all profiles to extract filter options
      final profiles = await _profileService.getAllProfiles();
      final users = await _getAllUsers();

      Map<String, List<SearchFilter>> filters = {};

      // Role filters
      filters['role'] = [
        SearchFilter(id: 'student', name: 'Student', category: 'role'),
        SearchFilter(id: 'lecturer', name: 'Lecturer', category: 'role'),
      ];

      // Department filters
      final departments = <String>{};
      for (final user in users) {
        if (user.department != null) departments.add(user.department!);
      }
      for (final profile in profiles) {
        if (profile.academicInfo?.department != null) {
          departments.add(profile.academicInfo!.department!);
        }
      }
      filters['department'] = departments
          .map((dept) =>
              SearchFilter(id: dept, name: dept, category: 'department'))
          .toList();

      // Skills filters (top 20 most common)
      final skillCounts = <String, int>{};
      for (final profile in profiles) {
        for (final skill in profile.skills) {
          skillCounts[skill] = (skillCounts[skill] ?? 0) + 1;
        }
      }
      final topSkills = skillCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      filters['skills'] = topSkills
          .take(20)
          .map((entry) =>
              SearchFilter(id: entry.key, name: entry.key, category: 'skills'))
          .toList();

      // Semester filters
      final semesters = <int>{};
      for (final profile in profiles) {
        if (profile.academicInfo?.currentSemester != null) {
          semesters.add(profile.academicInfo!.currentSemester);
        }
      }
      filters['semester'] = semesters
          .map((sem) => SearchFilter(
              id: sem.toString(), name: 'Semester $sem', category: 'semester'))
          .toList()
        ..sort((a, b) => int.parse(a.id).compareTo(int.parse(b.id)));

      // Program filters
      final programs = <String>{};
      for (final profile in profiles) {
        if (profile.academicInfo?.program != null) {
          programs.add(profile.academicInfo!.program!);
        }
      }
      filters['program'] = programs
          .map(
              (prog) => SearchFilter(id: prog, name: prog, category: 'program'))
          .toList();

      return filters;
    } catch (e) {
      debugPrint('SearchService: Error getting available filters: $e');
      return {};
    }
  }

  /// Get all users (students and lecturers only)
  Future<List<UserModel>> _getAllUsers() async {
    try {
      final query = await _firestore
          .collection('users')
          .where('role', whereIn: ['student', 'lecturer'])
          .where('isActive', isEqualTo: true)
          .get();

      return query.docs.map((doc) => UserModel.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('SearchService: Error getting all users: $e');
      return [];
    }
  }

  /// Load popular search terms from history
  Future<void> _loadPopularSearchTerms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_searchHistoryKey);
      if (historyJson != null) {
        final List<dynamic> historyList = json.decode(historyJson);
        final history = historyList
            .map((item) => SearchHistoryItem.fromJson(item))
            .toList();

        // Extract popular terms
        final termFrequency = <String, int>{};
        for (final item in history) {
          termFrequency[item.query] = (termFrequency[item.query] ?? 0) + 1;
        }

        _popularSearchTerms = termFrequency.entries
            .where((entry) => entry.value > 1)
            .map((entry) => entry.key)
            .toList();
      }
    } catch (e) {
      debugPrint('SearchService: Error loading popular search terms: $e');
    }
  }

  /// Load user data for suggestions
  Future<void> _loadUserDataForSuggestions() async {
    try {
      final users = await _getAllUsers();
      final profiles = await _profileService.getAllProfiles();

      // Extract names
      _allUserNames = users.map((user) => user.name).toList();
      for (final profile in profiles) {
        if (profile.fullName.isNotEmpty) {
          _allUserNames.add(profile.fullName);
        }
      }

      // Extract skills
      final skillsSet = <String>{};
      for (final profile in profiles) {
        skillsSet.addAll(profile.skills);
      }
      _allSkills = skillsSet.toList();

      // Extract departments
      final deptSet = <String>{};
      for (final user in users) {
        if (user.department != null) {
          deptSet.add(user.department!);
        }
      }
      for (final profile in profiles) {
        if (profile.academicInfo?.department != null) {
          deptSet.add(profile.academicInfo!.department);
        }
      }
      _allDepartments = deptSet.toList();
    } catch (e) {
      debugPrint('SearchService: Error loading user data for suggestions: $e');
    }
  }

  /// Check if cache is still valid
  bool _isCacheValid(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;

    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

  /// Get search frequency for a term
  int _getSearchFrequency(String term) {
    // Simple frequency based on popular terms
    if (_popularSearchTerms.contains(term)) {
      return _popularSearchTerms.indexOf(term) + 5;
    }
    return 1;
  }

  /// Clear search cache
  void clearCache() {
    _searchCache.clear();
    _suggestionCache.clear();
    _cacheTimestamps.clear();
  }

  /// Save current filter state
  Future<void> saveFilterState(Map<String, List<SearchFilter>> filters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filterData = <String, dynamic>{};

      for (final entry in filters.entries) {
        filterData[entry.key] = entry.value.map((f) => f.toJson()).toList();
      }

      await prefs.setString(_savedFiltersKey, json.encode(filterData));
      debugPrint('SearchService: Filter state saved');
    } catch (e) {
      debugPrint('SearchService: Error saving filter state: $e');
    }
  }

  /// Load saved filter state
  Future<Map<String, List<SearchFilter>>> loadFilterState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filterJson = prefs.getString(_savedFiltersKey);

      if (filterJson != null) {
        final Map<String, dynamic> filterData = json.decode(filterJson);
        final Map<String, List<SearchFilter>> filters = {};

        for (final entry in filterData.entries) {
          final List<dynamic> filterList = entry.value;
          filters[entry.key] =
              filterList.map((f) => SearchFilter.fromJson(f)).toList();
        }

        debugPrint('SearchService: Filter state loaded');
        return filters;
      }
    } catch (e) {
      debugPrint('SearchService: Error loading filter state: $e');
    }

    return {};
  }

  /// Clear saved filter state
  Future<void> clearSavedFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_savedFiltersKey);
      debugPrint('SearchService: Saved filters cleared');
    } catch (e) {
      debugPrint('SearchService: Error clearing saved filters: $e');
    }
  }

  /// Get filter presets (commonly used filter combinations)
  List<Map<String, dynamic>> getFilterPresets() {
    return [
      {
        'name': 'Computer Science Students',
        'description': 'Students in Computer Science department',
        'filters': {
          'role': ['student'],
          'department': ['Computer Science'],
        },
      },
      {
        'name': 'Final Year Students',
        'description': 'Students in semester 7-8',
        'filters': {
          'role': ['student'],
          'semester': ['7', '8'],
        },
      },
      {
        'name': 'Programming Skills',
        'description': 'People with programming skills',
        'filters': {
          'skills': ['Python', 'Java', 'JavaScript', 'C++', 'Flutter'],
        },
      },
      {
        'name': 'Lecturers Only',
        'description': 'All lecturers in the system',
        'filters': {
          'role': ['lecturer'],
        },
      },
    ];
  }
}
