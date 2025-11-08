import 'dart:io';

import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/book.dart';
import 'models/bookmark.dart';
import 'models/highlight.dart';
import 'services/epub_settings_service.dart';
import 'utils/color_utils.dart';
import 'utils/epub_theme_resolver.dart';
import 'widgets/empty_state.dart';
import 'widgets/reader_controls.dart';
import 'widgets/reader_drawer.dart';
import 'widgets/highlight_context_menu.dart';
import 'widgets/share_snippet_dialog.dart';

class EpubReaderPage extends StatefulWidget {
  const EpubReaderPage({
    super.key,
    this.assetPath,
    this.book,
  });

  final String? assetPath; // If null, user can pick a file
  final Book? book; // Book metadata for snippet sharing

  @override
  State<EpubReaderPage> createState() => _EpubReaderPageState();
}

class _EpubReaderPageState extends State<EpubReaderPage> {
  EpubController? _controller;
  EpubSource? _source;
  double _fontSize = 16.0;
  final List<Bookmark> _bookmarks = [];
  final List<Highlight> _highlights = [];
  double _maxProgress = 0.0;
  List<dynamic> _chapters = const [];
  List<dynamic> _searchResults = const [];
  String? _selectedCfi;
  String? _selectedText;
  String? _openedSourceLabel;
  String? _currentCfi;
  int? _currentPage;

  // Generate book ID from asset path
  String get _bookId => widget.assetPath ?? 'unknown';

  @override
  void initState() {
    super.initState();
    // If assetPath is provided, initialize immediately
    if (widget.assetPath != null) {
      _initializeAsset();
    }
    // Restore settings and apply font size if asset is already loaded
    _restoreSettings().then((_) {
      if (_controller != null) {
        _controller!.setFontSize(fontSize: _fontSize);
      }
      if (widget.assetPath == null) {
        // Only open initial if no asset path (for file picker flow)
        _openInitial();
      }
    });
  }

  void _initializeAsset() {
    final controller = EpubController();
    setState(() {
      _openedSourceLabel = 'Asset';
      _controller = controller;
      _source = EpubSource.fromAsset(widget.assetPath!);
    });
  }

  Future<void> _restoreSettings() async {
    final settings = await EpubSettingsService.restoreSettings(_bookId);
    final maxProgress = await EpubSettingsService.getMaxProgress(_bookId);
    setState(() {
      _fontSize = settings['fontSize'] as double;
      _bookmarks.clear();
      _bookmarks.addAll(settings['bookmarks'] as List<Bookmark>);
      _highlights.clear();
      _highlights.addAll(settings['highlights'] as List<Highlight>);
      _maxProgress = maxProgress;
    });
  }

  Future<void> _persistSettings() async {
    await EpubSettingsService.persistSettings(
      bookId: _bookId,
      fontSize: _fontSize,
      bookmarks: _bookmarks,
      highlights: _highlights,
    );
  }

  Future<void> _openInitial() async {
    if (widget.assetPath != null) {
      await _openDocumentFromAsset(widget.assetPath!);
    }
  }

  Future<void> _openDocumentFromAsset(String assetPath) async {
    _controller = null;
    final controller = EpubController();
    setState(() {
      _openedSourceLabel = 'Asset';
      _controller = controller;
      _source = EpubSource.fromAsset(assetPath);
    });
    controller.setFontSize(fontSize: _fontSize);
    setState(() => _chapters = const []);
  }

  Future<void> _openDocumentFromFile(String filePath) async {
    _controller = null;
    final controller = EpubController();
    setState(() {
      _openedSourceLabel = 'File';
      _controller = controller;
      _source = EpubSource.fromFile(File(filePath));
    });
    controller.setFontSize(fontSize: _fontSize);
    setState(() => _chapters = const []);
  }

