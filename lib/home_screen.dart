import 'dart:typed_data';

import 'package:epubx/epubx.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image/image.dart' as img;
import 'package:passage/reader/epub_reader_page.dart';
import 'package:passage/theme/app_theme.dart';

const String _defaultAssetPath = 'assets/books/sample.epub';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.appThemeMode,
    required this.onThemeChanged,
  });

  final AppThemeMode appThemeMode;
  final void Function(AppThemeMode) onThemeChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  _BookData? _assetBook;

  List<_BookData> get _libraryBooks => [
    _assetBook ?? _placeholderAssetBook,
    ..._additionalLibraryBooks,
  ];

  @override
  void initState() {
    super.initState();
    _loadDefaultAssetBook();
  }

  Future<void> _loadDefaultAssetBook() async {
    try {
      final data = await rootBundle.load(_defaultAssetPath);
      final bytes = data.buffer.asUint8List();
      final book = await EpubReader.readBook(bytes);

      final rawTitle = book.Title?.trim();
      final title = (rawTitle == null || rawTitle.isEmpty)
          ? 'Sample EPUB'
          : rawTitle;

      final authorCandidates = (book.AuthorList ?? [])
          .map((e) => e!.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final author = authorCandidates.isNotEmpty
          ? authorCandidates.join(', ')
          : (book.Author?.trim().isNotEmpty == true
                ? book.Author!.trim()
                : 'Unknown Author');

      final coverImage = book.CoverImage;
      Uint8List? coverBytes;
      if (coverImage != null) {
        try {
          // Encode the Image to PNG bytes using the image package
          final pngBytes = img.encodePng(coverImage);
          coverBytes = Uint8List.fromList(pngBytes);
        } catch (e) {
          debugPrint('Failed to encode cover image: $e');
        }
      }

      if (!mounted) return;
      setState(() {
        _assetBook = _BookData(
          title: title,
          subtitle: author,
          progress: 0.0,
          color: const Color(0xFF7B61FF),
          assetPath: _defaultAssetPath,
          coverImage: coverBytes,
        );
      });
    } catch (error) {
      debugPrint('Failed to load default asset metadata: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _MyBooksTab(onOpenBook: _openBook, books: _libraryBooks),
          const _MyMatesTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            label: 'My Books',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'My Mates',
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    switch (_currentIndex) {
      case 0:
        return AppBar(
          title: Text(
            'My Books',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          centerTitle: false,
          actions: [
            IconButton(
              tooltip: 'Sort books',
              icon: const Icon(Icons.sort_rounded),
              onPressed: () => _showFeatureComingSoon('Sort options'),
            ),
            IconButton(
              tooltip: 'Add book',
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _showFeatureComingSoon('Add book'),
            ),
            _buildThemeMenu(),
          ],
        );
      case 1:
      default:
        return AppBar(
          title: Text(
            'My Mates',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          centerTitle: false,
          actions: [
            IconButton(
              tooltip: 'Filter feed',
              icon: const Icon(Icons.filter_list_rounded),
              onPressed: () => _showFeatureComingSoon('Feed filters'),
            ),
            _buildThemeMenu(),
          ],
        );
    }
  }

  Widget _buildFloatingActionButton() {
    switch (_currentIndex) {
      case 0:
        return FloatingActionButton(
          onPressed: () => _showFeatureComingSoon('Add new book'),
          child: const Icon(Icons.add),
        );
      case 1:
      default:
        return FloatingActionButton(
          onPressed: () => _showFeatureComingSoon('Share a snippet'),
          child: const Icon(Icons.send),
        );
    }
  }

  PopupMenuButton<AppThemeMode> _buildThemeMenu() {
    return PopupMenuButton<AppThemeMode>(
      tooltip: 'Theme',
      initialValue: widget.appThemeMode,
      onSelected: widget.onThemeChanged,
      itemBuilder: (context) => const [
        PopupMenuItem(value: AppThemeMode.light, child: Text('Light')),
        PopupMenuItem(value: AppThemeMode.dark, child: Text('Dark')),
        PopupMenuItem(value: AppThemeMode.amoled, child: Text('AMOLED')),
        PopupMenuItem(value: AppThemeMode.night, child: Text('Night Light')),
      ],
      icon: const Icon(Icons.color_lens_outlined),
    );
  }

  void _showFeatureComingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$feature coming soon'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _openBook(_BookData book) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            EpubReaderPage(assetPath: book.assetPath ?? _defaultAssetPath),
      ),
    );
  }
}

class _MyBooksTab extends StatelessWidget {
  const _MyBooksTab({required this.onOpenBook, required this.books});

  final ValueChanged<_BookData> onOpenBook;
  final List<_BookData> books;

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ScreenUtil().screenWidth > 540 ? 3 : 2;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          sliver: SliverToBoxAdapter(
            child: _SectionHeader(title: 'My Library'),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
              childAspectRatio: 0.68,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final book = books[index];
              return _BookCard(book: book, onTap: () => onOpenBook(book));
            }, childCount: books.length),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          sliver: SliverToBoxAdapter(
            child: _SectionHeader(title: 'Discover Reads'),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 220.h,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final book = _discoverBooks[index];
                return _DiscoverBookCard(
                  book: book,
                  onTap: () => onOpenBook(book),
                );
              },
              separatorBuilder: (_, __) => SizedBox(width: 16.w),
              itemCount: _discoverBooks.length,
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 24.h)),
      ],
    );
  }
}

