import 'dart:io';

import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'models/bookmark.dart';
import 'models/highlight.dart';
import 'services/epub_settings_service.dart';
import 'utils/color_utils.dart';
import 'utils/epub_theme_resolver.dart';
import 'widgets/empty_state.dart';
import 'widgets/progress_bar.dart';
import 'widgets/reader_controls.dart';
import 'widgets/reader_drawer.dart';
import 'widgets/highlight_context_menu.dart';

class EpubReaderPage extends StatefulWidget {
  const EpubReaderPage({super.key, this.assetPath});

  final String? assetPath; // If null, user can pick a file

  @override
  State<EpubReaderPage> createState() => _EpubReaderPageState();
}

class _EpubReaderPageState extends State<EpubReaderPage> {
  EpubController? _controller;
  EpubSource? _source;
  double _fontSize = 16.0;
  final List<Bookmark> _bookmarks = [];
  final List<Highlight> _highlights = [];
  String _progressLabel = '0%';
  double _progress = 0.0;
  List<dynamic> _chapters = const [];
  List<dynamic> _searchResults = const [];
  String? _selectedCfi;
  String? _selectedText;
  String? _openedSourceLabel;

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
    final settings = await EpubSettingsService.restoreSettings();
    setState(() {
      _fontSize = settings['fontSize'] as double;
      _bookmarks.clear();
      _bookmarks.addAll(settings['bookmarks'] as List<Bookmark>);
      _highlights.clear();
      _highlights.addAll(settings['highlights'] as List<Highlight>);
    });
  }

  Future<void> _persistSettings() async {
    await EpubSettingsService.persistSettings(
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
    await EpubSettingsService.savePosition(cfi);
  }

  Future<void> _addBookmark() async {
    final controller = _controller;
    if (controller == null) return;
    final loc = await controller.getCurrentLocation();
    final dyn = loc as dynamic;
    final cfi = (dyn?.startCfi ?? dyn?.cfi ?? '') as String;
    if (cfi.isEmpty) return;
    setState(() {
      _bookmarks.add(
        Bookmark(label: 'Bookmark ${_bookmarks.length + 1}', cfi: cfi),
      );
    });
    _persistSettings();
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

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
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
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'Bookmark',
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
              onChapterTap: (cfi) => _controller?.display(cfi: cfi),
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
                  final cfi = await EpubSettingsService.getLastPosition();
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
                    _selectedCfi = (cfi != null && cfi.isNotEmpty) ? cfi : null;
                    _selectedText = text ?? '';
                  });
                },
                selectionContextMenu: HighlightContextMenu.build(
                  onHighlight: _applyHighlight,
                ),
                onRelocated: (loc) {
                  final v = loc as dynamic;
                  final p = (v?.progress ?? 0.0).clamp(0.0, 1.0);
                  setState(() {
                    _progress = p;
                    _progressLabel = '${(p * 100).toStringAsFixed(0)}%';
                  });
                },
              ),
            ),
      bottomNavigationBar: (controller == null || _source == null)
          ? null
          : ProgressBar(progress: _progress, label: _progressLabel),
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
}
