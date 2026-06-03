import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../core/api_config.dart';

class AuthService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // Storage keys
  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _accessExpiryKey = 'auth_access_expiry';
  static const String _refreshExpiryKey = 'auth_refresh_expiry';
  static const String _userKey = 'user_data';
  static Future<bool>? _refreshingToken;

  // ─── Register ─────────────────────────────────

  static Future<AuthToken> register({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/register',
        data: {
          'email': email,
          'password': password,
          if (name != null) 'name': name,
        },
      );

      final token = AuthToken.fromJson(response.data);
      await _saveToken(token);
      return token;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Login ────────────────────────────────────

  static Future<AuthToken> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final token = AuthToken.fromJson(response.data);
      await _saveToken(token);
      return token;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Get Current User ─────────────────────────

  static Future<User> getCurrentUser() async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await _dio.get(
        '/api/auth/me',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Logout ───────────────────────────────────

  static Future<void> logout() async {
    try {
      final token = await getToken();
      final refreshToken = await _getRefreshToken();
      if (token != null) {
        await _dio.post(
          '/api/auth/logout',
          data: refreshToken != null ? {'refresh_token': refreshToken} : null,
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
      }
    } catch (e) {
      // Ignore logout errors
    } finally {
      await _clearToken();
    }
  }

  // ─── Token Management ─────────────────────────

  static Future<void> _saveToken(AuthToken token) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setString(_accessTokenKey, token.accessToken);
    await prefs.setString(_refreshTokenKey, token.refreshToken);
    await prefs.setInt(
      _accessExpiryKey,
      now.add(Duration(seconds: token.accessExpiresIn)).millisecondsSinceEpoch,
    );
    await prefs.setInt(
      _refreshExpiryKey,
      now.add(Duration(seconds: token.refreshExpiresIn)).millisecondsSinceEpoch,
    );
    await prefs.setString(
        _userKey,
        jsonEncode({
          'user_id': token.userId,
          'email': token.email,
          'name': token.name,
        }));
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  static Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  static Future<bool> _isAccessTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryMs = prefs.getInt(_accessExpiryKey);
    if (expiryMs == null) return true;
    final now = DateTime.now().millisecondsSinceEpoch;
    return now >= (expiryMs - 15000);
  }

  static Future<bool> _isRefreshTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryMs = prefs.getInt(_refreshExpiryKey);
    if (expiryMs == null) return true;
    final now = DateTime.now().millisecondsSinceEpoch;
    return now >= (expiryMs - 15000);
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    return jsonDecode(userJson);
  }

  static Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_accessExpiryKey);
    await prefs.remove(_refreshExpiryKey);
    await prefs.remove(_userKey);
  }

  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    if (token == null) return false;
    if (!await _isAccessTokenExpired()) return true;
    return refreshAccessToken();
  }

  static Future<bool> refreshAccessToken() async {
    if (_refreshingToken != null) {
      return _refreshingToken!;
    }

    _refreshingToken = _doRefreshAccessToken();
    final result = await _refreshingToken!;
    _refreshingToken = null;
    return result;
  }

  static Future<bool> _doRefreshAccessToken() async {
    try {
      if (await _isRefreshTokenExpired()) {
        await _clearToken();
        return false;
      }

      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) {
        await _clearToken();
        return false;
      }

      final response = await _dio.post(
        '/api/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final token = AuthToken.fromJson(response.data);
      await _saveToken(token);
      return true;
    } on DioException {
      await _clearToken();
      return false;
    } catch (_) {
      await _clearToken();
      return false;
    }
  }

  static Future<Response<T>> authorizedRequest<T>({
    required String method,
    required String path,
    Map<String, dynamic>? queryParameters,
    dynamic data,
    ResponseType? responseType,
    bool retryOnUnauthorized = true,
  }) async {
    String? token = await getToken();
    if (token == null || await _isAccessTokenExpired()) {
      final refreshed = await refreshAccessToken();
      if (!refreshed) {
        throw 'Authentication required';
      }
      token = await getToken();
    }

    try {
      return await _dio.request<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          method: method,
          headers: {'Authorization': 'Bearer $token'},
          responseType: responseType,
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && retryOnUnauthorized) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          return authorizedRequest<T>(
            method: method,
            path: path,
            queryParameters: queryParameters,
            data: data,
            responseType: responseType,
            retryOnUnauthorized: false,
          );
        }
      }
      throw _handleError(e);
    }
  }

  // ─── Error Handling ───────────────────────────

  static String _handleError(DioException e) {
    if (e.response?.data != null) {
      try {
        final data = e.response!.data;
        if (data is Map && data['detail'] != null) {
          return data['detail'].toString();
        }
      } catch (_) {}
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please try again.';
      case DioExceptionType.badResponse:
        if (e.response?.statusCode == 401) {
          return 'Invalid email or password';
        }
        if (e.response?.statusCode == 400) {
          return 'Invalid request. Please check your input.';
        }
        return 'Server error. Please try again later.';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      default:
        return 'Network error. Please check your connection.';
    }
  }
}
