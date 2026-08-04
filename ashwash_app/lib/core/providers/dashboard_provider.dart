import 'package:flutter/material.dart';
import '../network/api_endpoints.dart';
import '../network/api_service.dart';

class DashboardProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  String _userName = 'User';
  String _userCategory = 'First Time Mother';
  int _selectedMoodIndex = -1; // -1 means none selected today yet

  int _courseProgressPercent = 43;
  int _sessionsAttended = 5;
  int _tasksCompleted = 1;
  int _pointsEarned = 450;

  List<Map<String, dynamic>> _enrolledCourses = [];
  bool _hasUnreadNotifications = true;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get userName => _userName;
  String get userCategory => _userCategory;
  int get selectedMoodIndex => _selectedMoodIndex;

  int get courseProgressPercent => _courseProgressPercent;
  int get sessionsAttended => _sessionsAttended;
  int get tasksCompleted => _tasksCompleted;
  int get pointsEarned => _pointsEarned;

  List<Map<String, dynamic>> get enrolledCourses => _enrolledCourses;
  bool get hasUnreadNotifications => _hasUnreadNotifications;

  final List<Map<String, dynamic>> moodOptions = [
    {'emoji': '😡', 'label': 'Distressed', 'color': const Color(0xFFEF4444)},
    {'emoji': '🙁', 'label': 'Sad', 'color': const Color(0xFFF97316)},
    {'emoji': '😐', 'label': 'Neutral', 'color': const Color(0xFFF59E0B)},
    {'emoji': '🙂', 'label': 'Happy', 'color': const Color(0xFF10B981)},
    {'emoji': '😄', 'label': 'Super Happy', 'color': const Color(0xFF8B5CF6)},
  ];

  DashboardProvider() {
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await ApiService.get(ApiEndpoints.dashboardOverview, requireAuth: true);
      _userName = data['user_name'] ?? 'User';
      _userCategory = data['category'] ?? 'First Time Mother';
      _hasUnreadNotifications = data['has_unread_notifications'] ?? true;

      if (data['metrics'] != null) {
        _courseProgressPercent = data['metrics']['overall_course_progress'] ?? 43;
        _sessionsAttended = data['metrics']['sessions_attended'] ?? 5;
        _tasksCompleted = data['metrics']['tasks_completed'] ?? 1;
        _pointsEarned = data['metrics']['points_earned'] ?? 450;
      }

      if (data['enrolled_courses'] != null) {
        _enrolledCourses = List<Map<String, dynamic>>.from(data['enrolled_courses']);
      }
    } catch (e) {
      _errorMessage = e.toString();
      // Fallback default values matching Figma prototype screenshots
      _enrolledCourses = [
        {
          'id': 1,
          'title': 'Postpartum Depression Recovery Program',
          'description': 'Comprehensive 6-week guided recovery for new mothers covering symptoms, bonding, and coping.',
          'completed_lessons': 2,
          'total_lessons': 17,
          'progress_percentage': 25,
          'format': 'Both',
        },
      ];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectMood(int index) {
    _selectedMoodIndex = index;
    notifyListeners();
  }
}
