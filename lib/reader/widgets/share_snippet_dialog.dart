import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/book.dart';
import '../../models/mate.dart';
import '../../profile/mate_avatar.dart';
import '../../services/mate_service.dart';
import '../../services/snippet_service.dart';
import '../../services/book_service.dart';

class ShareSnippetDialog extends StatefulWidget {
  const ShareSnippetDialog({
    required this.book,
    required this.snippetText,
    super.key,
  });

  final Book book;
  final String snippetText;

  @override
  State<ShareSnippetDialog> createState() => _ShareSnippetDialogState();
}

class _ShareSnippetDialogState extends State<ShareSnippetDialog> {
  final MateService _mateService = MateService();
  final SnippetService _snippetService = SnippetService();
  final BookService _bookService = BookService();
  final TextEditingController _noteController = TextEditingController();

  List<Mate> _mates = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;
  int? _selectedMateId;

  @override
  void initState() {
    super.initState();
    _loadMates();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadMates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final mates = await _mateService.getMates();
      if (!mounted) return;
      setState(() {
        _mates = mates;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<Book?> _ensureBookExists() async {
    // If book ID is negative (demo book), we need to add it to the library first
    if (widget.book.id <= 0) {
      try {
        // Add the demo book to the user's library
        final newBook = await _bookService.addBook(
          title: widget.book.title,
          author: widget.book.author,
          coverImageUrl: widget.book.coverImageUrl,
          progress: widget.book.progress,
        );

        if (!mounted) return null;

        return newBook;
      } catch (e) {
        if (!mounted) return null;
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isSending = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add book to library: ${_errorMessage ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
        return null;
      }
    }

    // Book already exists in library
    return widget.book;
  }

  Future<void> _sendSnippet() async {
    if (_selectedMateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a mate to send the snippet to'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (widget.snippetText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Snippet text cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      // Ensure the book exists in the library (for demo books)
      final bookToUse = await _ensureBookExists();
      if (bookToUse == null) {
        // Error already shown in _ensureBookExists
        return;
      }

      await _snippetService.sendSnippet(
        mateId: _selectedMateId!,
        bookId: bookToUse.id,
        text: widget.snippetText.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      if (!mounted) return;

      // Show success message
      final message = widget.book.id <= 0
          ? 'Book added to library and snippet sent successfully!'
          : 'Snippet sent successfully!';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      // Close dialog
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isSending = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send snippet: ${_errorMessage ?? 'Unknown error'}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 400.w,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share Snippet',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          widget.book.title,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.book.id <= 0)
                          Padding(
                            padding: EdgeInsets.only(top: 4.h),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 14.sp,
                                  color: colorScheme.primary,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'This book will be added to your library',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isSending ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Snippet Preview
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(maxHeight: 150.h),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Snippet Text:',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Text(
                          widget.snippetText,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Note Field
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: TextField(
                controller: _noteController,
                enabled: !_isSending,
                decoration: InputDecoration(
                  labelText: 'Add a note (optional)',
                  hintText: 'Tell your mate why you\'re sharing this...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  prefixIcon: const Icon(Icons.note_outlined),
                ),
                maxLines: 2,
                maxLength: 200,
              ),
            ),

            SizedBox(height: 16.h),

            // Mates List
            Flexible(
              child: _isLoading
                  ? Padding(
                      padding: EdgeInsets.all(40.w),
                      child: const CircularProgressIndicator(),
                    )
                  : _errorMessage != null
                      ? Padding(
                          padding: EdgeInsets.all(24.w),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48.sp,
                                color: colorScheme.error,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'Error loading mates',
                                style: theme.textTheme.titleMedium,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                _errorMessage!,
                                style: theme.textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 16.h),
                              ElevatedButton(
                                onPressed: _loadMates,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _mates.isEmpty
                          ? Padding(
                              padding: EdgeInsets.all(40.w),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 64.sp,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    'No mates yet',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'Add mates to start sharing snippets',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _mates.length,
                              itemBuilder: (context, index) {
                                final mate = _mates[index];
                                final mateUser = mate.mate;
                                final isSelected = _selectedMateId == mate.mateId;

                                return ListTile(
                                  enabled: !_isSending,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                    vertical: 8.h,
                                  ),
                                  leading: MateAvatar(
                                    mateUser: mateUser,
                                    mateId: mate.mateId,
                                    size: 50.w,
                                  ),
                                  title: Text(
                                    mateUser?.username ?? 'User ${mate.mateId}',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: mateUser?.email != null
                                      ? Text(
                                          mateUser!.email,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        )
                                      : null,
                                  trailing: isSelected
                                      ? Icon(
                                          Icons.check_circle,
                                          color: colorScheme.primary,
                                          size: 24.sp,
                                        )
                                      : null,
                                  selected: isSelected,
                                  selectedTileColor:
                                      colorScheme.primaryContainer.withValues(alpha: 0.3),
                                  onTap: () {
                                    setState(() {
                                      _selectedMateId = mate.mateId;
                                    });
                                  },
                                );
                              },
                            ),
            ),

            // Send Button
            Padding(
              padding: EdgeInsets.all(20.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSending || _selectedMateId == null
                      ? null
                      : _sendSnippet,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: _isSending
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20.w,
                              height: 20.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            const Text('Sending...'),
                          ],
                        )
                      : const Text('Send Snippet'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

