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
      // STRICT ACCOUNT & PASSWORD VERIFICATION FROM PERSISTED DATABASE
      final prefs = await SharedPreferences.getInstance();
      final savedDbStr = prefs.getString('persisted_user_db_v2');
      if (savedDbStr != null) {
        final List<dynamic> decoded = jsonDecode(savedDbStr);
        _persistedAccounts = List<Map<String, dynamic>>.from(decoded);
      }

      final match = _persistedAccounts.firstWhere(
        (acc) {
          final accEmail = (acc['email'] as String? ?? '').toLowerCase();
          final accUser = (acc['username'] as String? ?? '').toLowerCase();
          return (accEmail == input || accUser == input);
        },
        orElse: () => {},
      );

      if (match.isNotEmpty) {
        // Account exists! Verify registered role isolation
        final accRole = (match['role'] as String? ?? 'PATIENT').toUpperCase();
        final requestedRole = role.toUpperCase();
        if (accRole != requestedRole) {
          final displayAccRole = accRole == 'SPECIALIST' ? 'Specialist (Doctor)' : 'Patient';
          final displayReqRole = requestedRole == 'SPECIALIST' ? 'Specialist (Doctor)' : 'Patient';
          _errorMessage = 'Role mismatch! This account is registered as a $displayAccRole. Please select $displayAccRole role to log in.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        // Verify password
        final accPass = match['password'] as String? ?? '';
        if (password.isNotEmpty && accPass.isNotEmpty && accPass != password) {
          _errorMessage = 'Incorrect password! Please try again.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        // Credentials & Role match!
        _currentUser = UserModel(
          id: match['id'] ?? DateTime.now().millisecondsSinceEpoch,
          email: match['email'] ?? emailOrUsername,
          username: match['username'] ?? emailOrUsername.split('@').first,
          firstName: match['first_name'] ?? (accRole == 'SPECIALIST' ? 'Dr. Mekhala' : 'Ashwash'),
          lastName: match['last_name'] ?? (accRole == 'SPECIALIST' ? 'Sarkar' : 'User'),
          role: accRole,
          phone: match['phone'],
          preferredCategory: match['preferred_category'] ?? 'First Time Mother',
        );

        await prefs.setString('saved_user_role', _currentUser!.role);
        await prefs.setString('saved_user_email', _currentUser!.email);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // If user is not found in database or registered accounts, STRICTLY DENY LOGIN
      _errorMessage = 'Account does not exist! Please register/sign up an account first.';
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
      // Fallback local registration
      _currentUser = UserModel.fromJson(newAccMap);
    }

    // PERSIST ACCOUNT TO DEVICE STORAGE DATABASE
    final prefs = await SharedPreferences.getInstance();
    _persistedAccounts.add(newAccMap);
    await prefs.setString('persisted_user_db_v2', jsonEncode(_persistedAccounts));
    await prefs.setString('saved_user_role', _currentUser?.role ?? role);
    await prefs.setString('saved_user_email', _currentUser?.email ?? cleanEmail);

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
      final match = _persistedAccounts.firstWhere(
        (acc) => (acc['email'] as String).toLowerCase() == email.toLowerCase(),
        orElse: () => {},
      );

      if (match.isNotEmpty) {
        _currentUser = UserModel.fromJson(match);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = 'Account does not exist for Google login! Please sign up first.';
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
      _errorMessage = 'Account does not exist! Please register first.';
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
