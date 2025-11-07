import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:passage/my_mates_tab.dart';
import 'package:passage/reader/epub_reader_page.dart';
import 'package:passage/section_header.dart';
import 'package:passage/theme/app_theme.dart';
import 'package:passage/models/book.dart';
import 'package:passage/models/user.dart';
import 'package:passage/models/mate.dart';
import 'package:passage/services/book_service.dart';
import 'package:passage/services/auth_service.dart';
import 'package:passage/services/snippet_service.dart';
import 'package:passage/services/user_service.dart';
import 'package:passage/services/mate_service.dart';
import 'package:passage/auth/login_screen.dart';
import 'profile/profile_screen.dart';

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
  final BookService _bookService = BookService();
  final AuthService _authService = AuthService();
  List<Book> _books = [];
  bool _isLoadingBooks = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoadingBooks = true;
      _errorMessage = null;
    });

    try {
      final books = await _bookService.getMyBooks();
      if (!mounted) return;
      setState(() {
        _books = books;
        _isLoadingBooks = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoadingBooks = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _MyBooksTab(
            onOpenBook: _openBook,
            books: _books,
            isLoading: _isLoadingBooks,
            onDeleteBook: _deleteBook,
            errorMessage: _errorMessage,
            onRefresh: _loadBooks,
          ),
          MyMatesTab(),
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
              onPressed: _showAddBookDialog,
            ),
            IconButton(
              tooltip: 'Profile',
              icon: const Icon(Icons.account_circle_outlined),
              onPressed: _openProfile,
            ),
            IconButton(
              tooltip: 'Logout',
              icon: const Icon(Icons.logout),
              onPressed: _handleLogout,
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
              tooltip: 'Add mate',
              icon: const Icon(Icons.person_add),
              onPressed: _showAddMateDialog,
            ),
            IconButton(
              tooltip: 'Profile',
              icon: const Icon(Icons.account_circle_outlined),
              onPressed: _openProfile,
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
          onPressed: _showAddBookDialog,
          child: const Icon(Icons.add),
        );
      case 1:
      default:
        return FloatingActionButton(
          onPressed: _showShareSnippetDialog,
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

  void _openProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  void _openBook(Book book) {
    // For demo books (id < 0), use the asset path directly
    // For regular books, use the default asset path since books don't store EPUB files
    // In a real app, you'd need to handle EPUB file storage/retrieval
    final assetPath = book.id < 0 ? _defaultAssetPath : _defaultAssetPath;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EpubReaderPage(assetPath: assetPath)),
    );
  }

  Future<void> _showAddBookDialog() async {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final coverUrlController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Book'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter book title',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: authorController,
                decoration: const InputDecoration(
                  labelText: 'Author',
                  hintText: 'Enter author name',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: coverUrlController,
                decoration: const InputDecoration(
                  labelText: 'Cover Image URL (Optional)',
                  hintText: 'Enter cover image URL',
                ),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty &&
                  authorController.text.trim().isNotEmpty) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _bookService.addBook(
          title: titleController.text.trim(),
          author: authorController.text.trim(),
          coverImageUrl: coverUrlController.text.trim().isEmpty
              ? null
              : coverUrlController.text.trim(),
        );
        if (!mounted) return;
        _loadBooks();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book added successfully')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    titleController.dispose();
    authorController.dispose();
    coverUrlController.dispose();
  }

  Future<void> _deleteBook(int bookId) async {
    try {
      await _bookService.deleteBook(bookId);
      if (!mounted) return;
      _loadBooks();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showAddMateDialog() async {
    await showDialog(
      context: context,
      builder: (context) => const _AddMateDialog(),
    );
  }

  Future<void> _showShareSnippetDialog() async {
    final mateService = MateService();
    final snippetService = SnippetService();
    final bookService = BookService();
    List<Mate> mates;
    List<Book> books;

    try {
      mates = await mateService.getMates();
      books = await bookService.getMyBooks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;

    if (mates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to have mates first')),
      );
      return;
    }

    if (books.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to have books first')),
      );
      return;
    }

    final textController = TextEditingController();
    final noteController = TextEditingController();
    Mate? selectedMate;
    Book? selectedBook;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Share Snippet'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Mate>(
                  value: selectedMate,
                  decoration: const InputDecoration(labelText: 'Select Mate'),
                  items: mates.map((mate) {
                    return DropdownMenuItem(
                      value: mate,
                      child: Text(mate.mate?.username ?? 'Unknown'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedMate = value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Book>(
                  value: selectedBook,
                  decoration: const InputDecoration(labelText: 'Select Book'),
                  items: books.map((book) {
                    return DropdownMenuItem(
                      value: book,
                      child: Text(book.title),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedBook = value),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    labelText: 'Snippet Text',
                    hintText: 'Enter the text you want to share',
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (Optional)',
                    hintText: 'Add a note',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedMate != null &&
                    selectedBook != null &&
                    textController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );

    if (result == true &&
        selectedMate != null &&
        selectedBook != null &&
        textController.text.trim().isNotEmpty) {
      try {
        await snippetService.sendSnippet(
          mateId: selectedMate!.mateId,
          bookId: selectedBook!.id,
          text: textController.text.trim(),
          note: noteController.text.trim().isEmpty
              ? null
              : noteController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Snippet sent successfully')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    textController.dispose();
    noteController.dispose();
  }
}

class _MyBooksTab extends StatelessWidget {
  const _MyBooksTab({
    required this.onOpenBook,
    required this.books,
    required this.isLoading,
    required this.onDeleteBook,
    this.errorMessage,
    this.onRefresh,
  });

  final ValueChanged<Book> onOpenBook;
  final List<Book> books;
  final bool isLoading;
  final ValueChanged<int> onDeleteBook;
  final String? errorMessage;
  final VoidCallback? onRefresh;

  // Create a demo book that always shows the sample.epub
  Book _getDemoBook() {
    return Book(
      id: -1, // Special ID for demo book
      title: 'Sample Book',
      author: 'Demo Author',
      ownerId: 0,
      progress: 0.0,
      createdAt: DateTime.now(),
      coverImageUrl: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error loading books',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRefresh, child: const Text('Retry')),
          ],
        ),
      );
    }

    // Always show demo book, even if user has no books

    final crossAxisCount = ScreenUtil().screenWidth > 540 ? 3 : 2;
    final demoBook = _getDemoBook();

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh?.call();
        await Future.delayed(const Duration(seconds: 1));
      },
      child: CustomScrollView(
        slivers: [
          // Demo Book Section
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            sliver: SliverToBoxAdapter(
              child: SectionHeader(title: 'Demo Book'),
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
                return _BookCard(
                  book: demoBook,
                  onTap: () => onOpenBook(demoBook),
                  onDelete: null, // Demo book cannot be deleted
                );
              }, childCount: 1),
            ),
          ),
          // My Library Section
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            sliver: SliverToBoxAdapter(
              child: SectionHeader(title: 'My Library'),
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
                return _BookCard(
                  book: book,
                  onTap: () => onOpenBook(book),
                  onDelete: () => onDeleteBook(book.id),
                );
              }, childCount: books.length),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 24.h)),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book, required this.onTap, this.onDelete});

  final Book book;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  // Generate a color from the book title hash
  Color _getBookColor() {
    final hash = book.title.hashCode;
    final colors = [
      const Color(0xFF7B61FF),
      const Color(0xFFFF6584),
      const Color(0xFF00BFA5),
      const Color(0xFF4DD0E1),
      const Color(0xFFFFA726),
      const Color(0xFF26C6DA),
      const Color(0xFFA1887F),
    ];
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final bookColor = _getBookColor();
    final hasCoverImage =
        book.coverImageUrl != null && book.coverImageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete != null
          ? () {
              // Show delete dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Book'),
                  content: Text(
                    'Are you sure you want to delete "${book.title}"?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onDelete!();
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            }
          : null,
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
                  color: hasCoverImage ? Colors.black : null,
                  gradient: !hasCoverImage
                      ? LinearGradient(
                          colors: [bookColor, bookColor.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  image: hasCoverImage
                      ? DecorationImage(
                          image: NetworkImage(book.coverImageUrl!),
                          fit: BoxFit.cover,
                          onError: (_, __) {
                            // Handle image load error - fallback to gradient
                          },
                        )
                      : null,
                ),
              ),
            ),
            if (hasCoverImage)
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
                      book.author,
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
                  value: book.progress.clamp(0.0, 1.0),
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

class _AddMateDialog extends StatefulWidget {
  const _AddMateDialog();

  @override
  State<_AddMateDialog> createState() => _AddMateDialogState();
}

class _AddMateDialogState extends State<_AddMateDialog> {
  late final TextEditingController _searchController;
  final UserService _userService = UserService();
  final MateService _mateService = MateService();
  List<User> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();

    // Cancel previous debounce timer
    _searchDebounce?.cancel();

    setState(() {
      _searchQuery = query;
      if (query.length < 2) {
        _searchResults = [];
        _isSearching = false;
      }
    });

    if (query.length < 2) {
      return;
    }

    // Debounce search to avoid too many API calls
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _userService.searchUsers(query);
      if (!mounted) return;

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSearching = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addMate(User user) async {
    try {
      await _mateService.addMateRequest(user.username);
      if (!mounted) return;

      Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Mate request sent')));
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Mate'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by username or email',
                hintText: 'Enter username or email',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              )
            else if (_searchResults.isEmpty && _searchQuery.length >= 2)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No users found'),
              )
            else if (_searchResults.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text(user.initials)),
                      title: Text(user.username),
                      subtitle: Text(user.email),
                      trailing: ElevatedButton(
                        onPressed: () => _addMate(user),
                        child: const Text('Add'),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
