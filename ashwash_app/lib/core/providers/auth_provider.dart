import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_endpoints.dart';
import '../network/api_service.dart';
import '../../data/models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isFirstTimeUser = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get errorMessage => _errorMessage;
  bool get isFirstTimeUser => _isFirstTimeUser;

  AuthProvider() {
    _loadUserFromStorage();
  }

  Future<void> _loadUserFromStorage() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiService.tokenKey);
      final savedEmail = prefs.getString('saved_user_email');

      if (token != null) {
        try {
          final profileData = await ApiService.get(ApiEndpoints.profile, requireAuth: true);
          _currentUser = UserModel.fromJson(profileData);
        } catch (_) {}
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
    _isFirstTimeUser = false;
    notifyListeners();

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
    _isFirstTimeUser = true;
    notifyListeners();

    final cleanEmail = email.trim().toLowerCase();
    final cleanUsername = (username != null && username.trim().isNotEmpty) ? username.trim() : cleanEmail.split('@').first;

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

  Future<Map<String, dynamic>> loginWithGoogleDirect({required String email, required String name, String? photoUrl}) async {
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

      final bool isNewUser = data['is_new_user'] ?? false;
      _isFirstTimeUser = isNewUser;

      if (data['user'] != null) {
        _currentUser = UserModel.fromJson(data['user']);
      } else {
        await fetchProfile();
      }

      await prefs.setString('saved_user_role', 'PATIENT');
      await prefs.setString('saved_user_email', email);

      _isLoading = false;
      notifyListeners();
      return {'success': true, 'isNewUser': isNewUser, 'cancelled': false};
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'isNewUser': false, 'cancelled': false, 'error': _errorMessage};
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'isNewUser': false, 'cancelled': true};
      }

      return await loginWithGoogleDirect(
        email: googleUser.email,
        name: googleUser.displayName ?? 'Google User',
        photoUrl: googleUser.photoUrl ?? '',
      );
    } catch (e) {
      debugPrint("Google Native Sign-In SDK Note (Developer SHA-1 / ApiException): $e");
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'isNewUser': false, 'cancelled': false, 'fallback': true, 'error': e.toString()};
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

  Future<bool> setCategoryPreferences(List<String> categoryIds) async {
    try {
      await ApiService.post(
        ApiEndpoints.categoryPreference,
        {'category_ids': categoryIds},
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
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiService.tokenKey);
    await prefs.remove(ApiService.refreshKey);
    await prefs.remove('saved_user_role');
    await prefs.remove('saved_user_email');
    _currentUser = null;
    notifyListeners();
  }
}
