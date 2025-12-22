import 'dart:async';
import 'package:flutter/material.dart';
import '../models/search_models.dart';
import '../services/search_service.dart';
import '../models/user_model.dart';
import 'profile/profile_image_widget.dart';

/// Enhanced search bar with real-time search and suggestions
class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String) onChanged;
  final Function(String) onSubmitted;
  final VoidCallback? onFilterTap;
  final bool showFilterButton;
  final List<SearchHistoryItem> searchHistory;
  final Function(String)? onHistoryItemTap;
  final bool isLoading;
  final bool enableRealTimeSuggestions;

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.hintText = 'Search people...',
    required this.onChanged,
    required this.onSubmitted,
    this.onFilterTap,
    this.showFilterButton = true,
    this.searchHistory = const [],
    this.onHistoryItemTap,
    this.isLoading = false,
    this.enableRealTimeSuggestions = true,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  bool _showSuggestions = false;
  final FocusNode _focusNode = FocusNode();
  List<SearchSuggestion> _realTimeSuggestions = [];
  Timer? _suggestionTimer;
  final SearchService _searchService = SearchService();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _showSuggestions = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _suggestionTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged(String value) {
    widget.onChanged(value);

    // Update suggestions state
    setState(() {
      _showSuggestions = _focusNode.hasFocus;
    });

    // Get real-time suggestions if enabled
    if (widget.enableRealTimeSuggestions && value.isNotEmpty) {
      _suggestionTimer?.cancel();
      _suggestionTimer = Timer(const Duration(milliseconds: 150), () {
        _loadSuggestions(value);
      });
    } else if (value.isEmpty) {
      setState(() {
        _realTimeSuggestions = [];
      });
    }
  }

  Future<void> _loadSuggestions(String query) async {
    try {
      final suggestions = await _searchService.getSearchSuggestions(query);
      if (mounted) {
        setState(() {
          _realTimeSuggestions = suggestions;
        });
      }
    } catch (e) {
      debugPrint('Error loading suggestions: $e');
    }
  }

  IconData _getSuggestionIcon(SearchSuggestionType type) {
    switch (type) {
      case SearchSuggestionType.name:
        return Icons.person;
      case SearchSuggestionType.skill:
        return Icons.star;
      case SearchSuggestionType.department:
        return Icons.business;
      case SearchSuggestionType.program:
        return Icons.school;
      case SearchSuggestionType.general:
        return Icons.search;
    }
  }

  Color _getSuggestionColor(SearchSuggestionType type) {
    switch (type) {
      case SearchSuggestionType.name:
        return Colors.blue;
      case SearchSuggestionType.skill:
        return Colors.orange;
      case SearchSuggestionType.department:
        return Colors.green;
      case SearchSuggestionType.program:
        return Colors.purple;
      case SearchSuggestionType.general:
        return Colors.grey;
    }
  }

  String _getSuggestionTypeLabel(SearchSuggestionType type) {
    switch (type) {
      case SearchSuggestionType.name:
        return 'Person';
      case SearchSuggestionType.skill:
        return 'Skill';
      case SearchSuggestionType.department:
        return 'Department';
      case SearchSuggestionType.program:
        return 'Program';
      case SearchSuggestionType.general:
        return 'Search';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            onChanged: _onTextChanged,
            onSubmitted: widget.onSubmitted,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: widget.isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        widget.controller.clear();
                        widget.onChanged('');
                        setState(() {
                          _showSuggestions = _focusNode.hasFocus;
                        });
                      },
                    ),
                  if (widget.showFilterButton && widget.onFilterTap != null)
                    IconButton(
                      icon: const Icon(Icons.tune),
                      onPressed: widget.onFilterTap,
                    ),
                ],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),

        // Search suggestions/history
        if (_showSuggestions &&
            (_realTimeSuggestions.isNotEmpty ||
                widget.searchHistory.isNotEmpty))
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            constraints: const BoxConstraints(
              maxHeight: 300, // Limit height to prevent overflow
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Real-time suggestions
                if (_realTimeSuggestions.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Suggestions',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  ..._realTimeSuggestions.take(5).map((suggestion) => ListTile(
                        leading: Icon(
                          _getSuggestionIcon(suggestion.type),
                          color: _getSuggestionColor(suggestion.type),
                          size: 20,
                        ),
                        title: Text(suggestion.text),
                        subtitle:
                            Text(_getSuggestionTypeLabel(suggestion.type)),
                        onTap: () {
                          widget.controller.text = suggestion.text;
                          widget.onSubmitted(suggestion.text);
                          setState(() {
                            _showSuggestions = false;
                          });
                        },
                      )),
                ],

                // Search history
                if (widget.searchHistory.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        16, _realTimeSuggestions.isNotEmpty ? 8 : 16, 16, 8),
                    child: const Text(
                      'Recent Searches',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: widget.searchHistory
                          .take(5)
                          .map((item) => ListTile(
                                leading: const Icon(Icons.history,
                                    color: Colors.grey, size: 20),
                                title: Text(item.query),
                                subtitle: Text('${item.resultCount} results'),
                                onTap: () {
                                  widget.onHistoryItemTap?.call(item.query);
                                  setState(() {
                                    _showSuggestions = false;
                                  });
                                },
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Filter chips widget for displaying active filters
class FilterChipsWidget extends StatelessWidget {
  final Map<String, List<SearchFilter>> availableFilters;
  final Function(SearchFilter) onFilterToggle;
  final VoidCallback? onClearAll;

  const FilterChipsWidget({
    super.key,
    required this.availableFilters,
    required this.onFilterToggle,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final selectedFilters = availableFilters.values
        .expand((filters) => filters)
        .where((filter) => filter.isSelected)
        .toList();

    if (selectedFilters.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Filters (${selectedFilters.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              if (onClearAll != null)
                TextButton(
                  onPressed: onClearAll,
                  child: const Text('Clear All'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedFilters
                .map((filter) => FilterChip(
                      label: Text(filter.name),
                      selected: filter.isSelected,
                      onSelected: (_) => onFilterToggle(filter),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => onFilterToggle(filter),
                      backgroundColor: Colors.grey[100],
                      selectedColor:
                          Theme.of(context).primaryColor.withValues(alpha: 0.2),
                      checkmarkColor: Theme.of(context).primaryColor,
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Enhanced user result card widget for displaying search results
class UserResultCard extends StatelessWidget {
  final SearchResult result;
  final VoidCallback onTap;
  final bool showMatchedFields;
  final bool showQuickActions;
  final VoidCallback? onConnect;
  final VoidCallback? onMessage;

  const UserResultCard({
    super.key,
    required this.result,
    required this.onTap,
    this.showMatchedFields = false,
    this.showQuickActions = true,
    this.onConnect,
    this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    // Enhanced profile picture with status indicator
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 2,
                            ),
                          ),
                          child: ProfileImageWidget(
                            imageUrl: result.profileImageUrl,
                            size: 64,
                            fallbackText: result.displayName.isNotEmpty
                                ? result.displayName[0].toUpperCase()
                                : 'U',
                            backgroundColor: _getRoleColor(result.user.role)
                                .withValues(alpha: 0.1),
                            textColor: _getRoleColor(result.user.role),
                            shape: BoxShape.circle,
                          ),
                        ),
                        // Activity status indicator
                        if (result.isActive)
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // User info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name and role
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  result.displayName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _buildRoleBadge(context),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Bio or headline
                          if (result.headline != null &&
                              result.headline!.isNotEmpty)
                            Text(
                              result.headline!,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )
                          else if (result.bio != null && result.bio!.isNotEmpty)
                            Text(
                              result.bio!,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                          const SizedBox(height: 6),

                          // Department and academic info
                          _buildAcademicInfo(),
                        ],
                      ),
                    ),

                    // Profile completeness indicator
                    _buildCompletenessIndicator(),
                  ],
                ),

                // Skills chips
                if (result.skills.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSkillsChips(),
                ],

                // Matched fields (if enabled)
                if (showMatchedFields && result.matchedFields.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildMatchedFields(),
                ],

                // Quick action buttons
                if (showQuickActions) ...[
                  const SizedBox(height: 16),
                  _buildQuickActions(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getRoleColor(result.user.role).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getRoleColor(result.user.role).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        result.roleDisplay,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _getRoleColor(result.user.role),
        ),
      ),
    );
  }

  Widget _buildAcademicInfo() {
    List<String> infoItems = [];

    if (result.department != null) {
      infoItems.add(result.department!);
    }

    if (result.user.role == UserRole.student) {
      if (result.currentSemester != null) {
        infoItems.add('Semester ${result.currentSemester}');
      }
      if (result.program != null) {
        infoItems.add(result.program!);
      }
    } else if (result.user.role == UserRole.lecturer) {
      // For lecturers, show their specialization or position if available
      if (result.profile?.academicInfo?.specialization != null) {
        infoItems.add(result.profile!.academicInfo!.specialization!);
      }
      // Could add lecturer position/title here in the future
    }

    if (infoItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: infoItems
          .take(2)
          .map((info) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  info,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCompletenessIndicator() {
    return Column(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            value: result.profileCompleteness / 100,
            strokeWidth: 4,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getCompletenessColor(result.profileCompleteness),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${result.profileCompleteness.round()}%',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsChips() {
    final skillsToShow = result.skills.take(4).toList();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...skillsToShow.map((skill) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.shade200,
                  width: 1,
                ),
              ),
              child: Text(
                skill,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade700,
                ),
              ),
            )),
        if (result.skills.length > 4)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+${result.skills.length - 4}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMatchedFields() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 14,
            color: Colors.green.shade600,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Matches: ${result.matchedFields.join(', ')}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.person, size: 16),
            label: const Text('View Profile'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              side: BorderSide(color: Colors.grey.shade300),
              foregroundColor: Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onConnect ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Connect feature coming soon!')),
                  );
                },
            icon: const Icon(Icons.person_add, size: 16),
            label: const Text('Connect'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onMessage ??
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message feature coming soon!')),
                );
              },
          icon: const Icon(Icons.message),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey.shade100,
            foregroundColor: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.student:
        return Colors.blue;
      case UserRole.lecturer:
        return Colors.green;
      case UserRole.admin:
        return Colors.red;
    }
  }

  Color _getCompletenessColor(double completeness) {
    if (completeness >= 80) return Colors.green;
    if (completeness >= 50) return Colors.orange;
    return Colors.red;
  }
}

/// Empty state widget for search results
class SearchEmptyState extends StatelessWidget {
  final String message;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onActionTap;
  final String? actionText;

  const SearchEmptyState({
    super.key,
    required this.message,
    this.subtitle,
    this.icon = Icons.search_off,
    this.onActionTap,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onActionTap != null && actionText != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onActionTap,
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
