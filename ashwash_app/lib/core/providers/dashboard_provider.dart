import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    _loadLocalEnrolledCourses();
    fetchDashboardData();
  }

  Future<void> _loadLocalEnrolledCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString('persisted_enrolled_courses_v2');
      if (savedStr != null) {
        final List<dynamic> decoded = jsonDecode(savedStr);
        _enrolledCourses = List<Map<String, dynamic>>.from(decoded);
        notifyListeners();
      }
    } catch (_) {}
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

      if (data['enrolled_courses'] != null && (data['enrolled_courses'] as List).isNotEmpty) {
        final fetched = List<Map<String, dynamic>>.from(data['enrolled_courses']);
        for (var c in fetched) {
          if (!_enrolledCourses.any((item) => item['id'] == c['id'] || item['title'] == c['title'])) {
            _enrolledCourses.add(c);
          }
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isCourseEnrolled(dynamic courseId, String courseTitle) {
    return _enrolledCourses.any((c) =>
      c['id'].toString() == courseId.toString() ||
      c['title'].toString().trim().toLowerCase() == courseTitle.trim().toLowerCase()
    );
  }

  Future<void> enrollCourse(Map<String, dynamic> courseData) async {
    final courseId = courseData['id'];
    if (!isCourseEnrolled(courseId, courseData['title'] ?? '')) {
      _enrolledCourses.insert(0, courseData);
      notifyListeners();

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('persisted_enrolled_courses_v2', jsonEncode(_enrolledCourses));
      } catch (_) {}

      try {
        await ApiService.post('/api/courses/enroll/', {
          'course_id': courseId,
          'course_title': courseData['title'],
        }, requireAuth: true);
      } catch (_) {}
    }
  }

  void selectMood(int index) {
    _selectedMoodIndex = index;
    notifyListeners();
  }
}
