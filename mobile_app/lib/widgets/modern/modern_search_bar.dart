import 'package:flutter/material.dart';
import 'dart:async';
import '../../utils/app_theme.dart';
import '../../services/search_service.dart';
import '../../models/search_models.dart';

class ModernSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final VoidCallback? onClear;
  final VoidCallback? onFilter;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool showFilterButton;
  final bool enableSuggestions;
  final List<SearchHistoryItem> searchHistory;
  final Function(String)? onSuggestionTap;

  const ModernSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.onFilter,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.showFilterButton = false,
    this.enableSuggestions = true,
    this.searchHistory = const [],
    this.onSuggestionTap,
  });

  @override
  State<ModernSearchBar> createState() => _ModernSearchBarState();
}

class _ModernSearchBarState extends State<ModernSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  bool _isFocused = false;
  bool _hasText = false;
  bool _showSuggestions = false;

  // Suggestion functionality
  final SearchService _searchService = SearchService();
  List<SearchSuggestion> _suggestions = [];
  Timer? _suggestionTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Initialize color animation with a placeholder, updated in didChangeDependencies
    _colorAnimation = ColorTween(
      begin: Colors.grey[200],
      end: Colors.blue.withValues(alpha: 0.1),
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    widget.focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
    _hasText = widget.controller.text.isNotEmpty;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update color animation with proper theme colors after dependencies are ready
    final colorScheme = Theme.of(context).colorScheme;
    _colorAnimation = ColorTween(
      begin: colorScheme.surfaceContainerHighest,
      end: colorScheme.primary.withValues(alpha: 0.1),
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    _animationController.dispose();
    _suggestionTimer?.cancel();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = widget.focusNode.hasFocus;
      _showSuggestions = _isFocused && widget.enableSuggestions;
    });

    if (_isFocused) {
      _animationController.forward();
      // Load suggestions when focused
      if (widget.enableSuggestions && widget.controller.text.isNotEmpty) {
        _loadSuggestions(widget.controller.text);
      }
    } else {
      _animationController.reverse();
      // Hide suggestions when focus lost
      setState(() {
        _showSuggestions = false;
      });
    }
  }

  void _onTextChange() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }

    widget.onChanged?.call(widget.controller.text);

    // Handle suggestions
    if (widget.enableSuggestions && _isFocused) {
      _suggestionTimer?.cancel();
      if (hasText) {
        _suggestionTimer = Timer(const Duration(milliseconds: 300), () {
          _loadSuggestions(widget.controller.text);
        });
      } else {
        setState(() {
          _suggestions = [];
          _showSuggestions = _isFocused;
        });
      }
    }
  }

  Future<void> _loadSuggestions(String query) async {
    if (!widget.enableSuggestions || query.isEmpty) return;

    try {
      final suggestions = await _searchService.getSearchSuggestions(query);
      if (mounted && _isFocused) {
        setState(() {
          _suggestions = suggestions;
          _showSuggestions = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading suggestions: $e');
    }
  }

  void _clearText() {
    widget.controller.clear();
    widget.onClear?.call();
    widget.focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _colorAnimation.value,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: _isFocused
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: _isFocused
                            ? [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: TextField(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        enabled: widget.enabled,
                        onSubmitted: widget.onSubmitted,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                        decoration: InputDecoration(
                          hintText: widget.hintText,
                          hintStyle:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                          prefixIcon: widget.prefixIcon ??
                              Container(
                                padding: const EdgeInsets.all(AppTheme.spaceMd),
                                child: Icon(
                                  Icons.search_rounded,
                                  color: _isFocused
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                  size: 20,
                                ),
                              ),
                          suffixIcon: _hasText
                              ? Container(
                                  padding:
                                      const EdgeInsets.all(AppTheme.spaceXs),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.clear_rounded,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      size: 20,
                                    ),
                                    onPressed: _clearText,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                  ),
                                )
                              : widget.suffixIcon,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spaceMd,
                            vertical: AppTheme.spaceMd,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.showFilterButton) ...[
              const SizedBox(width: AppTheme.spaceSm),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .shadow
                          .withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: widget.onFilter,
                  icon: Icon(
                    Icons.tune_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
              ),
            ],
          ],
        ),

        // Suggestions overlay
        if (_showSuggestions &&
            (_suggestions.isNotEmpty || widget.searchHistory.isNotEmpty))
          Container(
            margin: const EdgeInsets.only(top: AppTheme.spaceXs),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .shadow
                      .withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            constraints: const BoxConstraints(maxHeight: 300),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Real-time suggestions
                if (_suggestions.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceMd),
                    child: Text(
                      'Suggestions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  ..._suggestions
                      .take(5)
                      .map((suggestion) => _buildSuggestionItem(suggestion)),
                ],

                // Search history
                if (widget.searchHistory.isNotEmpty &&
                    _suggestions.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceMd),
                    child: Text(
                      'Recent Searches',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  ...widget.searchHistory
                      .take(5)
                      .map((item) => _buildHistoryItem(item)),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestionItem(SearchSuggestion suggestion) {
    return InkWell(
      onTap: () {
        widget.controller.text = suggestion.text;
        widget.onSuggestionTap?.call(suggestion.text);
        widget.onSubmitted?.call(suggestion.text);
        setState(() {
          _showSuggestions = false;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMd,
          vertical: AppTheme.spaceXs,
        ),
        child: Row(
          children: [
            Icon(
              _getSuggestionIcon(suggestion.type),
              size: 18,
              color: _getSuggestionColor(suggestion.type),
            ),
            const SizedBox(width: AppTheme.spaceSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.text,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    _getSuggestionTypeLabel(suggestion.type),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(SearchHistoryItem item) {
    return InkWell(
      onTap: () {
        widget.controller.text = item.query;
        widget.onSuggestionTap?.call(item.query);
        widget.onSubmitted?.call(item.query);
        setState(() {
          _showSuggestions = false;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMd,
          vertical: AppTheme.spaceXs,
        ),
        child: Row(
          children: [
            Icon(
              Icons.history_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppTheme.spaceSm),
            Expanded(
              child: Text(
                item.query,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              '${item.resultCount} results',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSuggestionIcon(SearchSuggestionType type) {
    switch (type) {
      case SearchSuggestionType.name:
        return Icons.person_rounded;
      case SearchSuggestionType.skill:
        return Icons.star_rounded;
      case SearchSuggestionType.department:
        return Icons.school_rounded;
      case SearchSuggestionType.program:
        return Icons.book_rounded;
      default:
        return Icons.search_rounded;
    }
  }

  Color _getSuggestionColor(SearchSuggestionType type) {
    switch (type) {
      case SearchSuggestionType.name:
        return Theme.of(context).colorScheme.primary;
      case SearchSuggestionType.skill:
        return Theme.of(context).colorScheme.secondary;
      case SearchSuggestionType.department:
        return Theme.of(context).colorScheme.primary;
      case SearchSuggestionType.program:
        return Theme.of(context).colorScheme.tertiary;
      default:
        return Theme.of(context).textTheme.bodyMedium?.color ??
            Theme.of(context).colorScheme.onSurfaceVariant;
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
      default:
        return 'Search';
    }
  }
}

class ModernSearchBarWithVoice extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final VoidCallback? onClear;
  final VoidCallback? onVoiceSearch;
  final bool enabled;

  const ModernSearchBarWithVoice({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.onVoiceSearch,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ModernSearchBar(
            controller: controller,
            focusNode: focusNode,
            hintText: hintText,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            onClear: onClear,
            enabled: enabled,
          ),
        ),
        const SizedBox(width: AppTheme.spaceSm),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.mic_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: onVoiceSearch ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Voice search coming soon!'),
                      backgroundColor: AppTheme.infoColor,
                    ),
                  );
                },
            constraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
          ),
        ),
      ],
    );
  }
}

class SearchSuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final IconData? icon;
  final bool isSelected;

  const SearchSuggestionChip({
    super.key,
    required this.text,
    this.onTap,
    this.onDelete,
    this.icon,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMd,
          vertical: AppTheme.spaceSm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
              const SizedBox(width: AppTheme.spaceXs),
            ],
            Text(
              text,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: AppTheme.spaceXs),
              GestureDetector(
                onTap: onDelete,
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
