import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'APPOINTMENT':
        return Icons.calendar_today;
      case 'COURSE':
        return Icons.menu_book;
      case 'COMMUNITY':
        return Icons.people;
      case 'SYSTEM':
        return Icons.settings;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'APPOINTMENT':
        return Colors.blue;
      case 'COURSE':
        return Colors.orange;
      case 'COMMUNITY':
        return Colors.purple;
      case 'SYSTEM':
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (provider.notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                provider.markAllAsRead();
              },
              child: const Text('Mark all as read', style: TextStyle(color: AppColors.primary)),
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.notifications.isEmpty
              ? const Center(
                  child: Text('No notifications yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
                )
              : RefreshIndicator(
                  onRefresh: () => provider.fetchNotifications(),
                  child: ListView.builder(
                    itemCount: provider.notifications.length,
                    itemBuilder: (context, index) {
                      final notif = provider.notifications[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getColorForType(notif.type).withOpacity(0.2),
                          child: Icon(_getIconForType(notif.type), color: _getColorForType(notif.type)),
                        ),
                        title: Text(
                          notif.title,
                          style: TextStyle(
                            fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(notif.body),
                        trailing: notif.isRead
                            ? null
                            : Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                ),
                              ),
                        onTap: () {
                          if (!notif.isRead) {
                            provider.markAsRead(notif.id);
                          }
                          // Navigate to related object...
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
