import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_endpoints.dart';
import '../network/api_service.dart';
import '../../data/models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Local registered user database
  List<Map<String, dynamic>> _persistedAccounts = [
    {
      'id': 1,
      'email': 'doctor@ashwash.com',
      'username': 'doctor',
      'password': 'password123',
      'first_name': 'Dr. Mekhala',
      'last_name': 'Sarkar',
      'role': 'SPECIALIST',
      'preferred_category': 'Postpartum Depression',
    },
    {
      'id': 2,
      'email': 'patient@ashwash.com',
      'username': 'patient',
      'password': 'password123',
      'first_name': 'Nusrat',
      'last_name': 'Sultana',
      'role': 'PATIENT',
      'preferred_category': 'First Time Mother',
    },
  ];

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _loadUserFromStorage();
  }

  Future<void> _loadUserFromStorage() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDbStr = prefs.getString('persisted_user_db_v2');
      if (savedDbStr != null) {
        final List<dynamic> decoded = jsonDecode(savedDbStr);
        _persistedAccounts = List<Map<String, dynamic>>.from(decoded);
      } else {
        await prefs.setString('persisted_user_db_v2', jsonEncode(_persistedAccounts));
      }

      final token = prefs.getString(ApiService.tokenKey);
      final savedEmail = prefs.getString('saved_user_email');
      final savedRole = prefs.getString('saved_user_role');

      if (token != null) {
        try {
          final profileData = await ApiService.get(ApiEndpoints.profile, requireAuth: true);
          _currentUser = UserModel.fromJson(profileData);
        } catch (_) {}
      }

      if (_currentUser == null && savedEmail != null) {
        final found = _persistedAccounts.firstWhere(
          (acc) => (acc['email'] as String).toLowerCase() == savedEmail.toLowerCase(),
          orElse: () => {},
        );
        if (found.isNotEmpty) {
          _currentUser = UserModel.fromJson(found);
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String emailOrUsername, String password, {String role = 'PATIENT'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final input = emailOrUsername.trim().toLowerCase();

    try {
      final data = await ApiService.post(ApiEndpoints.login, {
        'username': emailOrUsername,
        'email': emailOrUsername,
        'password': password,
        'role': role,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ApiService.tokenKey, data['access']);
      await prefs.setString(ApiService.refreshKey, data['refresh']);

      if (data['user'] != null) {
        _currentUser = UserModel.fromJson(data['user']);
      } else {
        await fetchProfile();
      }

      await prefs.setString('saved_user_role', _currentUser?.role ?? role);
      await prefs.setString('saved_user_email', _currentUser?.email ?? emailOrUsername);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    String? username,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final cleanEmail = email.trim().toLowerCase();
    final cleanUsername = (username != null && username.trim().isNotEmpty) ? username.trim() : cleanEmail.split('@').first;

    final newAccMap = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'email': cleanEmail,
      'username': cleanUsername,
      'password': password,
      'first_name': firstName.isEmpty ? (role == 'SPECIALIST' ? 'Dr. Mekhala' : 'Ashwash') : firstName,
      'last_name': lastName,
      'role': role,
      'preferred_category': 'First Time Mother',
    };

    try {
      final data = await ApiService.post(ApiEndpoints.register, {
        'email': cleanEmail,
        'username': cleanUsername,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'role': role,
      });

      final prefs = await SharedPreferences.getInstance();
      if (data['access'] != null) {
        await prefs.setString(ApiService.tokenKey, data['access']);
        await prefs.setString(ApiService.refreshKey, data['refresh']);
      }

      if (data['user'] != null) {
        _currentUser = UserModel.fromJson(data['user']);
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> loginWithGoogle({required String email, required String name, String? photoUrl}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await ApiService.post(ApiEndpoints.googleAuth, {
        'email': email,
        'name': name,
        'profile_picture': photoUrl ?? '',
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ApiService.tokenKey, data['access']);
      await prefs.setString(ApiService.refreshKey, data['refresh']);

      if (data['user'] != null) {
        _currentUser = UserModel.fromJson(data['user']);
      } else {
        await fetchProfile();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithFacebook({required String email, required String name, String? photoUrl}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await ApiService.post(ApiEndpoints.facebookAuth, {
        'email': email,
        'name': name,
        'profile_picture': photoUrl ?? '',
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ApiService.tokenKey, data['access']);
      await prefs.setString(ApiService.refreshKey, data['refresh']);

      if (data['user'] != null) {
        _currentUser = UserModel.fromJson(data['user']);
      } else {
        await fetchProfile();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchProfile() async {
    try {
      final data = await ApiService.get(ApiEndpoints.profile, requireAuth: true);
      _currentUser = UserModel.fromJson(data);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  Future<bool> setCategoryPreference(String categoryId) async {
    try {
      await ApiService.post(
        ApiEndpoints.categoryPreference,
        {'category': categoryId},
        requireAuth: true,
      );
      await fetchProfile();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiService.tokenKey);
    await prefs.remove(ApiService.refreshKey);
    await prefs.remove('saved_user_role');
    await prefs.remove('saved_user_email');
    _currentUser = null;
    notifyListeners();
  }
}
