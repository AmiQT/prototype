import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/event_model.dart';
import '../../../services/event_service.dart';
import '../../../utils/app_theme.dart';
import '../../../config/supabase_config.dart';

class ModernEventDetailScreen extends StatefulWidget {
  final EventModel event;

  const ModernEventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  State<ModernEventDetailScreen> createState() =>
      _ModernEventDetailScreenState();
}

class _ModernEventDetailScreenState extends State<ModernEventDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final EventService _eventService = EventService();
  bool _isFavorite = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = SupabaseConfig.auth.currentUser?.id;
    _isFavorite =
        _userId != null && widget.event.favoriteUserIds.contains(_userId);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        _buildEventInfo(),
                        _buildEventDescription(),
                        _buildEventMeta(),
                        _buildActionSection(),
                        const SizedBox(height: AppTheme.space2xl),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      leading: Container(
        margin: const EdgeInsets.all(AppTheme.spaceXs),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(AppTheme.spaceXs),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? AppTheme.secondaryColor : Colors.white,
            ),
            onPressed: _toggleFavorite,
          ),
        ),
        Container(
          margin: const EdgeInsets.all(AppTheme.spaceXs),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: _shareEvent,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildEventImage(),
            _buildImageOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventImage() {
    if (widget.event.imageUrl.isNotEmpty &&
        _isValidImageUrl(widget.event.imageUrl)) {
      return CachedNetworkImage(
        imageUrl: widget.event.imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppTheme.surfaceVariant,
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildPlaceholderImage(),
      );
    } else {
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.8),
            AppTheme.primaryColor,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_rounded,
              size: 80,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            Text(
              'Event Image',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.3),
          ],
        ),
      ),
    );
  }

  Widget _buildEventInfo() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceLg),
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildCategoryBadge(),
              const Spacer(),
              _buildInterestCount(),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMd),
          Text(
            widget.event.title.isNotEmpty
                ? widget.event.title
                : 'Untitled Event',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMd,
        vertical: AppTheme.spaceXs,
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        widget.event.category.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInterestCount() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMd,
        vertical: AppTheme.spaceXs,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.people_outline_rounded,
            size: 16,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(width: AppTheme.spaceXs),
          Text(
            '${widget.event.favoriteUserIds.length} interested',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDescription() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spaceXs),
              Text(
                'About This Event',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMd),
          Text(
            widget.event.description.isNotEmpty
                ? widget.event.description
                : 'No description available for this event.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondaryColor,
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventMeta() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceLg),
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          _buildMetaItem(
            icon: Icons.calendar_today_rounded,
            label: 'Created',
            value: _formatDate(widget.event.createdAt),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          _buildMetaItem(
            icon: Icons.update_rounded,
            label: 'Last Updated',
            value: _formatDate(widget.event.updatedAt),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: AppTheme.spaceXs),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildActionSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
      child: Column(
        children: [
          _buildRegisterButton(),
          const SizedBox(height: AppTheme.spaceMd),
          _buildSecondaryActions(),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _registerForEvent,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
        icon: const Icon(Icons.event_available_rounded, color: Colors.white),
        label: Text(
          'Register for Event',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }

  Widget _buildSecondaryActions() {
    return Row(
      children: [
        Expanded(
          child: _buildSecondaryButton(
            icon: Icons.share_rounded,
            label: 'Share Event',
            onTap: _shareEvent,
          ),
        ),
        const SizedBox(width: AppTheme.spaceMd),
        Expanded(
          child: _buildSecondaryButton(
            icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
            label: _isFavorite ? 'Favorited' : 'Add to Favorites',
            onTap: _toggleFavorite,
            isActive: _isFavorite,
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMd),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.secondaryColor.withValues(alpha: 0.1)
              : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isActive
                ? AppTheme.secondaryColor
                : AppTheme.textSecondaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive
                  ? AppTheme.secondaryColor
                  : AppTheme.textSecondaryColor,
            ),
            const SizedBox(width: AppTheme.spaceXs),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isActive
                        ? AppTheme.secondaryColor
                        : AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // Action methods
  Future<void> _toggleFavorite() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add favorites')),
      );
      return;
    }

    try {
      await _eventService.toggleFavorite(
        eventId: widget.event.id,
        userId: _userId!,
        isFavorite: !_isFavorite,
      );

      setState(() {
        _isFavorite = !_isFavorite;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorite ? 'Added to favorites' : 'Removed from favorites',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating favorites: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _shareEvent() {
    Share.share(
      'Check out this event: ${widget.event.title}\n\n${widget.event.description}',
      subject: widget.event.title,
    );
  }

  Future<void> _registerForEvent() async {
    if (widget.event.registerUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration link not available'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    try {
      final url = Uri.parse(widget.event.registerUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch URL';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open registration link'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Helper methods
  bool _isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    if (url.startsWith('data:')) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }
}
