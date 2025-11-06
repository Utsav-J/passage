import 'package:flutter/material.dart';

enum AppThemeMode { light, dark, amoled, night }

class AppThemes {
  static ThemeData light = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(elevation: 0),
  );

  static ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(elevation: 0),
  );

  static ThemeData amoled = ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Colors.tealAccent,
      surface: Colors.black,
      background: Colors.black,
    ),
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(backgroundColor: Colors.black, elevation: 0),
    cardColor: const Color(0xFF0A0A0A),
    dividerColor: const Color(0xFF111111),
  );

  // Night/eye-strain protection: warm sepia background with dark text
  static ThemeData night = ThemeData(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF9C6F3D),
      surface: Color(0xFFF2E8D8),
      background: Color(0xFFF2E8D8),
      onBackground: Color(0xFF2B2A28),
    ),
    scaffoldBackgroundColor: const Color(0xFFF2E8D8), // warm sepia
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF2E8D8),
      foregroundColor: Color(0xFF2B2A28),
      elevation: 0,
    ),
    dividerColor: const Color(0xFFE4D7C3),
  );
}
