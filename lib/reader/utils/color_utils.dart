import 'package:flutter/material.dart';

class ColorUtils {
  // Highlight colors
  static const List<Color> highlightColors = [
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
  ];

  static String getColorCircleEmoji(Color color) {
    // Return colored circle emojis for each color
    if (color == Colors.yellow) return '🟡';
    if (color == Colors.green) return '🟢';
    if (color == Colors.blue) return '🔵';
    if (color == Colors.orange) return '🟠';
    if (color == Colors.purple) return '🟣';
    return '⚪'; // Default white circle
  }

  static String getColorName(Color color) {
    if (color == Colors.yellow) return 'Yellow';
    if (color == Colors.green) return 'Green';
    if (color == Colors.blue) return 'Blue';
    if (color == Colors.orange) return 'Orange';
    if (color == Colors.purple) return 'Purple';
    return 'Custom';
  }
}

