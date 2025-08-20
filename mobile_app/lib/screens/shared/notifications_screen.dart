import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import '../../services/supabase_auth_service.dart';
import '../../models/notification_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/modern/modern_notification_card.dart';
import '../settings/notification_settings_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  late TabController _tabController;

  List<AppNotification> _notifications = [];
  NotificationType? _selectedFilter;
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notificationService.removeListener(_onNotificationsUpdated);
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    final authService =
        Provider.of<SupabaseAuthService>(context, listen: false);
    final userId = authService.currentUserId;

    if (userId != null) {
      await _notificationService.initialize(userId);
      _notificationService.addListener(_onNotificationsUpdated);
      _onNotificationsUpdated(_notificationService.notifications);
    }
  }

  void _onNotificationsUpdated(List<AppNotification> notifications) {
    if (mounted) {
      setState(() {
        _notifications = notifications;
      });
    }
  }

  List<AppNotification> get _filteredNotifications {
    var filtered = _notifications;

    // Filter by type
    if (_selectedFilter != null) {
      filtered = filtered.where((n) => n.type == _selectedFilter).toList();
    }

    // Filter by read status
    if (_showUnreadOnly) {
      filtered = filtered.where((n) => !n.isRead).toList();
    }

    return filtered;
  }

  List<AppNotification> get _unreadNotifications {
    return _notifications.where((n) => !n.isRead).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_notificationService.unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.mark_email_read_rounded),
              tooltip: 'Mark all as read',
              onPressed: () async {
                await _notificationService.markAllAsRead();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All notifications marked as read'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              },
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              switch (value) {
                case 'clear_all':
                  _showClearAllDialog();
                  break;
                case 'settings':
                  _showNotificationSettings();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all_rounded),
                    SizedBox(width: 8),
                    Text('Clear All'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_rounded),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              text: 'All (${_notifications.length})',
            ),
            Tab(
              text: 'Unread (${_notificationService.unreadCount})',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationsList(_filteredNotifications),
                _buildNotificationsList(_unreadNotifications),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'All',
                    isSelected: _selectedFilter == null,
                    onTap: () {
                      setState(() {
                        _selectedFilter = null;
                      });
                    },
                  ),
                  const SizedBox(width: AppTheme.spaceXs),
                  ...NotificationType.values.map((type) => Padding(
                        padding: const EdgeInsets.only(right: AppTheme.spaceXs),
                        child: _buildFilterChip(
                          label: type.displayName,
                          isSelected: _selectedFilter == type,
                          onTap: () {
                            setState(() {
                              _selectedFilter = type;
                            });
                          },
                        ),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spaceSm),
          IconButton(
            icon: Icon(
              _showUnreadOnly ? Icons.visibility_off : Icons.visibility,
              color: _showUnreadOnly
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondaryColor,
            ),
            tooltip: _showUnreadOnly ? 'Show all' : 'Show unread only',
            onPressed: () {
              setState(() {
                _showUnreadOnly = !_showUnreadOnly;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceSm,
          vertical: AppTheme.spaceXs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsList(List<AppNotification> notifications) {
    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh notifications
        await _initializeNotifications();
      },
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
            child: ModernNotificationCard(
              notification: notification,
              onTap: () => _handleNotificationTap(notification),
              onMarkAsRead: () =>
                  _notificationService.markAsRead(notification.id),
              onDelete: () => _showDeleteDialog(notification),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 64,
            color: AppTheme.textSecondaryColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          Text(
            _tabController.index == 0
                ? 'No notifications yet'
                : 'No unread notifications',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
          const SizedBox(height: AppTheme.spaceXs),
          Text(
            _tabController.index == 0
                ? 'When you receive notifications, they\'ll appear here'
                : 'All caught up! No unread notifications',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    // Mark as read when tapped
    if (!notification.isRead) {
      _notificationService.markAsRead(notification.id);
    }

    // Handle action URL or navigation
    if (notification.actionUrl != null && mounted) {
      // Implement navigation based on actionUrl
      final actionUrl = notification.actionUrl!;

      try {
        // Parse the action URL to determine navigation
        if (actionUrl.startsWith('/profile/')) {
          // Navigate to profile screen
          final userId = actionUrl.replaceFirst('/profile/', '');
          Navigator.pushNamed(context, '/profile',
              arguments: {'userId': userId});
        } else if (actionUrl.startsWith('/achievement/')) {
          // Navigate to achievement details
          final achievementId = actionUrl.replaceFirst('/achievement/', '');
          Navigator.pushNamed(context, '/achievement',
              arguments: {'achievementId': achievementId});
        } else if (actionUrl.startsWith('/event/')) {
          // Navigate to event details
          final eventId = actionUrl.replaceFirst('/event/', '');
          Navigator.pushNamed(context, '/event',
              arguments: {'eventId': eventId});
        } else if (actionUrl.startsWith('/showcase/')) {
          // Navigate to showcase post
          final postId = actionUrl.replaceFirst('/showcase/', '');
          Navigator.pushNamed(context, '/showcase',
              arguments: {'postId': postId});
        } else {
          // Generic navigation or external URL
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Navigation to: ${notification.title}'),
              backgroundColor: AppTheme.infoColor,
            ),
          );
        }
      } catch (e) {
        // Fallback for invalid URLs
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to navigate: ${notification.title}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showDeleteDialog(AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content:
            const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _notificationService.deleteNotification(notification.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
            'Are you sure you want to clear all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _notificationService.clearAllNotifications();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const NotificationSettingsScreen(),
        ),
      );
    }
  }
}
