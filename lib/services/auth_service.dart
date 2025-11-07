import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  // Register a new user
  Future<User> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.dio.post(
        ApiConstants.authRegister,
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
      );

      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(ApiService.getErrorMessage(e));
    }
  }

  // Login and get access token
  Future<String> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.dio.post(
        ApiConstants.authLogin,
        data: FormData.fromMap({
          'username': email, // API uses 'username' field but expects email
          'password': password,
        }),
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['access_token'] as String;

      // Save token to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ApiConstants.accessTokenKey, token);

      return token;
    } on DioException catch (e) {
      throw Exception(ApiService.getErrorMessage(e));
    }
  }

  // Get current user
  Future<User> getCurrentUser() async {
    try {
      final response = await _apiService.dio.get(ApiConstants.authMe);
      final user = User.fromJson(response.data as Map<String, dynamic>);

      // Cache user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        ApiConstants.currentUserKey,
        user.toJson().toString(),
      );

      return user;
    } on DioException catch (e) {
      throw Exception(ApiService.getErrorMessage(e));
    }
  }

  // Logout (clear token)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.accessTokenKey);
    await prefs.remove(ApiConstants.currentUserKey);
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(ApiConstants.accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  // Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.accessTokenKey);
  }
}

