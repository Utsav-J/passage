import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reader/epub_reader_page.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const PassageApp());
}

class PassageApp extends StatefulWidget {
  const PassageApp({super.key});

  @override
  State<PassageApp> createState() => _PassageAppState();
}

class _PassageAppState extends State<PassageApp> {
  AppThemeMode _appThemeMode = AppThemeMode.light;

  @override
  void initState() {
    super.initState();
    _restoreTheme();
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
          home: HomeScreen(
            appThemeMode: _appThemeMode,
            onThemeChanged: _onChangeTheme,
          ),
        );
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.appThemeMode,
    required this.onThemeChanged,
  });

  final AppThemeMode appThemeMode;
  final void Function(AppThemeMode) onThemeChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Passage EPUB Reader'),
        actions: [
          PopupMenuButton<AppThemeMode>(
            tooltip: 'Theme',
            initialValue: appThemeMode,
            onSelected: onThemeChanged,
            itemBuilder: (context) => const [
              PopupMenuItem(value: AppThemeMode.light, child: Text('Light')),
              PopupMenuItem(value: AppThemeMode.dark, child: Text('Dark')),
              PopupMenuItem(value: AppThemeMode.amoled, child: Text('AMOLED')),
              PopupMenuItem(
                value: AppThemeMode.night,
                child: Text('Night Light'),
              ),
            ],
            icon: const Icon(Icons.color_lens_outlined),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.menu_book_outlined, size: 88.sp),
              SizedBox(height: 16.h),
              Text(
                'Read EPUB books',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 24.h),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EpubReaderPage()),
                  );
                },
                icon: const Icon(Icons.folder_open),
                label: const Text('Pick EPUB from device'),
              ),
              SizedBox(height: 12.h),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EpubReaderPage(
                        assetPath: 'assets/books/sample.epub',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow_outlined),
                label: const Text(
                  'Open asset sample (assets/books/sample.epub)',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
