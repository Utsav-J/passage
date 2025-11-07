import 'package:dio/dio.dart';
import '../models/snippet.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class SnippetService {
  final ApiService _apiService = ApiService();

  // Send a snippet to a mate
  Future<Snippet> sendSnippet({
    required int mateId,
    required int bookId,
    required String text,
    String? note,
  }) async {
    try {
      final response = await _apiService.dio.post(
        ApiConstants.snippetsSend,
        data: {
          'mate_id': mateId,
          'book_id': bookId,
          'text': text,
          if (note != null) 'note': note,
        },
      );

      return Snippet.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(ApiService.getErrorMessage(e));
    }
  }

  // Get all received snippets
  Future<List<Snippet>> getReceivedSnippets() async {
    try {
      final response = await _apiService.dio.get(ApiConstants.snippetsReceived);
      final data = response.data as List<dynamic>;
      return data
          .map((json) => Snippet.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(ApiService.getErrorMessage(e));
    }
  }

  // Get all sent snippets
  Future<List<Snippet>> getSentSnippets() async {
    try {
      final response = await _apiService.dio.get(ApiConstants.snippetsSent);
      final data = response.data as List<dynamic>;
      return data
          .map((json) => Snippet.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(ApiService.getErrorMessage(e));
    }
  }

  // Delete a snippet
  Future<void> deleteSnippet(int snippetId) async {
    try {
      await _apiService.dio.delete(ApiConstants.snippetsDelete(snippetId));
    } on DioException catch (e) {
      throw Exception(ApiService.getErrorMessage(e));
    }
  }
}

