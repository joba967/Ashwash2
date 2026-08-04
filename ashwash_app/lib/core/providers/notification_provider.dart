import 'package:flutter/material.dart';
import '../network/api_service.dart';

class NotificationItem {
  final String id;
  final String titleEn;
  final String titleBn;
  final String bodyEn;
  final String bodyBn;
  final DateTime timestamp;
  bool isRead;
  final String category; // 'REMINDER', 'SYSTEM', 'COMMUNITY', 'COURSE'

  NotificationItem({
    required this.id,
    required this.titleEn,
    required this.titleBn,
    required this.bodyEn,
    required this.bodyBn,
    required this.timestamp,
    this.isRead = false,
    required this.category,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    DateTime parsedTime;
    try {
      parsedTime = DateTime.parse(json['created_at']);
    } catch (_) {
      parsedTime = DateTime.now();
    }

    return NotificationItem(
      id: json['id']?.toString() ?? '0',
      titleEn: json['title_en']?.toString() ?? '',
      titleBn: json['title_bn']?.toString() ?? json['title_en']?.toString() ?? '',
      bodyEn: json['message_en']?.toString() ?? '',
      bodyBn: json['message_bn']?.toString() ?? json['message_en']?.toString() ?? '',
      timestamp: parsedTime,
      isRead: json['is_read'] == true,
      category: json['category']?.toString() ?? 'SYSTEM',
    );
  }
}

class NotificationProvider with ChangeNotifier {
  List<NotificationItem> _notifications = [
    NotificationItem(
      id: 'n1',
      titleEn: 'Daily Mood Tracking Reminder 🌸',
      titleBn: 'দৈনন্দিন মুড ট্র্যাকের রিমাইন্ডার 🌸',
      bodyEn: 'Take 30 seconds to reflect and record how you are feeling today.',
      bodyBn: 'আজ আপনার মনের অনুভূতি কেমন তা রেকর্ড করতে ৩০ সেকেন্ড সময় নিন।',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      isRead: false,
      category: 'REMINDER',
    ),
    NotificationItem(
      id: 'n2',
      titleEn: 'New Course Assignment Unlocked 📚',
      titleBn: 'নতুন কোর্স অ্যাসাইনমেন্ট আনলক হয়েছে 📚',
      bodyEn: 'Module 2: Self-Care & Gratitude Journaling is now available in your Postpartum Recovery Program.',
      bodyBn: 'আপনার পোস্টপার্টাম রিকভারি প্রোগ্রামে মডিউল ২ আনলক হয়েছে।',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      category: 'COURSE',
    ),
  ];

  String _selectedFilter = 'ALL';
  bool _isLoading = false;

  NotificationProvider() {
    fetchNotifications();
  }

  bool get isLoading => _isLoading;

  List<NotificationItem> get notifications {
    if (_selectedFilter == 'ALL') {
      return List.unmodifiable(_notifications);
    }
    return List.unmodifiable(_notifications.where((n) => n.category == _selectedFilter));
  }

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  String get selectedFilter => _selectedFilter;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.getList('http://127.0.0.1:8000/api/notifications/', requireAuth: true);
      if (res.isNotEmpty) {
        final List<NotificationItem> apiItems = [];
        for (var item in res) {
          if (item is Map<String, dynamic>) {
            apiItems.add(NotificationItem.fromJson(item));
          } else if (item is Map) {
            apiItems.add(NotificationItem.fromJson(Map<String, dynamic>.from(item)));
          }
        }
        if (apiItems.isNotEmpty) {
          _notifications = apiItems;
        }
      }
    } catch (_) {
      // Retain fallback list on network error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(String category) {
    _selectedFilter = category;
    notifyListeners();
  }

  void markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
      try {
        await ApiService.post('http://127.0.0.1:8000/api/notifications/$id/read/', {}, requireAuth: true);
      } catch (_) {}
    }
  }

  void markAllAsRead() async {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
    try {
      await ApiService.post('http://127.0.0.1:8000/api/notifications/read-all/', {}, requireAuth: true);
    } catch (_) {}
  }

  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}
