import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;

  Dio get dio => _dio;

  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add Bearer token if available
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString(ApiConstants.accessTokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Handle 401 Unauthorized - token expired or invalid
          if (error.response?.statusCode == 401) {
            // Clear token and let the app handle navigation to login
            _clearToken();
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.accessTokenKey);
    await prefs.remove(ApiConstants.currentUserKey);
  }

  // Helper method to handle API errors
  static String getErrorMessage(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please check your internet connection.';
    } else if (error.type == DioExceptionType.connectionError) {
      return 'No internet connection. Please check your network.';
    } else if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;
      
      if (statusCode == 401) {
        return 'Unauthorized. Please login again.';
      } else if (statusCode == 404) {
        return 'Resource not found.';
      } else if (statusCode == 422) {
        // Handle validation errors
        if (data is Map<String, dynamic> && data.containsKey('detail')) {
          final detail = data['detail'];
          if (detail is List) {
            return detail.map((e) => e.toString()).join('\n');
          } else if (detail is String) {
            return detail;
          }
        }
        return 'Validation error. Please check your input.';
      } else if (statusCode != null && statusCode >= 500) {
        return 'Server error. Please try again later.';
      }
      
      // Try to extract error message from response
      if (data is Map<String, dynamic>) {
        if (data.containsKey('message')) {
          return data['message'] as String;
        } else if (data.containsKey('detail')) {
          return data['detail'].toString();
        }
      }
      
      return 'An error occurred: ${error.message}';
    }
    return 'An unexpected error occurred.';
  }
}

