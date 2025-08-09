import '../models/user_model.dart';
import '../models/profile_model.dart';

/// Search filter model for organizing search criteria
class SearchFilter {
  final String id;
  final String name;
  final String category;
  final bool isSelected;

  SearchFilter({
    required this.id,
    required this.name,
    required this.category,
    this.isSelected = false,
  });

  SearchFilter copyWith({
    String? id,
    String? name,
    String? category,
    bool? isSelected,
  }) {
    return SearchFilter(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'isSelected': isSelected,
    };
  }

  factory SearchFilter.fromJson(Map<String, dynamic> json) {
    return SearchFilter(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      isSelected: json['isSelected'] ?? false,
    );
  }
}

/// Search result model combining user and profile data
class SearchResult {
  final UserModel user;
  final ProfileModel? profile;
  final double relevanceScore;
  final List<String> matchedFields;

  SearchResult({
    required this.user,
    this.profile,
    this.relevanceScore = 0.0,
    this.matchedFields = const [],
  });

  // Get display name (prefer profile full name, fallback to user name)
  String get displayName => profile?.fullName ?? user.name;

  // Get profile image URL
  String? get profileImageUrl => profile?.profileImageUrl;

  // Get bio/headline
  String? get bio => profile?.bio;
  String? get headline => profile?.headline;

  // Get department (prefer profile, fallback to user)
  String? get department =>
      profile?.academicInfo?.department ?? user.department;

  // Get role display
  String get roleDisplay {
    switch (user.role) {
      case UserRole.student:
        return 'Student';
      case UserRole.lecturer:
        return 'Lecturer';
      case UserRole.admin:
        return 'Admin';
    }
  }

  // Get skills
  List<String> get skills => profile?.skills ?? [];

  // Get interests
  List<String> get interests => profile?.interests ?? [];

  // Get academic info
  String? get program => profile?.academicInfo?.program;
  int? get currentSemester => profile?.academicInfo?.currentSemester;
  String? get studentId => profile?.academicInfo?.studentId ?? user.studentId;

  // Profile completeness percentage
  double get profileCompleteness {
    if (profile == null) return 0.0;

    int totalFields = 10; // Adjust based on important fields
    int completedFields = 0;

    if (profile!.fullName.isNotEmpty) completedFields++;
    if (profile!.bio != null && profile!.bio!.isNotEmpty) completedFields++;
    if (profile!.headline != null && profile!.headline!.isNotEmpty)
      completedFields++;
    if (profile!.profileImageUrl != null &&
        profile!.profileImageUrl!.isNotEmpty) completedFields++;
    if (profile!.skills.isNotEmpty) completedFields++;
    if (profile!.interests.isNotEmpty) completedFields++;
    if (profile!.experiences.isNotEmpty) completedFields++;
    if (profile!.projects.isNotEmpty) completedFields++;
    if (profile!.achievements.isNotEmpty) completedFields++;
    if (profile!.academicInfo != null) completedFields++;

    return (completedFields / totalFields) * 100;
  }

  // Check if user is currently active (for future online status)
  bool get isActive => user.isActive;

  SearchResult copyWith({
    UserModel? user,
    ProfileModel? profile,
    double? relevanceScore,
    List<String>? matchedFields,
  }) {
    return SearchResult(
      user: user ?? this.user,
      profile: profile ?? this.profile,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      matchedFields: matchedFields ?? this.matchedFields,
    );
  }
}

/// Search history item model
class SearchHistoryItem {
  final String id;
  final String query;
  final DateTime searchedAt;
  final int resultCount;
  final List<SearchFilter> appliedFilters;

  SearchHistoryItem({
    required this.id,
    required this.query,
    required this.searchedAt,
    this.resultCount = 0,
    this.appliedFilters = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'query': query,
      'searchedAt': searchedAt.toIso8601String(),
      'resultCount': resultCount,
      'appliedFilters': appliedFilters.map((f) => f.toJson()).toList(),
    };
  }

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      id: json['id'] ?? '',
      query: json['query'] ?? '',
      searchedAt: DateTime.parse(json['searchedAt']),
      resultCount: json['resultCount'] ?? 0,
      appliedFilters: (json['appliedFilters'] as List?)
              ?.map((f) => SearchFilter.fromJson(f))
              .toList() ??
          [],
    );
  }
}

/// Search suggestions model
class SearchSuggestion {
  final String text;
  final SearchSuggestionType type;
  final int frequency;

  SearchSuggestion({
    required this.text,
    required this.type,
    this.frequency = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'type': type.toString(),
      'frequency': frequency,
    };
  }

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    return SearchSuggestion(
      text: json['text'] ?? '',
      type: SearchSuggestionType.values.firstWhere(
        (type) => type.toString() == json['type'],
        orElse: () => SearchSuggestionType.general,
      ),
      frequency: json['frequency'] ?? 1,
    );
  }
}

enum SearchSuggestionType {
  general,
  name,
  skill,
  department,
  program,
}

/// Search configuration model
class SearchConfig {
  final bool enableRealTimeSearch;
  final int searchDebounceMs;
  final int maxSearchHistory;
  final int maxSuggestions;
  final bool enableSearchAnalytics;

  const SearchConfig({
    this.enableRealTimeSearch = true,
    this.searchDebounceMs = 300,
    this.maxSearchHistory = 20,
    this.maxSuggestions = 10,
    this.enableSearchAnalytics = false,
  });
}

/// Filter categories enum
enum FilterCategory {
  role,
  department,
  skills,
  semester,
  program,
}

extension FilterCategoryExtension on FilterCategory {
  String get displayName {
    switch (this) {
      case FilterCategory.role:
        return 'Role';
      case FilterCategory.department:
        return 'Department';
      case FilterCategory.skills:
        return 'Skills';
      case FilterCategory.semester:
        return 'Semester';
      case FilterCategory.program:
        return 'Program';
    }
  }
}
