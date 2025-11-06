import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import '../utils/color_utils.dart';

class HighlightContextMenu {
  static ContextMenu build({
    required void Function(Color color) onHighlight,
  }) {
    final menuItems = <ContextMenuItem>[];

    // Add highlight color options with color circle emojis only
    // Start from 1 to avoid conflicts with system menu items (0 is typically reserved)
    for (int i = 0; i < ColorUtils.highlightColors.length; i++) {
      final color = ColorUtils.highlightColors[i];
      menuItems.add(
        ContextMenuItem(
          id: i + 1, // Use integer ID starting from 1
          title: ColorUtils.getColorCircleEmoji(color),
          action: () => onHighlight(color),
        ),
      );
    }

    return ContextMenu(
      settings: ContextMenuSettings(hideDefaultSystemContextMenuItems: true),
      menuItems: menuItems,
    );
  }
}