class _MyMatesTab extends StatelessWidget {
  const _MyMatesTab();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 800));
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 100.h),
        itemBuilder: (context, index) {
          final message = _mateMessages[index];
          return _MessageCard(message: message);
        },
        separatorBuilder: (_, __) => SizedBox(height: 16.h),
        itemCount: _mateMessages.length,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book, required this.onTap});

  final _BookData book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: book.coverImage != null ? Colors.black : null,
                  gradient: book.coverImage == null
                      ? LinearGradient(
                          colors: [book.color, book.color.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  image: book.coverImage != null
                      ? DecorationImage(
                          image: MemoryImage(book.coverImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              ),
            ),
            if (book.coverImage != null)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.05),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      book.subtitle,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SizedBox(
                height: 6.h,
                child: LinearProgressIndicator(
                  value: book.progress,
                  color: Theme.of(context).colorScheme.primary,
                  backgroundColor: Colors.white.withOpacity(0.15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoverBookCard extends StatelessWidget {
  const _DiscoverBookCard({required this.book, required this.onTap});

  final _BookData book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 160.w,
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [book.color, book.color.withOpacity(0.65)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        book.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        book.subtitle,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final _MateMessage message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mutedBodyColor = textTheme.bodySmall?.color != null
        ? textTheme.bodySmall!.color!.withOpacity(0.7)
        : colorScheme.onSurfaceVariant.withOpacity(0.7);
    final mutedLabelColor = textTheme.labelSmall?.color != null
        ? textTheme.labelSmall!.color!.withOpacity(0.7)
        : colorScheme.onSurfaceVariant.withOpacity(0.7);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24.r,
              backgroundColor: colorScheme.primary.withOpacity(0.15),
              child: Text(
                message.initials,
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message.snippet, style: textTheme.bodyLarge),
                  SizedBox(height: 8.h),
                  Text(
                    '— from ${message.bookTitle}',
                    style: textTheme.bodySmall?.copyWith(color: mutedBodyColor),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 12.w,
                          runSpacing: 8.h,
                          children: message.reactions
                              .map(
                                (reaction) => Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 6.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withOpacity(
                                      0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Text(
                                    reaction,
                                    style: textTheme.labelMedium,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Shared by ${message.sender}',
                            style: textTheme.bodySmall?.copyWith(
                              color: mutedBodyColor,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            message.timeLabel,
                            style: textTheme.labelSmall?.copyWith(
                              color: mutedLabelColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            ClipRRect(
              borderRadius: BorderRadius.circular(14.r),
              child: Container(
                width: 54.w,
                height: 72.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.secondaryContainer,
                      colorScheme.primaryContainer,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  message.bookInitials,
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookData {
  const _BookData({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.color,
    this.assetPath,
    this.coverImage,
  });

  final String title;
  final String subtitle;
  final double progress;
  final Color color;
  final String? assetPath;
  final Uint8List? coverImage;
}

class _MateMessage {
  const _MateMessage({
    required this.sender,
    required this.snippet,
    required this.bookTitle,
    required this.timeLabel,
    required this.reactions,
  });

  final String sender;
  final String snippet;
  final String bookTitle;
  final String timeLabel;
  final List<String> reactions;

  String get initials {
    final trimmed = sender.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final parts = trimmed.split(RegExp(r'\s+'));
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + last).toUpperCase();
  }

  String get bookInitials {
    final words = bookTitle.trim().split(RegExp(r'\s+'));
    final buffer = StringBuffer();
    for (final word in words) {
      if (word.isEmpty) continue;
      buffer.write(word[0].toUpperCase());
      if (buffer.length == 2) break;
    }
    return buffer.toString();
  }
}

final _BookData _placeholderAssetBook = _BookData(
  title: 'Sample EPUB',
  subtitle: 'Loading...',
  progress: 0.0,
  color: const Color(0xFF7B61FF),
  assetPath: _defaultAssetPath,
);

final List<_BookData> _additionalLibraryBooks = [
  const _BookData(
    title: 'Atomic Habits',
    subtitle: 'James Clear',
    progress: 0.34,
    color: const Color(0xFFFF6584),
  ),
  const _BookData(
    title: 'Dune',
    subtitle: 'Frank Herbert',
    progress: 0.9,
    color: const Color(0xFF00BFA5),
  ),
  const _BookData(
    title: 'The Pragmatic Programmer',
    subtitle: 'Andrew Hunt',
    progress: 0.18,
    color: const Color(0xFF4DD0E1),
  ),
];

final List<_BookData> _discoverBooks = [
  _BookData(
    title: 'The Midnight Library',
    subtitle: 'Matt Haig',
    progress: 0.0,
    color: const Color(0xFFFFA726),
  ),
  _BookData(
    title: 'Project Hail Mary',
    subtitle: 'Andy Weir',
    progress: 0.0,
    color: const Color(0xFF26C6DA),
  ),
  _BookData(
    title: 'Tomorrow, and Tomorrow, and Tomorrow',
    subtitle: 'Gabrielle Zevin',
    progress: 0.0,
    color: const Color(0xFFA1887F),
  ),
];

final List<_MateMessage> _mateMessages = [
  _MateMessage(
    sender: 'Alex Carter',
    snippet:
        '“We are what we repeatedly do. Excellence, then, is not an act but a habit.”',
    bookTitle: 'Atomic Habits',
    timeLabel: '5 min ago',
    reactions: ['🔥 12', '👏 4'],
  ),
  _MateMessage(
    sender: 'Priya Patel',
    snippet:
        '“Fear is the mind-killer. Fear is the little-death that brings total obliteration.”',
    bookTitle: 'Dune',
    timeLabel: '2 hrs ago',
    reactions: ['💡 8', '🚀 3'],
  ),
  _MateMessage(
    sender: 'Jonas Meyer',
    snippet:
        '“Hope is being able to see that there is light despite all of the darkness.”',
    bookTitle: 'The Midnight Library',
    timeLabel: 'Yesterday',
    reactions: ['🌙 5', '💬 2'],
  ),
];
