import 'package:dio/dio.dart';
import '../models/book.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class BookService {
  final ApiService _apiService = ApiService();

  // Get all books for the current user
  Future<List<Book>> getMyBooks() async {
    try {
      final response = await _apiService.dio.get(ApiConstants.booksMy);
      final data = response.data as List<dynamic>;
      return data
          .map((json) => Book.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(ApiService.getErrorMessage(e));
    }
  }

  // Add a new book
  Future<Book> addBook({
    required String title,
    required String author,
    String? coverImageUrl,
    double progress = 0.0,
  }) async {
    try {
      final response = await _apiService.dio.post(
        ApiConstants.booksAdd,
        data: {
          'title': title,
          'author': author,
          if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
          'progress': progress,
        },
      );

      return Book.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(ApiService.getErrorMessage(e));
    }
  }

  // Delete a book
  Future<void> deleteBook(int bookId) async {
    try {
      await _apiService.dio.delete(ApiConstants.booksDelete(bookId));
    } on DioException catch (e) {
      throw Exception(ApiService.getErrorMessage(e));
    }
  }
}

