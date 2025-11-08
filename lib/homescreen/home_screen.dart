import 'dart:async';
import 'package:flutter/material.dart';
import 'package:passage/homescreen/add_mate_dialog.dart';
import 'package:passage/homescreen/my_books_tab.dart';
import 'package:passage/homescreen/my_mates_tab.dart';
import 'package:passage/reader/epub_reader_page.dart';
import 'package:passage/theme/app_theme.dart';
import 'package:passage/models/book.dart';
import 'package:passage/models/mate.dart';
import 'package:passage/services/book_service.dart';
import 'package:passage/services/auth_service.dart';
import 'package:passage/services/snippet_service.dart';
import 'package:passage/services/mate_service.dart';
import 'package:passage/auth/login_screen.dart';
import '../profile/profile_screen.dart';
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
          MyBooksTab(
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
      builder: (context) => const AddMateDialog(),
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