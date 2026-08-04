import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_language_provider.dart';
import '../../core/providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  String _formatTime(DateTime dt, bool isBn) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return isBn ? '${diff.inMinutes} মিনিট আগে' : '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return isBn ? '${diff.inHours} ঘণ্টা আগে' : '${diff.inHours}h ago';
    } else {
      return isBn ? '${diff.inDays} দিন আগে' : '${diff.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<AppLanguageProvider>(context);
    final isBn = langProvider.isBangla;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifProvider = Provider.of<NotificationProvider>(context);

    final categories = [
      {'key': 'ALL', 'labelEn': 'All', 'labelBn': 'সব'},
      {'key': 'REMINDER', 'labelEn': 'Reminders', 'labelBn': 'রিমাইন্ডার'},
      {'key': 'COURSE', 'labelEn': 'Courses', 'labelBn': 'কোর্স'},
      {'key': 'SYSTEM', 'labelEn': 'System', 'labelBn': 'সিস্টেম'},
      {'key': 'COMMUNITY', 'labelEn': 'Community', 'labelBn': 'কমিউনিটি'},
    ];

    final items = notifProvider.notifications;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          isBn ? 'নোটিফিকেশন' : 'Notifications',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          if (notifProvider.unreadCount > 0)
            TextButton(
              onPressed: () => notifProvider.markAllAsRead(),
              child: Text(
                isBn ? 'সব পড়া হয়েছে' : 'Mark all read',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? AppColors.darkSurface : Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = notifProvider.selectedFilter == cat['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(isBn ? cat['labelBn']! : cat['labelEn']!),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    onSelected: (_) => notifProvider.setFilter(cat['key']!),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),

          // Notifications List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => notifProvider.fetchNotifications(),
              child: items.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: 400,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 64,
                              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isBn ? 'কোনো নোটিফিকেশন নেই' : 'No notifications available',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                      final item = items[index];
                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                        ),
                        onDismissed: (_) {
                          notifProvider.deleteNotification(item.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isBn ? 'নোটিফিকেশন মুছে ফেলা হয়েছে' : 'Notification removed'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: GestureDetector(
                          onTap: () {
                            notifProvider.markAsRead(item.id);
                            _showNotificationDetailModal(context, item, isBn, isDark);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: item.isRead
                                  ? (isDark ? AppColors.darkSurface : Colors.white)
                                  : (isDark ? Colors.indigo.shade900.withOpacity(0.3) : const Color(0xFFF0F9FF)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: item.isRead
                                    ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
                                    : AppColors.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _getCategoryIcon(item.category),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              isBn ? item.titleBn : item.titleEn,
                                              style: TextStyle(
                                                fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                                                fontSize: 15,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                            ),
                                          ),
                                          if (!item.isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: AppColors.primary,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        isBn ? item.bodyBn : item.bodyEn,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _formatTime(item.timestamp, isBn),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getCategoryIcon(String category) {
    IconData icon;
    Color color;
    switch (category) {
      case 'REMINDER':
        icon = Icons.alarm_rounded;
        color = Colors.orange;
        break;
      case 'COURSE':
        icon = Icons.school_rounded;
        color = AppColors.primary;
        break;
      case 'COMMUNITY':
        icon = Icons.forum_rounded;
        color = Colors.purple;
        break;
      default:
        icon = Icons.notifications_active_rounded;
        color = Colors.teal;
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withOpacity(0.15),
      child: Icon(icon, color: color, size: 20),
    );
  }

  void _showNotificationDetailModal(BuildContext context, NotificationItem item, bool isBn, bool isDark) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _getCategoryIcon(item.category),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isBn ? item.titleBn : item.titleEn,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isBn ? item.bodyBn : item.bodyEn,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  isBn ? 'বন্ধ করুন' : 'Close',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
