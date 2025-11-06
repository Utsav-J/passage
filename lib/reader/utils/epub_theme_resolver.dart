import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

class EpubThemeResolver {
  static EpubTheme resolve(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.scaffoldBackgroundColor;
    final fg = theme.colorScheme.onBackground;
    return EpubTheme.custom(backgroundColor: bg, foregroundColor: fg);
  }
}

