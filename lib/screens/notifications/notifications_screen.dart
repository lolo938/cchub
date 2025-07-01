import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/notification_service.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final notificationsAsync = ref.watch(currentUserNotificationsProvider);
    final filter = ref.watch(notificationTypeFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          // Filter menu
          PopupMenuButton<NotificationType?>(
            icon: Icon(
              Icons.filter_list,
              color: filter != null ? AppColors.primary : null,
            ),
            onSelected: (value) {
              ref.read(notificationTypeFilterProvider.notifier).state = value;
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All Notifications'),
              ),
              const PopupMenuItem(
                value: NotificationType.consultation,
                child: Text('Consultations'),
              ),
              const PopupMenuItem(
                value: NotificationType.appointment,
                child: Text('Appointments'),
              ),
              const PopupMenuItem(
                value: NotificationType.reminder,
                child: Text('Reminders'),
              ),
              const PopupMenuItem(
                value: NotificationType.general,
                child: Text('General'),
              ),
            ],
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          final filteredNotifications = ref.watch(filteredNotificationsProvider(notifications));
          final stats = ref.watch(notificationStatsProvider(notifications));
          
          return Column(
            children: [
              // Stats header
              _buildStatsHeader(stats),
              
              // Notifications list
              Expanded(
                child: filteredNotifications.isEmpty
                    ? _buildEmptyState(filter)
                    : _buildNotificationsList(filteredNotifications, user?.uid),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildStatsHeader(Map<String, int> stats) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Total',
              stats['total'].toString(),
              AppColors.primary,
              Icons.notifications,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Unread',
              stats['unread'].toString(),
              AppColors.warning,
              Icons.notifications_active,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Today',
              stats['today'].toString(),
              AppColors.success,
              Icons.today,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: AppSizes.spacingSmall),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsList(List<Map<String, dynamic>> notifications, String? userId) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(currentUserNotificationsProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.paddingSmall),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationItem(notification, userId);
        },
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification, String? userId) {
    final isRead = notification['isRead'] ?? false;
    final type = notification['type'] as String? ?? 'general';
    final title = notification['title'] as String? ?? 'Notification';
    final body = notification['body'] as String? ?? '';
    final receivedAt = notification['receivedAt'];
    final notificationId = notification['id'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingSmall),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        border: Border.all(
          color: isRead ? Colors.grey.shade200 : AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: _buildNotificationIcon(type, isRead),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (body.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                body,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _formatNotificationTime(receivedAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: !isRead 
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () {
          if (!isRead && userId != null) {
            _markAsRead(userId, notificationId);
          }
          _handleNotificationTap(notification);
        },
      ),
    );
  }

  Widget _buildNotificationIcon(String type, bool isRead) {
    IconData iconData;
    Color color;

    switch (type) {
      case 'consultation':
        iconData = Icons.video_call;
        color = AppColors.consultation;
        break;
      case 'appointment':
        iconData = Icons.calendar_today;
        color = AppColors.primary;
        break;
      case 'reminder':
        iconData = Icons.access_time;
        color = AppColors.warning;
        break;
      case 'urgent':
        iconData = Icons.priority_high;
        color = AppColors.error;
        break;
      default:
        iconData = Icons.notifications;
        color = AppColors.secondary;
    }

    if (isRead) {
      color = color.withOpacity(0.6);
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      child: Icon(iconData, color: color, size: 24),
    );
  }

  Widget _buildEmptyState(NotificationType? filter) {
    String message = filter != null 
        ? 'No ${filter.name} notifications found'
        : 'No notifications yet';
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: AppSizes.spacingMedium),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: AppSizes.spacingSmall),
          Text(
            'Your notifications will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
          if (filter != null) ...[
            const SizedBox(height: AppSizes.spacingMedium),
            TextButton(
              onPressed: () {
                ref.read(notificationTypeFilterProvider.notifier).state = null;
              },
              child: const Text('Show All Notifications'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: AppSizes.spacingMedium),
          Text(
            'Unable to load notifications',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: AppSizes.spacingSmall),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.spacingMedium),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(currentUserNotificationsProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _markAsRead(String userId, String notificationId) {
    ref.read(notificationControllerProvider.notifier).markAsRead(userId, notificationId);
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final data = notification['data'] as Map<String, dynamic>?;
    final route = data?['route'] as String?;
    
    if (route != null) {
      // Navigate to the specified route
      // This would typically use GoRouter context.go(route)
      print('Navigate to: $route');
    }
  }

  String _formatNotificationTime(dynamic receivedAt) {
    if (receivedAt == null) return 'Unknown time';

    DateTime time;
    try {
      if (receivedAt is DateTime) {
        time = receivedAt;
      } else {
        time = receivedAt.toDate();
      }
    } catch (e) {
      return 'Unknown time';
    }

    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}