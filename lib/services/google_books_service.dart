import 'package:dio/dio.dart';

/// Model for Google Books API response
class GoogleBook {
  GoogleBook({
    required this.id,
    required this.title,
    required this.authors,
    this.thumbnail,
    this.description,
    this.publishedDate,
    this.pageCount,
  });

  final String id;
  final String title;
  final List<String> authors;
  final String? thumbnail;
  final String? description;
  final String? publishedDate;
  final int? pageCount;

  factory GoogleBook.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] as Map<String, dynamic>? ?? {};
    final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
    final thumbnail = imageLinks?['thumbnail'] as String?;
    
    // Convert HTTP to HTTPS for security
    String? thumbnailUrl = thumbnail;
    if (thumbnailUrl != null && thumbnailUrl.startsWith('http://')) {
      thumbnailUrl = thumbnailUrl.replaceFirst('http://', 'https://');
    }
    
    return GoogleBook(
      id: json['id'] as String? ?? '',
      title: volumeInfo['title'] as String? ?? '',
      authors: (volumeInfo['authors'] as List<dynamic>?)
              ?.map((a) => a.toString())
              .toList() ??
          [],
      thumbnail: thumbnailUrl,
      description: volumeInfo['description'] as String?,
      publishedDate: volumeInfo['publishedDate'] as String?,
      pageCount: volumeInfo['pageCount'] as int?,
    );
  }
}

/// Service for interacting with Google Books API
class GoogleBooksService {
  final Dio _dio = Dio();
  static const String _baseUrl = 'https://www.googleapis.com/books/v1';

  /// Search for a book by title and author
  /// 
  /// [title] - Book title
  /// [author] - Book author (optional)
  /// Returns the first matching book or null if not found
  Future<GoogleBook?> searchBook({
    required String title,
    String? author,
  }) async {
    try {
      // Build search query
      String query = 'intitle:${_encodeQuery(title)}';
      if (author != null && author.isNotEmpty) {
        // Extract author name up to first comma
        final authorName = _extractAuthorName(author);
        if (authorName.isNotEmpty) {
          query += '+inauthor:${_encodeQuery(authorName)}';
        }
      }

      final url = '$_baseUrl/volumes';
      final response = await _dio.get(
        url,
        queryParameters: {'q': query, 'maxResults': 5},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>?;

        if (items != null && items.isNotEmpty) {
          // Return the first matching book
          return GoogleBook.fromJson(items.first as Map<String, dynamic>);
        }
      }

      return null;
    } catch (e) {
      // Log error but don't throw - return null if search fails
      return null;
    }
  }

  /// Extract author name up to the first comma
  /// Example: "Julie Schwartz Gottman, PhD" => "Julie Schwartz Gottman"
  String _extractAuthorName(String author) {
    final trimmed = author.trim();
    final commaIndex = trimmed.indexOf(',');
    if (commaIndex > 0) {
      return trimmed.substring(0, commaIndex).trim();
    }
    return trimmed;
  }

  /// Encode query parameters for URL
  String _encodeQuery(String query) {
    return Uri.encodeComponent(query.trim());
  }

  /// Get cover image URL from Google Books
  /// 
  /// [title] - Book title
  /// [author] - Book author (optional)
  /// Returns the thumbnail URL or null if not found
  Future<String?> getCoverImageUrl({
    required String title,
    String? author,
  }) async {
    final book = await searchBook(title: title, author: author);
    return book?.thumbnail;
  }
}

