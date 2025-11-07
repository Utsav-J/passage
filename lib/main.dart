import 'theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:passage/home_screen.dart';
import 'package:passage/auth/login_screen.dart';
import 'package:passage/services/api_service.dart';
import 'package:passage/services/auth_service.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Initialize API service
  ApiService().init();
  runApp(const PassageApp());
}

class PassageApp extends StatefulWidget {
  const PassageApp({super.key});

  @override
  State<PassageApp> createState() => _PassageAppState();
}

class _PassageAppState extends State<PassageApp> {
  AppThemeMode _appThemeMode = AppThemeMode.light;
  bool _isAuthenticated = false;
  bool _isLoading = true;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _restoreTheme();
    await _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final isAuth = await _authService.isAuthenticated();
    setState(() {
      _isAuthenticated = isAuth;
      _isLoading = false;
    });
  }

  Future<void> _restoreTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('app_theme_mode');
    setState(() {
      _appThemeMode = _parseTheme(saved) ?? AppThemeMode.light;
    });
  }

  Future<void> _saveTheme(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme_mode', mode.name);
  }

  AppThemeMode? _parseTheme(String? name) {
    if (name == null) return null;
    return AppThemeMode.values.firstWhere(
      (e) => e.name == name,
      orElse: () => AppThemeMode.light,
    );
  }

  void _onChangeTheme(AppThemeMode mode) {
    setState(() => _appThemeMode = mode);
    _saveTheme(mode);
  }

  @override
  Widget build(BuildContext context) {
    final themeData = switch (_appThemeMode) {
      AppThemeMode.light => AppThemes.light,
      AppThemeMode.dark => AppThemes.dark,
      AppThemeMode.amoled => AppThemes.amoled,
      AppThemeMode.night => AppThemes.night,
    };

    return ScreenUtilInit(
      designSize: const Size(390, 844), // reference size
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Passage EPUB Reader',
          theme: themeData,
          debugShowCheckedModeBanner: false,
          home: _isLoading
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : _isAuthenticated
              ? HomeScreen(
                  appThemeMode: _appThemeMode,
                  onThemeChanged: _onChangeTheme,
                )
              : LoginScreen(),
        );
      },
    );
  }
}
