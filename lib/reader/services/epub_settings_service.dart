import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bookmark.dart';
import '../models/highlight.dart';

class EpubSettingsService {
  static const String _keyCfi = 'last_epub_cfi';
  static const String _keyFont = 'font_size';
  static const String _keyBookmarks = 'bookmarks_cfi';
  static const String _keyHighlights = 'highlights_json';

  // Restore settings
  static Future<Map<String, dynamic>> restoreSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final fontSize = prefs.getDouble(_keyFont) ?? 16.0;

    final savedBookmarks = prefs.getStringList(_keyBookmarks) ?? <String>[];
    final bookmarks = savedBookmarks
        .map((e) => Bookmark(label: 'Bookmark', cfi: e))
        .toList();

    final highlightsJson = prefs.getString(_keyHighlights);
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

  // Persist settings
  static Future<void> persistSettings({
    required double fontSize,
    required List<Bookmark> bookmarks,
    required List<Highlight> highlights,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFont, fontSize);
    await prefs.setStringList(
      _keyBookmarks,
      bookmarks.map((b) => b.cfi).toList(),
    );
    final highlightsJson = jsonEncode(
      highlights.map((h) => h.toJson()).toList(),
    );
    await prefs.setString(_keyHighlights, highlightsJson);
  }

  // Save current position
  static Future<void> savePosition(String cfi) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCfi, cfi);
  }

  // Get last saved position
  static Future<String?> getLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCfi);
  }
}
