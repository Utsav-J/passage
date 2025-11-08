import 'dart:io';
import 'dart:typed_data';
import 'package:epubx/epubx.dart';
import 'package:flutter/services.dart';

/// Metadata extracted from an EPUB file
class EpubMetadata {
  EpubMetadata({
    required this.title,
    required this.author,
    this.coverImageBytes,
    this.firstPageImageBytes,
  });

  final String title;
  final String author;
  final Uint8List? coverImageBytes;
  final Uint8List? firstPageImageBytes;
}

/// Service for extracting metadata and images from EPUB files
class EpubMetadataService {
  /// Extract metadata from an EPUB file
  /// 
  /// [filePath] - Path to the EPUB file (file system or asset path)
  /// [isAsset] - Whether the file is an asset (default: false)
  /// Returns EpubMetadata object with title, author, and optional cover image
  Future<EpubMetadata> extractMetadata(
    String filePath, {
    bool isAsset = false,
  }) async {
    Uint8List bytes;
    
    if (isAsset) {
      // Load from assets
      final ByteData data = await rootBundle.load(filePath);
      bytes = data.buffer.asUint8List();
    } else {
      // Load from file system
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('EPUB file not found: $filePath');
      }
      bytes = await file.readAsBytes();
    }

    // Read EPUB book
    final epubBook = await EpubReader.readBook(bytes);

    // Extract title and author
    final title = _extractTitle(epubBook, filePath);
    final author = _extractAuthor(epubBook);

    // Try to extract cover image
    Uint8List? coverImageBytes = await _extractCoverImage(epubBook);

    // If no cover, try to extract first page image
    Uint8List? firstPageImageBytes;
    if (coverImageBytes == null || coverImageBytes.isEmpty) {
      firstPageImageBytes = await _extractFirstPageAsImage(epubBook);
    }

