import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bookmark.dart';
import '../models/highlight.dart';

class EpubSettingsService {
  static const String _keyFont = 'font_size';

  // Generate book-specific keys
  static String _bookKey(String bookId, String suffix) => 'book_${bookId}_$suffix';

  // Restore settings for a specific book
  static Future<Map<String, dynamic>> restoreSettings(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final fontSize = prefs.getDouble(_keyFont) ?? 16.0;

    final bookmarksJson = prefs.getString(_bookKey(bookId, 'bookmarks'));
    final bookmarks = <Bookmark>[];
    if (bookmarksJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(bookmarksJson);
        bookmarks.addAll(
          decoded.map((e) => Bookmark.fromJson(e as Map<String, dynamic>)),
        );
      } catch (e) {
        // Ignore invalid JSON
      }
    }

    final highlightsJson = prefs.getString(_bookKey(bookId, 'highlights'));
    final highlights = <Highlight>[];
    if (highlightsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(highlightsJson);
        highlights.addAll(
          decoded.map((e) => Highlight.fromJson(e as Map<String, dynamic>)),
        );
      } catch (e) {
        // Ignore invalid JSON
      }
    }

    return {
      'fontSize': fontSize,
      'bookmarks': bookmarks,
      'highlights': highlights,
    };
  }

  // Persist settings for a specific book
  static Future<void> persistSettings({
    required String bookId,
    required double fontSize,
    required List<Bookmark> bookmarks,
    required List<Highlight> highlights,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFont, fontSize);

    final bookmarksJson = jsonEncode(
      bookmarks.map((b) => b.toJson()).toList(),
    );
    await prefs.setString(_bookKey(bookId, 'bookmarks'), bookmarksJson);

    final highlightsJson = jsonEncode(
      highlights.map((h) => h.toJson()).toList(),
    );
    await prefs.setString(_bookKey(bookId, 'highlights'), highlightsJson);
  }

  // Save current position for a specific book
  static Future<void> savePosition(String bookId, String cfi) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bookKey(bookId, 'last_cfi'), cfi);
  }

  // Get last saved position for a specific book
  static Future<String?> getLastPosition(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_bookKey(bookId, 'last_cfi'));
  }

  // Save max progress for a specific book
  static Future<void> saveMaxProgress(String bookId, double progress) async {
    final prefs = await SharedPreferences.getInstance();
    final currentMax = prefs.getDouble(_bookKey(bookId, 'max_progress')) ?? 0.0;
    if (progress > currentMax) {
      await prefs.setDouble(_bookKey(bookId, 'max_progress'), progress);
    }
  }

  // Get max progress for a specific book
  static Future<double> getMaxProgress(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_bookKey(bookId, 'max_progress')) ?? 0.0;
  }
}
