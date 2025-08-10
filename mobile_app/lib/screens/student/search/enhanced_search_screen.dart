import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../../services/search_service.dart';
import '../../../services/auth_service.dart';
import '../../../models/search_models.dart';
import '../../../widgets/search_widgets.dart';
import '../../../widgets/modern/modern_search_bar.dart';
import '../../../widgets/modern/modern_filter_bottom_sheet.dart';
import '../../../utils/app_theme.dart';
import '../../shared/profile_view_screen.dart';

class EnhancedSearchScreen extends StatefulWidget {
  const EnhancedSearchScreen({super.key});

  @override
  State<EnhancedSearchScreen> createState() => _EnhancedSearchScreenState();
}

class _EnhancedSearchScreenState extends State<EnhancedSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final SearchService _searchService = SearchService();

  Timer? _debounceTimer;
  bool _isLoading = false;
  bool _isInitialLoad = true;

  List<SearchResult> _searchResults = [];
  List<SearchHistoryItem> _searchHistory = [];
  Map<String, List<SearchFilter>> _availableFilters = {};

  String _currentQuery = '';
  final bool _showFilters = false;

  // Range filter values
  RangeValues _semesterRange = const RangeValues(1, 8);
  RangeValues _cgpaRange = const RangeValues(0, 4);

  @override
  void initState() {
    super.initState();
    _initializeSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Get current user ID from AuthService
  String? get _currentUserId {
    final authService = Provider.of<AuthService>(context, listen: false);
    return authService.currentUserId;
  }

  Future<void> _initializeSearch() async {
    setState(() {
      _isInitialLoad = true;
    });

    try {
      // Initialize search data for better performance
      await _searchService.initializeSearchData();

      // Load search history and available filters
      final history = await _searchService.getSearchHistory();
      final filters = await _searchService.getAvailableFilters();

      // Load saved filter state and merge with available filters
      final savedFilters = await _searchService.loadFilterState();
      final mergedFilters = _mergeFilterStates(filters, savedFilters);

      if (mounted) {
        setState(() {
          _searchHistory = history;
          _availableFilters = mergedFilters;
          _isInitialLoad = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialLoad = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing search: $e')),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _currentQuery = query;
    });

    // Cancel previous timer
    _debounceTimer?.cancel();

    // Start new timer for debounced search
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    });
  }

  void _onSearchSubmitted(String query) {
    _debounceTimer?.cancel();
    if (query.isNotEmpty) {
      _performSearch(query);
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final selectedFilters = _availableFilters.values
          .expand((filters) => filters)
          .where((filter) => filter.isSelected)
          .toList();

      // Track filter usage if filters are applied
      if (selectedFilters.isNotEmpty) {
        await _searchService.trackFilterUsage(
          filters: _availableFilters.values.expand((f) => f).toList(),
          query: query,
          userId: _currentUserId,
        );
      }

      final results = await _searchService.searchUsersAndProfiles(
        query: query,
        filters: selectedFilters,
        userId: _currentUserId,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: $e')),
        );
      }
    }
  }

  void _onHistoryItemTap(String query) {
    _searchController.text = query;
    _onSearchSubmitted(query);
  }

  void _onFilterToggle(SearchFilter filter) {
    setState(() {
      final categoryFilters = _availableFilters[filter.category];
      if (categoryFilters != null) {
        final index = categoryFilters.indexWhere((f) => f.id == filter.id);
        if (index != -1) {
          _availableFilters[filter.category]![index] = filter.copyWith(
            isSelected: !filter.isSelected,
          );
        }
      }
    });

    // Save filter state
    _searchService.saveFilterState(_availableFilters);

    // Re-run search if there's a current query
    if (_currentQuery.isNotEmpty) {
      _performSearch(_currentQuery);
    }
  }

  void _clearAllFilters() {
    setState(() {
      for (final category in _availableFilters.keys) {
        _availableFilters[category] = _availableFilters[category]!
            .map((filter) => filter.copyWith(isSelected: false))
            .toList();
      }
      // Reset range values
      _semesterRange = const RangeValues(1, 8);
      _cgpaRange = const RangeValues(0, 4);
    });

    // Re-run search if there's a current query
    if (_currentQuery.isNotEmpty) {
      _performSearch(_currentQuery);
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModernFilterBottomSheet(
        availableFilters: _availableFilters,
        onFilterToggle: _onFilterToggle,
        onClearAll: _clearAllFilters,
        semesterRange: _semesterRange,
        cgpaRange: _cgpaRange,
        onSemesterRangeChanged: (range) {
          setState(() {
            _semesterRange = range;
          });
        },
        onCgpaRangeChanged: (range) {
          setState(() {
            _cgpaRange = range;
          });
        },
        onApply: () {
          if (_currentQuery.isNotEmpty) {
            _performSearch(_currentQuery);
          }
        },
      ),
    );
  }

  void _navigateToProfile(SearchResult result) async {
    debugPrint(
        'EnhancedSearchScreen: Navigating to profile for user: ${result.user.name} (${result.user.uid})');
    debugPrint('EnhancedSearchScreen: Has profile: ${result.profile != null}');

    // Track analytics for profile view interaction
    await _searchService.trackResultInteraction(
      query: _currentQuery,
      result: result,
      interactionType: SearchInteractionType.view,
      userId: _currentUserId,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileViewScreen(
            userId: result.user.uid,
            isViewOnly: true,
            searchResult: result,
          ),
        ),
      );
    }
  }

  /// Merge available filters with saved filter states
  Map<String, List<SearchFilter>> _mergeFilterStates(
    Map<String, List<SearchFilter>> availableFilters,
    Map<String, List<SearchFilter>> savedFilters,
  ) {
    final mergedFilters = <String, List<SearchFilter>>{};

    for (final entry in availableFilters.entries) {
      final category = entry.key;
      final available = entry.value;
      final saved = savedFilters[category] ?? [];

      // Create a map of saved filter states
      final savedStates = <String, bool>{};
      for (final savedFilter in saved) {
        savedStates[savedFilter.id] = savedFilter.isSelected;
      }

      // Apply saved states to available filters
      final merged = available.map((filter) {
        final savedState = savedStates[filter.id];
        return savedState != null
            ? filter.copyWith(isSelected: savedState)
            : filter;
      }).toList();

      mergedFilters[category] = merged;
    }

    return mergedFilters;
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoad) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceLg),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
              const SizedBox(height: AppTheme.spaceLg),
              Text(
                'Preparing search...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildModernSearchHeader(),
            _buildFilterChips(),
            Expanded(
              child: _buildSearchContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
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
          Text(
            'Discover Talents',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          ModernSearchBar(
            controller: _searchController,
            focusNode: _searchFocusNode,
            hintText: 'Search students, lecturers, skills...',
            onChanged: _onSearchChanged,
            onSubmitted: _onSearchSubmitted,
            showFilterButton: true,
            onFilter: _showFilterBottomSheet,
            enableSuggestions: true,
            searchHistory: _searchHistory,
            onSuggestionTap: _onSearchSubmitted,
            onClear: () {
              setState(() {
                _searchController.clear();
                _currentQuery = '';
                _searchResults.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final activeFilters = _availableFilters.values
        .expand((filters) => filters)
        .where((filter) => filter.isSelected)
        .toList();

    if (activeFilters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
        itemCount: activeFilters.length + 1, // +1 for clear all button
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              margin: const EdgeInsets.only(right: AppTheme.spaceSm),
              child: FilterChip(
                label: const Text('Clear All'),
                onSelected: (selected) => _clearAllFilters(),
                backgroundColor: AppTheme.errorColor.withValues(alpha: 0.1),
                selectedColor: AppTheme.errorColor,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
              ),
            );
          }

          final filter = activeFilters[index - 1];
          return Container(
            margin: const EdgeInsets.only(right: AppTheme.spaceSm),
            child: FilterChip(
              label: Text(filter.name),
              selected: true,
              onSelected: (selected) => _onFilterToggle(filter),
              backgroundColor: AppTheme.surfaceVariant,
              selectedColor: AppTheme.primaryColor,
              checkmarkColor: Colors.white,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchContent() {
    if (_isLoading) {
      return _buildModernLoadingState();
    }

    if (_currentQuery.isNotEmpty && _searchResults.isEmpty) {
      return _buildModernEmptyState();
    }

    if (_searchResults.isNotEmpty) {
      return _buildModernSearchResults();
    }

    return _buildModernDiscoverContent();
  }

  Widget _buildModernLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          SizedBox(height: AppTheme.spaceMd),
          Text(
            'Searching...',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceLg),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            Text(
              'No Results Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Text(
              'Try adjusting your search terms or filters',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return _buildModernResultCard(result);
      },
    );
  }

  Widget _buildModernResultCard(SearchResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppTheme.spaceMd),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          child: Text(
            result.displayName.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          result.displayName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.department != null && result.department!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                result.department!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
            ],
            if (result.matchedFields.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceSm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                ),
                child: Text(
                  'Matches: ${result.matchedFields.join(', ')}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.all(AppTheme.spaceXs),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Text(
            result.roleDisplay.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        onTap: () {
          // Navigate to profile view
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileViewScreen(userId: result.user.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernDiscoverContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_searchHistory.isNotEmpty) _buildRecentSearches(),
          const SizedBox(height: AppTheme.spaceLg),
          _buildTrendingTopics(),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Searches',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchHistory.clear();
                });
              },
              child: const Text('Clear All'),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceSm),
        ...(_searchHistory.take(5).map((item) => _buildRecentSearchItem(item))),
      ],
    );
  }

  Widget _buildRecentSearchItem(SearchHistoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceXs),
      child: ListTile(
        leading: const Icon(
          Icons.history_rounded,
          color: AppTheme.textSecondaryColor,
        ),
        title: Text(item.query),
        subtitle: Text('${item.resultCount} results'),
        trailing: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            setState(() {
              _searchHistory.remove(item);
            });
          },
        ),
        onTap: () {
          _searchController.text = item.query;
          _onSearchSubmitted(item.query);
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
      ),
    );
  }

  Widget _buildTrendingTopics() {
    final trendingTopics = [
      'Web Development',
      'Mobile Apps',
      'Data Science',
      'UI/UX Design',
      'Machine Learning',
      'Cybersecurity',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trending Topics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
        ),
        const SizedBox(height: AppTheme.spaceMd),
        Wrap(
          spacing: AppTheme.spaceSm,
          runSpacing: AppTheme.spaceSm,
          children:
              trendingTopics.map((topic) => _buildTrendingChip(topic)).toList(),
        ),
      ],
    );
  }

  Widget _buildTrendingChip(String topic) {
    return GestureDetector(
      onTap: () {
        _searchController.text = topic;
        _onSearchSubmitted(topic);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMd,
          vertical: AppTheme.spaceSm,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.trending_up_rounded,
              size: 16,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: AppTheme.spaceXs),
            Text(
              topic,
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_currentQuery.isEmpty) {
      return const SearchEmptyState(
        message: 'Start typing to search',
        subtitle:
            'Find students and lecturers by name, skills, department, and more',
        icon: Icons.search,
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return SearchEmptyState(
        message: 'No results found',
        subtitle: 'Try adjusting your search terms or filters',
        icon: Icons.search_off,
        actionText: 'Clear Filters',
        onActionTap: _clearAllFilters,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return UserResultCard(
          result: result,
          onTap: () => _navigateToProfile(result),
          showMatchedFields: true,
        );
      },
    );
  }
}

/// Filter bottom sheet widget
class FilterBottomSheet extends StatefulWidget {
  final Map<String, List<SearchFilter>> availableFilters;
  final Function(SearchFilter) onFilterToggle;
  final VoidCallback onClearAll;
  final VoidCallback onApply;

  const FilterBottomSheet({
    super.key,
    required this.availableFilters,
    required this.onFilterToggle,
    required this.onClearAll,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _filterSearch = '';

  // Range filter values
  RangeValues _semesterRange = const RangeValues(1, 8);
  final RangeValues _cgpaRange = const RangeValues(0, 4);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.availableFilters.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = widget.availableFilters.values
        .expand((filters) => filters)
        .where((filter) => filter.isSelected)
        .length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header with drag handle
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (selectedCount > 0)
                          Text(
                            '$selectedCount filter${selectedCount == 1 ? '' : 's'} applied',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: widget.onClearAll,
                          child: const Text('Clear All'),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search bar for filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search filters...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _filterSearch.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _filterSearch = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                setState(() {
                  _filterSearch = value.toLowerCase();
                });
              },
            ),
          ),

          const SizedBox(height: 16),

          // Tab bar for filter categories
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: widget.availableFilters.keys.map((category) {
              final categoryFilters = widget.availableFilters[category]!;
              final selectedInCategory =
                  categoryFilters.where((f) => f.isSelected).length;

              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_getCategoryDisplayName(category)),
                    if (selectedInCategory > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          selectedInCategory.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: widget.availableFilters.entries.map((entry) {
                final category = entry.key;
                final filters = entry.value;

                return _buildFilterCategory(category, filters);
              }).toList(),
            ),
          ),

          // Apply button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onApply,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  selectedCount > 0
                      ? 'Apply $selectedCount Filter${selectedCount == 1 ? '' : 's'}'
                      : 'Apply Filters',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryDisplayName(String category) {
    switch (category.toLowerCase()) {
      case 'role':
        return 'Role';
      case 'department':
        return 'Department';
      case 'skills':
        return 'Skills';
      case 'semester':
        return 'Semester';
      case 'program':
        return 'Program';
      default:
        return category.toUpperCase();
    }
  }

  Widget _buildFilterCategory(String category, List<SearchFilter> filters) {
    // Filter based on search
    final filteredFilters = _filterSearch.isEmpty
        ? filters
        : filters
            .where(
                (filter) => filter.name.toLowerCase().contains(_filterSearch))
            .toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header with select all/none
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getCategoryDisplayName(category),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _selectAllInCategory(category, true),
                    child: const Text('Select All'),
                  ),
                  TextButton(
                    onPressed: () => _selectAllInCategory(category, false),
                    child: const Text('None'),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Special handling for range filters
          if (category == 'semester') ...[
            _buildSemesterRangeFilter(),
            const SizedBox(height: 16),
          ],

          // Filter options
          Expanded(
            child: ListView.builder(
              itemCount: filteredFilters.length,
              itemBuilder: (context, index) {
                final filter = filteredFilters[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: filter.isSelected
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                        : null,
                  ),
                  child: CheckboxListTile(
                    title: Text(
                      filter.name,
                      style: TextStyle(
                        fontWeight: filter.isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: _getFilterSubtitle(category, filter),
                    value: filter.isSelected,
                    onChanged: (_) => widget.onFilterToggle(filter),
                    activeColor: Theme.of(context).primaryColor,
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Semester Range',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: _semesterRange,
          min: 1,
          max: 8,
          divisions: 7,
          labels: RangeLabels(
            'Sem ${_semesterRange.start.round()}',
            'Sem ${_semesterRange.end.round()}',
          ),
          onChanged: (values) {
            setState(() {
              _semesterRange = values;
            });
          },
        ),
        Text(
          'Semester ${_semesterRange.start.round()} - ${_semesterRange.end.round()}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget? _getFilterSubtitle(String category, SearchFilter filter) {
    switch (category) {
      case 'skills':
        return const Text('Skill', style: TextStyle(fontSize: 12));
      case 'department':
        return const Text('Academic Department',
            style: TextStyle(fontSize: 12));
      case 'program':
        return const Text('Study Program', style: TextStyle(fontSize: 12));
      default:
        return null;
    }
  }

  void _selectAllInCategory(String category, bool select) {
    final categoryFilters = widget.availableFilters[category];
    if (categoryFilters != null) {
      for (final filter in categoryFilters) {
        if (filter.isSelected != select) {
          widget.onFilterToggle(filter);
        }
      }
    }
  }
}
