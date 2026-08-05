import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static const String tokenKey = 'jwt_access_token';
  static const String refreshKey = 'jwt_refresh_token';

  static String _activeHost = 'https://ashwash-backend.onrender.com/api';
  static final List<String> _candidateHosts = [
    'https://ashwash-backend.onrender.com/api',
    'http://127.0.0.1:8000/api',
    'http://10.0.2.2:8000/api',
  ];

  static Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (requireAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(tokenKey);
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static String _buildUrl(String rawUrl, String host) {
    if (rawUrl.contains('/api/')) {
      final path = rawUrl.substring(rawUrl.indexOf('/api/') + 5);
      return '$host/$path';
    }
    return rawUrl;
  }

  static Future<dynamic> _executeWithFallback(
    String originalUrl,
    Future<http.Response> Function(String url, Map<String, String> headers) requestFn, {
    bool requireAuth = true,
  }) async {
    final headers = await _getHeaders(requireAuth: requireAuth);

    final primaryUrl = _buildUrl(originalUrl, _activeHost);
    http.Response? response;
    try {
      response = await requestFn(primaryUrl, headers).timeout(const Duration(seconds: 4));
    } catch (_) {
      for (final host in _candidateHosts) {
        if (host == _activeHost) continue;
        try {
          final fallbackUrl = _buildUrl(originalUrl, host);
          response = await requestFn(fallbackUrl, headers).timeout(const Duration(seconds: 4));
          _activeHost = host;
          ApiConfig.setCustomBaseUrl(host);
          break;
        } catch (_) {}
      }
    }

    if (response == null) {
      throw Exception('Server Connection Error. Ensure Django backend is running on port 8000.');
    }

    return _processResponse(response);
  }

  static Future<dynamic> get(String url, {bool requireAuth = true}) async {
    return _executeWithFallback(
      url,
      (targetUrl, headers) => http.get(Uri.parse(targetUrl), headers: headers),
      requireAuth: requireAuth,
    );
  }

  static Future<List<dynamic>> getList(String url, {bool requireAuth = true}) async {
    final res = await get(url, requireAuth: requireAuth);
    if (res is List) return res;
    if (res is Map && res.containsKey('results') && res['results'] is List) {
      return res['results'] as List<dynamic>;
    }
    return [];
  }

  static Future<dynamic> post(String url, Map<String, dynamic> body, {bool requireAuth = false}) async {
    return _executeWithFallback(
      url,
      (targetUrl, headers) => http.post(Uri.parse(targetUrl), headers: headers, body: jsonEncode(body)),
      requireAuth: requireAuth,
    );
  }

  static Future<dynamic> patch(String url, Map<String, dynamic> body, {bool requireAuth = true}) async {
    return _executeWithFallback(
      url,
      (targetUrl, headers) => http.patch(Uri.parse(targetUrl), headers: headers, body: jsonEncode(body)),
      requireAuth: requireAuth,
    );
  }

  static Future<dynamic> put(String url, Map<String, dynamic> body, {bool requireAuth = true}) async {
    return _executeWithFallback(
      url,
      (targetUrl, headers) => http.put(Uri.parse(targetUrl), headers: headers, body: jsonEncode(body)),
      requireAuth: requireAuth,
    );
  }

  static Future<dynamic> delete(String url, {bool requireAuth = true}) async {
    return _executeWithFallback(
      url,
      (targetUrl, headers) => http.delete(Uri.parse(targetUrl), headers: headers),
      requireAuth: requireAuth,
    );
  }

  static dynamic _processResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
      }
      throw Exception('Server Error (${response.statusCode})');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      if (body is Map) {
        if (body.containsKey('detail')) {
          final d = body['detail'];
          if (d is List && d.isNotEmpty) throw Exception(d.first.toString());
          throw Exception(d.toString());
        }
        if (body.containsKey('error')) throw Exception(body['error'].toString());
        if (body.containsKey('message')) throw Exception(body['message'].toString());
        if (body.containsKey('non_field_errors')) {
          final errs = body['non_field_errors'];
          if (errs is List && errs.isNotEmpty) throw Exception(errs.first.toString());
        }
        for (var key in body.keys) {
          final val = body[key];
          if (val is List && val.isNotEmpty) {
            throw Exception('$key: ${val.first}');
          }
        }
      }
      throw Exception('API error occurred (${response.statusCode})');
    }
  }
}
