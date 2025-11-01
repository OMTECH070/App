import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../l10n/app_localizations.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationProvider>().fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final notificationProvider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('notifications') ?? 'Notifications'),
      ),
      body: Column(
        children: [
          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFilterChip(context, 'all', loc),
                const SizedBox(width: 8),
                _buildFilterChip(context, 'critical', loc),
                const SizedBox(width: 8),
                _buildFilterChip(context, 'warning', loc),
              ],
            ),
          ),

          // Notifications List
          Expanded(
            child: notificationProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : notificationProvider.notifications.isEmpty
                    ? Center(
                        child: Text(
                          loc?.translate('loading') ?? 'No notifications',
                        ),
                      )
                    : ListView.builder(
                        itemCount: notificationProvider.notifications.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final notification =
                              notificationProvider.notifications[index];
                          return _buildNotificationCard(
                            context,
                            notification,
                            loc,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String type, AppLocalizations? loc) {
    final notificationProvider = context.read<NotificationProvider>();
    final isSelected = notificationProvider.filterType == type;

    return FilterChip(
      label: Text(loc?.translate(type) ?? type),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          notificationProvider.fetchNotifications(type: type);
        }
      },
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    Map<String, dynamic> notification,
    AppLocalizations? loc,
  ) {
    final type = notification['type'] as String? ?? 'info';
    final color = _getNotificationColor(type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(notification['id']),
        onDismissed: (_) {
          context.read<NotificationProvider>().deleteNotification(
            notification['id'],
          );
        },
        child: ListTile(
          leading: Container(
            width: 4,
            color: color,
          ),
          title: Text(
            notification['title'] ?? 'Notification',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification['message'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(notification['created_at']),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          trailing: !notification['is_read']
              ? Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                )
              : null,
          onTap: () {
            if (!notification['is_read']) {
              context.read<NotificationProvider>().markAsRead(
                notification['id'],
              );
            }
          },
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'success':
        return Colors.green;
      case 'info':
      default:
        return Colors.blue;
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final dateTime = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final diff = now.difference(dateTime);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (e) {
      return 'Unknown';
    }
  }
}