    return EpubMetadata(
      title: title,
      author: author,
      coverImageBytes: coverImageBytes,
      firstPageImageBytes: firstPageImageBytes,
    );
  }

  /// Extract cover image from EPUB
  Future<Uint8List?> _extractCoverImage(EpubBook epubBook) async {
    try {
      final coverImage = epubBook.CoverImage;
      if (coverImage == null) {
        return null;
      }

      // Try to access image content through different possible properties
      // epubx Image class structure may vary
      try {
        // Method 1: Try Content property
        final content = (coverImage as dynamic).Content;
        if (content != null) {
          if (content is Uint8List) {
            return content;
          } else if (content is List<int>) {
            return Uint8List.fromList(content);
          }
        }
      } catch (e) {
        // Content property doesn't exist or failed
      }

      try {
        // Method 2: Try accessing through Images map using FileName
        final fileName = (coverImage as dynamic).FileName;
        if (fileName != null && fileName is String) {
          final images = epubBook.Content;
          if (images != null) {
            // Try to find image in content
            // This is a simplified approach
          }
        }
      } catch (e) {
        // Alternative method failed
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Extract title from EPUB metadata
  String _extractTitle(EpubBook epubBook, String filePath) {
    // Try to get title from metadata
    final title = epubBook.Title;
    if (title != null && title.isNotEmpty) {
      return title;
    }

    // Try alternative metadata fields
    final metadata = epubBook.Schema?.Package?.Metadata;
    if (metadata != null) {
      // Try Dublin Core title
      final titles = metadata.Titles;
      if (titles != null && titles.isNotEmpty) {
        for (final t in titles) {
          if (t.isNotEmpty) {
            return t;
          }
        }
      }
    }

    // Fallback to filename
    final fileName = filePath.split('/').last.split('\\').last;
    return fileName.replaceAll('.epub', '').replaceAll('_', ' ');
  }

  /// Extract author from EPUB metadata
  String _extractAuthor(EpubBook epubBook) {
    // Try to get author from metadata
    final author = epubBook.Author;
    if (author != null && author.isNotEmpty) {
      return author;
    }

    // Try alternative metadata fields
    final metadata = epubBook.Schema?.Package?.Metadata;
    if (metadata != null) {
      // Try Dublin Core creators
      final creators = metadata.Creators;
      if (creators != null && creators.isNotEmpty) {
        for (final creator in creators) {
          final creatorName = creator.Creator;
          if (creatorName != null && creatorName.isNotEmpty) {
            return creatorName;
          }
        }
      }
    }

    // Fallback
    return 'Unknown Author';
  }

  /// Extract first page as image for cover fallback
  /// 
  /// This method tries to extract an image from the first chapter
  /// as a cover fallback when no cover image exists
  Future<Uint8List?> _extractFirstPageAsImage(EpubBook epubBook) async {
    try {
      // Get chapters
      final chapters = epubBook.Chapters;
      if (chapters == null || chapters.isEmpty) {
        return null;
      }

      // Try to get first chapter
      final firstChapter = chapters.first;

      // Try to extract first image from the chapter
      return await _extractFirstImageFromChapter(firstChapter, epubBook);
    } catch (e) {
      return null;
    }
  }

  /// Extract first image from chapter as fallback
  Future<Uint8List?> _extractFirstImageFromChapter(
    EpubChapter chapter,
    EpubBook epubBook,
  ) async {
    try {
      // Get HTML content from chapter
      final htmlContent = chapter.HtmlContent;
      if (htmlContent == null || htmlContent.isEmpty) {
        return null;
      }

      // Try to find images in the HTML using regex
      // Look for img tags with src attributes
      final imageRegex1 = RegExp(r'<img[^>]+src="([^"]+)"', caseSensitive: false);
      final imageRegex2 = RegExp(r"<img[^>]+src='([^']+)'", caseSensitive: false);
      
      final matches1 = imageRegex1.allMatches(htmlContent);
      final matches2 = imageRegex2.allMatches(htmlContent);
      
      // Process matches from first regex (double quotes)
      for (final match in matches1) {
        if (match.groupCount >= 1) {
          var imagePath = match.group(1);
          if (imagePath != null && imagePath.isNotEmpty) {
            // Clean up the image path
            imagePath = imagePath.replaceAll('../', '').replaceAll('./', '');
            
            // Try to get image from EPUB content
            final imageBytes = await _getImageFromEpub(epubBook, imagePath);
            if (imageBytes != null) {
              return imageBytes;
            }
          }
        }
      }
      
      // Process matches from second regex (single quotes)
      for (final match in matches2) {
        if (match.groupCount >= 1) {
          var imagePath = match.group(1);
          if (imagePath != null && imagePath.isNotEmpty) {
            // Clean up the image path
            imagePath = imagePath.replaceAll('../', '').replaceAll('./', '');
            
            // Try to get image from EPUB content
            final imageBytes = await _getImageFromEpub(epubBook, imagePath);
            if (imageBytes != null) {
              return imageBytes;
            }
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get image bytes from EPUB content by path
  Future<Uint8List?> _getImageFromEpub(EpubBook epubBook, String imagePath) async {
    try {
      // Try to access images through Content property
      final content = epubBook.Content;
      if (content != null) {
        // Content is typically a map of file paths to content
        // Try different path variations
        final pathVariations = [
          imagePath,
          imagePath.replaceAll('../', ''),
          imagePath.replaceAll('./', ''),
          'images/$imagePath',
          'OEBPS/images/$imagePath',
          'OEBPS/$imagePath',
        ];

        for (final path in pathVariations) {
          try {
            final imageContent = (content as dynamic)[path];
            if (imageContent != null) {
              if (imageContent is Uint8List) {
                return imageContent;
              } else if (imageContent is List<int>) {
                return Uint8List.fromList(imageContent);
              } else if (imageContent is Image) {
                // Try to get Content from Image object
                final imgContent = (imageContent as dynamic).Content;
                if (imgContent != null) {
                  if (imgContent is Uint8List) {
                    return imgContent;
                  } else if (imgContent is List<int>) {
                    return Uint8List.fromList(imgContent);
                  }
                }
              }
            }
          } catch (e) {
            continue;
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
