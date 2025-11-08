import 'dart:convert';
import 'dart:typed_data';

/// Utility class for image conversion operations
class ImageUtils {
  /// Convert image bytes to base64 data URL
  /// 
  /// [bytes] - The image bytes to convert
  /// [mimeType] - The MIME type of the image (default: 'image/png')
  /// Returns a base64 data URL string in format: data:image/png;base64,<base64_string>
  static String bytesToBase64DataUrl(
    Uint8List bytes, {
    String mimeType = 'image/png',
  }) {
    final base64String = base64Encode(bytes);
    return 'data:$mimeType;base64,$base64String';
  }

  /// Detect image MIME type from bytes
  /// 
  /// [bytes] - The image bytes to analyze
  /// Returns the MIME type string (e.g., 'image/png', 'image/jpeg')
  static String detectImageMimeType(Uint8List bytes) {
    if (bytes.length < 4) return 'image/png';

    // PNG signature: 89 50 4E 47
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }

    // JPEG signature: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }

    // Default to PNG if unknown
    return 'image/png';
  }

  /// Convert image bytes to base64 data URL with automatic MIME type detection
  /// 
  /// [bytes] - The image bytes to convert
  /// Returns a base64 data URL string
  static String bytesToBase64DataUrlAuto(Uint8List bytes) {
    final mimeType = detectImageMimeType(bytes);
    return bytesToBase64DataUrl(bytes, mimeType: mimeType);
  }

  /// Check if a string is a base64 data URL
  /// 
  /// [url] - The string to check
  /// Returns true if the string is a base64 data URL
  static bool isBase64DataUrl(String url) {
    return url.startsWith('data:image/') && url.contains(';base64,');
  }

  /// Extract base64 string from data URL
  /// 
  /// [dataUrl] - The base64 data URL
  /// Returns the base64 string without the data URL prefix
  static String extractBase64FromDataUrl(String dataUrl) {
    if (!isBase64DataUrl(dataUrl)) {
      return dataUrl;
    }
    final parts = dataUrl.split(';base64,');
    return parts.length > 1 ? parts[1] : dataUrl;
  }
}

