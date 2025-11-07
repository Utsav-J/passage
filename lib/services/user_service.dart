import 'package:dio/dio.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class UserService {
  final ApiService _apiService = ApiService();

  // Search users by username or email
  Future<List<User>> searchUsers(String query) async {
    try {
      final response = await _apiService.dio.get(
        ApiConstants.usersSearch,
        queryParameters: {'query': query},
      );
      final data = response.data as List<dynamic>;
      return data
          .map((json) => User.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(ApiService.getErrorMessage(e));
    }
  }
}

