import 'package:dio/dio.dart';
import '../models/mate.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class MateService {
  final ApiService _apiService = ApiService();

  // Get all accepted mates for the current user
  Future<List<Mate>> getMates() async {
    try {
      final response = await _apiService.dio.get(ApiConstants.mates);
      final data = response.data as List<dynamic>;
      return data
          .map((json) => Mate.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(ApiService.getErrorMessage(e));
    }
  }

  // Send a mate request
  Future<void> addMateRequest(String username) async {
    try {
      await _apiService.dio.post(ApiConstants.matesAdd(username));
    } on DioException catch (e) {
      throw Exception(ApiService.getErrorMessage(e));
    }
  }

  // Get incoming mate requests
  Future<List<Mate>> getMateRequests() async {
    try {
      final response = await _apiService.dio.get(ApiConstants.matesRequests);
      final data = response.data as List<dynamic>;
      return data
          .map((json) => Mate.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(ApiService.getErrorMessage(e));
    }
  }

  // Accept a mate request
  Future<void> acceptMateRequest(String username) async {
    try {
      await _apiService.dio.post(ApiConstants.matesAccept(username));
    } on DioException catch (e) {
      throw Exception(ApiService.getErrorMessage(e));
    }
  }

  // Reject a mate request
  Future<void> rejectMateRequest(String username) async {
    try {
      await _apiService.dio.post(ApiConstants.matesReject(username));
    } on DioException catch (e) {
      throw Exception(ApiService.getErrorMessage(e));
    }
  }

  // Remove a mate
  Future<void> removeMate(String username) async {
    try {
      await _apiService.dio.delete(ApiConstants.matesRemove(username));
    } on DioException catch (e) {
      throw Exception(ApiService.getErrorMessage(e));
    }
  }
}

