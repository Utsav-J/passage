import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'package:passage/services/epub_metadata_service.dart';
import 'package:passage/utils/image_utils.dart';
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
  final EpubMetadataService _epubMetadataService = EpubMetadataService();
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

      // Ensure the sample book exists in the library
      final sampleBookTitle = 'Sample Book';
      final sampleBookAuthor = 'Demo Author';
      var sampleBook = books.firstWhere(
        (book) => book.title == sampleBookTitle && book.author == sampleBookAuthor,
        orElse: () => Book(
          id: -1,
          title: sampleBookTitle,
          author: sampleBookAuthor,
          ownerId: 0,
          progress: 0.0,
          createdAt: DateTime.now(),
        ),
      );

      final hasSampleBook = sampleBook.id > 0;

      if (!hasSampleBook) {
        try {
          // Extract metadata from sample EPUB asset
          final metadata = await _epubMetadataService.extractMetadata(
            _defaultAssetPath,
            isAsset: true,
          );

          // Determine cover image
          String? coverImageUrl;
          if (metadata.coverImageBytes != null && metadata.coverImageBytes!.isNotEmpty) {
            coverImageUrl = ImageUtils.bytesToBase64DataUrlAuto(metadata.coverImageBytes!);
          } else if (metadata.firstPageImageBytes != null && metadata.firstPageImageBytes!.isNotEmpty) {
            coverImageUrl = ImageUtils.bytesToBase64DataUrlAuto(metadata.firstPageImageBytes!);
          }

          // Add sample book with extracted metadata
          await _bookService.addBook(
            title: metadata.title,
            author: metadata.author,
            coverImageUrl: coverImageUrl,
            progress: 0.0,
          );
          // Reload books to get the newly added sample book
          final updatedBooks = await _bookService.getMyBooks();
          if (!mounted) return;
          setState(() {
            _books = updatedBooks;
            _isLoadingBooks = false;
          });
        } catch (e) {
          // If adding sample book fails, try with default metadata
          try {
            await _bookService.addBook(
              title: sampleBookTitle,
              author: sampleBookAuthor,
              coverImageUrl: null,
              progress: 0.0,
            );
            final updatedBooks = await _bookService.getMyBooks();
            if (!mounted) return;
            setState(() {
              _books = updatedBooks;
              _isLoadingBooks = false;
            });
          } catch (e2) {
            // If adding sample book fails, just use the existing books
            if (!mounted) return;
            setState(() {
              _books = books;
              _isLoadingBooks = false;
            });
          }
        }
      } else {
        // Note: If sample book has default metadata, we could extract and update it
        // For now, we'll use the existing book since we don't have an update endpoint
        // TODO: Add book update endpoint if metadata update is needed

        setState(() {
          _books = books;
          _isLoadingBooks = false;
        });
      }
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

  Future<void> _openBook(Book book) async {
    // Check if this book has a stored file path
    final filePath = await _getBookFilePath(book.id);
    
    // Determine if this is the sample book (always use asset path)
    final isSampleBook = book.title == 'Sample Book' && book.author == 'Demo Author';
    
    if (isSampleBook) {
      // Sample book always uses asset path
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EpubReaderPage(
            assetPath: _defaultAssetPath,
            book: book,
          ),
        ),
      );
    } else if (filePath != null && await File(filePath).exists()) {
      // Book has a stored file path, use it
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EpubReaderPage(
            filePath: filePath,
            book: book,
          ),
        ),
      );
    } else {
      // Fallback to asset path (should not happen for user-added books)
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EpubReaderPage(
            assetPath: _defaultAssetPath,
            book: book,
          ),
        ),
      );
    }
  }

  /// Store file path for a book
  Future<void> _storeBookFilePath(int bookId, String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('book_file_path_$bookId', filePath);
  }

  /// Get file path for a book
  Future<String?> _getBookFilePath(int bookId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('book_file_path_$bookId');
  }

  Future<void> _showAddBookDialog() async {
    // Pick EPUB file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'],
    );

    if (result == null || result.files.single.path == null) {
      return; // User cancelled
    }

    final filePath = result.files.single.path!;

    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Extract metadata from EPUB
      final metadata = await _epubMetadataService.extractMetadata(filePath);

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      // Determine cover image
      String? coverImageUrl;
      if (metadata.coverImageBytes != null && metadata.coverImageBytes!.isNotEmpty) {
        coverImageUrl = ImageUtils.bytesToBase64DataUrlAuto(metadata.coverImageBytes!);
      } else if (metadata.firstPageImageBytes != null && metadata.firstPageImageBytes!.isNotEmpty) {
        coverImageUrl = ImageUtils.bytesToBase64DataUrlAuto(metadata.firstPageImageBytes!);
      }

      // Show preview dialog
      final confirmResult = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add Book'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (coverImageUrl != null)
                  Container(
                    height: 200.h,
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 16.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: ImageUtils.isBase64DataUrl(coverImageUrl)
                        ? Builder(
                            builder: (context) {
                              final imageBytes = _decodeBase64Image(coverImageUrl);
                              if (imageBytes != null) {
                                return Image.memory(
                                  imageBytes,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(child: Icon(Icons.error));
                                  },
                                );
                              }
                              return const Center(child: Icon(Icons.error));
                            },
                          )
                        : Image.network(
                            coverImageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(child: Icon(Icons.error));
                            },
                          ),
                  ),
                Text(
                  'Title: ${metadata.title}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Author: ${metadata.author}',
                  style: Theme.of(context).textTheme.bodyMedium,
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
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Add Book'),
            ),
          ],
        ),
      );

      if (confirmResult == true) {
        // Add book to backend
        final addedBook = await _bookService.addBook(
          title: metadata.title,
          author: metadata.author,
          coverImageUrl: coverImageUrl,
        );
        
        // Store file path locally for this book
        if (addedBook.id > 0) {
          await _storeBookFilePath(addedBook.id, filePath);
        }
        
        if (!mounted) return;
        _loadBooks();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book added successfully')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error extracting EPUB: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Uint8List? _decodeBase64Image(String? dataUrl) {
    if (dataUrl == null) return null;
    try {
      final base64String = ImageUtils.extractBase64FromDataUrl(dataUrl);
      return base64Decode(base64String);
    } catch (e) {
      return null;
    }
  }

  Future<void> _deleteBook(int bookId) async {
    // Find the book to check if it's the sample book
    final book = _books.firstWhere((b) => b.id == bookId, orElse: () => _books.first);
    
    // Prevent deletion of the sample book
    if (book.title == 'Sample Book' && book.author == 'Demo Author') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete the sample book'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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