  Future<void> _pickEpub() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'],
    );
    final filePath = result?.files.single.path;
    if (filePath != null) {
      await _openDocumentFromFile(filePath);
    }
  }

  Future<void> _savePosition() async {
    String cfi = '';
    final controller = _controller;
    if (controller != null) {
      final loc = await controller.getCurrentLocation();
      final dyn = loc as dynamic;
      cfi = (dyn?.startCfi ?? dyn?.cfi ?? '') as String;
    }
    await EpubSettingsService.savePosition(_bookId, cfi);
    await EpubSettingsService.saveMaxProgress(_bookId, _maxProgress);
  }

  Future<void> _addBookmark() async {
    final controller = _controller;
    if (controller == null) return;
    final loc = await controller.getCurrentLocation();
    final dyn = loc as dynamic;
    final cfi = (dyn?.startCfi ?? dyn?.cfi ?? '') as String;
    if (cfi.isEmpty) return;

    // Check if this page is already bookmarked
    final existingIndex = _bookmarks.indexWhere((b) => b.cfi == cfi);
    if (existingIndex != -1) {
      // Remove the bookmark if it already exists
      setState(() {
        _bookmarks.removeAt(existingIndex);
      });
      _persistSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bookmark removed'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    // Add new bookmark with page number
    final pageNumber = _currentPage;
    final label = pageNumber != null
        ? 'Page $pageNumber'
        : 'Bookmark ${_bookmarks.length + 1}';
    setState(() {
      _bookmarks.add(Bookmark(label: label, cfi: cfi, pageNumber: pageNumber));
    });
    _persistSettings();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bookmark added: $label'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  bool _isCurrentPageBookmarked() {
    if (_currentCfi == null || _currentCfi!.isEmpty) return false;
    return _bookmarks.any((b) => b.cfi == _currentCfi);
  }

  void _goToBookmark(Bookmark b) {
    _controller?.display(cfi: b.cfi);
  }

  void _increaseFont() {
    setState(() {
      _fontSize = (_fontSize + 1).clamp(12.0, 28.0);
    });
    _controller?.setFontSize(fontSize: _fontSize);
    _persistSettings();
  }

  void _decreaseFont() {
    setState(() {
      _fontSize = (_fontSize - 1).clamp(12.0, 28.0);
    });
    _controller?.setFontSize(fontSize: _fontSize);
    _persistSettings();
  }

  @override
  void dispose() {
    _savePosition();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    // Save current position before showing dialog
    await _savePosition();

    // Show confirmation dialog
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Book?'),
        content: const Text(
          'Your reading progress has been saved. Do you want to close this book?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Close'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _openedSourceLabel == null
                ? 'EPUB Reader'
                : 'EPUB Reader • ${_openedSourceLabel!}',
          ),
          actions: [
            IconButton(
              onPressed: _openControls,
              icon: const Icon(Icons.tune),
              tooltip: 'Reader controls',
            ),
            IconButton(
              onPressed: _decreaseFont,
              icon: const Icon(Icons.text_decrease),
              tooltip: 'Smaller',
            ),
            IconButton(
              onPressed: _increaseFont,
              icon: const Icon(Icons.text_increase),
              tooltip: 'Larger',
            ),
            IconButton(
              onPressed: _addBookmark,
              icon: Icon(
                _isCurrentPageBookmarked()
                    ? Icons.bookmark
                    : Icons.bookmark_add_outlined,
              ),
              tooltip: _isCurrentPageBookmarked()
                  ? 'Remove bookmark'
                  : 'Add bookmark',
            ),
            IconButton(
              onPressed: _pickEpub,
              icon: const Icon(Icons.folder_open),
              tooltip: 'Open EPUB',
            ),
          ],
        ),
        drawer: controller == null
            ? null
            : ReaderDrawer(
                chapters: _chapters,
                bookmarks: _bookmarks,
                highlights: _highlights,
                controller: controller,
                progress: _maxProgress,
                progressLabel: '${(_maxProgress * 100).toStringAsFixed(0)}%',
                onChapterTap: (href) {
                  // Navigate using href - the display method can handle both cfi and href
                  if (href.isNotEmpty) {
                    try {
                      // The flutter_epub_viewer display method accepts href as cfi parameter
                      _controller?.display(cfi: href);
                    } catch (e) {
                      debugPrint('Failed to navigate to chapter: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to navigate to chapter'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  }
                },
                onBookmarkTap: _goToBookmark,
                onBookmarkDelete: (index) {
                  setState(() => _bookmarks.removeAt(index));
                  _persistSettings();
                },
                onHighlightTap: (cfi) => _controller?.display(cfi: cfi),
                onHighlightDelete: (index, cfi) async {
                  setState(() => _highlights.removeAt(index));
                  _persistSettings();
                  await _controller?.removeHighlight(cfi: cfi);
                },
              ),
        body: (controller == null || _source == null)
            ? EmptyState(
                isLoading: widget.assetPath != null,
                onPickFile: _pickEpub,
              )
            : SafeArea(
                child: EpubViewer(
                  epubSource: _source!,
                  epubController: controller,
                  displaySettings: EpubDisplaySettings(
                    flow: EpubFlow.paginated,
                    snap: true,
                    theme: EpubThemeResolver.resolve(context),
                  ),
                  onChaptersLoaded: (chapters) async {
                    setState(() => _chapters = chapters);
                  },
                  onEpubLoaded: () async {
                    final cfi = await EpubSettingsService.getLastPosition(
                      _bookId,
                    );
                    if (cfi != null && cfi.isNotEmpty) {
                      controller.display(cfi: cfi);
                    }
                    // Re-apply saved highlights
                    for (final highlight in _highlights) {
                      await controller.addHighlight(
                        cfi: highlight.cfi,
                        color: highlight.color,
                        opacity: 0.5,
                      );
                    }
                  },
                  onTextSelected: (sel) {
                    final s = sel as dynamic;
                    final cfi = s?.selectionCfi as String?;
                    final text = s?.selectedText as String?;
                    setState(() {
                      _selectedCfi = (cfi != null && cfi.isNotEmpty)
                          ? cfi
                          : null;
                      _selectedText = text ?? '';
                    });
                  },
                  selectionContextMenu: HighlightContextMenu.build(
                    onHighlight: _applyHighlight,
                    onShareSnippet: widget.book != null ? _showShareSnippetDialog : null,
                  ),
                  onRelocated: (loc) {
                    final v = loc as dynamic;
                    final p = (v?.progress ?? 0.0).clamp(0.0, 1.0);
                    final cfi = (v?.startCfi ?? v?.cfi ?? '') as String;

                    // Try to extract page number from location
                    int? pageNum;
                    try {
                      final displayed = v?.displayed as dynamic;
                      final page = displayed?.page;
                      if (page != null) {
                        pageNum = page as int;
                      }
                    } catch (e) {
                      // Page number not available
                    }

                    setState(() {
                      _currentCfi = cfi;
                      _currentPage = pageNum;

                      // Update max progress
                      if (p > _maxProgress) {
                        _maxProgress = p;
                      }
                    });
                  },
                ),
              ),
      ),
    );
  }

  Future<void> _applyHighlight(Color color) async {
    final cfi = _selectedCfi;
    final text = _selectedText ?? '';

    if (cfi == null || cfi.isEmpty) return;

    await _controller?.addHighlight(cfi: cfi, color: color, opacity: 0.5);

    setState(() {
      _highlights.add(Highlight(cfi: cfi, color: color, text: text));
      _selectedCfi = null;
      _selectedText = null;
    });

    _persistSettings();

    // Show feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
              SizedBox(width: 8.w),
              Text('Text highlighted in ${ColorUtils.getColorName(color)}'),
            ],
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: color,
        ),
      );
    }
  }

  void _openControls() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return ReaderControls(
              controller: _controller,
              searchResults: _searchResults,
              onSearch: (query) async {
                final results = await _controller?.search(query: query) ?? [];
                setState(() {
                  _searchResults = results;
                });
                setSheetState(() {});
              },
              onSearchResultTap: (cfi) {
                _controller?.display(cfi: cfi);
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showShareSnippetDialog() async {
    if (widget.book == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book information not available'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (_selectedText == null || _selectedText!.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No text selected. Please select some text to share.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ShareSnippetDialog(
        book: widget.book!,
        snippetText: _selectedText!.trim(),
      ),
    );

    // Clear selection after sharing (if successful)
    if (result == true && mounted) {
      setState(() {
        _selectedText = null;
        _selectedCfi = null;
      });
    }
  }
}
