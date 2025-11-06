import 'dart:convert';
import 'dart:io';

import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EpubReaderPage extends StatefulWidget {
  const EpubReaderPage({super.key, this.assetPath});

  final String? assetPath; // If null, user can pick a file

  @override
  State<EpubReaderPage> createState() => _EpubReaderPageState();
}

class _EpubReaderPageState extends State<EpubReaderPage> {
  EpubController? _controller;
  EpubSource? _source;
  double _fontSize = 16.0; // logical font size for viewer
  final List<_Bookmark> _bookmarks = [];
  final List<_Highlight> _highlights = [];
  String _progressLabel = '0%';
  double _progress = 0.0;
  List<dynamic> _chapters = const [];
  List<dynamic> _searchResults = const [];
  String? _selectedCfi;
  String? _selectedText;
  String _prefsKeyCfi = 'last_epub_cfi';
  String _prefsKeyFont = 'font_size';
  String _prefsKeyBookmarks = 'bookmarks_cfi';
  String _prefsKeyHighlights = 'highlights_json';
  String? _openedSourceLabel;
  
  // Highlight colors
  static const List<Color> _highlightColors = [
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.pink,
    Colors.orange,
    Colors.purple,
  ];

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
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble(_prefsKeyFont) ?? 16.0;
    final savedBookmarks = prefs.getStringList(_prefsKeyBookmarks) ?? <String>[];
    _bookmarks
      ..clear()
      ..addAll(savedBookmarks.map((e) => _Bookmark(label: 'Bookmark', cfi: e)));
    
    // Restore highlights
    final highlightsJson = prefs.getString(_prefsKeyHighlights);
    _highlights.clear();
    if (highlightsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(highlightsJson);
        _highlights.addAll(
          decoded.map((e) => _Highlight.fromJson(e as Map<String, dynamic>)),
        );
      } catch (e) {
        // Ignore invalid JSON
      }
    }
  }

  Future<void> _persistSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefsKeyFont, _fontSize);
    await prefs.setStringList(_prefsKeyBookmarks, _bookmarks.map((b) => b.cfi).toList());
    final highlightsJson = jsonEncode(_highlights.map((h) => h.toJson()).toList());
    await prefs.setString(_prefsKeyHighlights, highlightsJson);
  }

  Future<void> _openInitial() async {
    if (widget.assetPath != null) {
      await _openDocumentFromAsset(widget.assetPath!);
    } else {
      // idle, wait for user to pick
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
    // No await needed for widget; initialCfi applied below
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
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['epub']);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyCfi, cfi);
  }

  Future<void> _addBookmark() async {
    final controller = _controller;
    if (controller == null) return;
    final loc = await controller.getCurrentLocation();
    final dyn = loc as dynamic;
    final cfi = (dyn?.startCfi ?? dyn?.cfi ?? '') as String;
    if (cfi.isEmpty) return;
    setState(() {
      _bookmarks.add(_Bookmark(label: 'Bookmark ${_bookmarks.length + 1}', cfi: cfi));
    });
    _persistSettings();
  }

  void _goToBookmark(_Bookmark b) {
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
    // no dispose on controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(
        title: Text(_openedSourceLabel == null ? 'EPUB Reader' : 'EPUB Reader • ${_openedSourceLabel!}'),
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
          : Drawer(
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Text('Table of Contents', style: Theme.of(context).textTheme.titleLarge),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _chapters.length,
                        itemBuilder: (context, index) {
                          final chapter = _chapters[index];
                          return ListTile(
                            dense: true,
                            title: Text((chapter as dynamic).title ?? (chapter as dynamic).label ?? (chapter as dynamic).href ?? 'Chapter ${index + 1}'),
                            onTap: () {
                              final dyn = chapter as dynamic;
                              final cfi = dyn.cfi as String?;
                              if (cfi != null && cfi.isNotEmpty) {
                                _controller?.display(cfi: cfi);
                              }
                            },
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Text('Bookmarks', style: Theme.of(context).textTheme.titleLarge),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _bookmarks.length,
                        itemBuilder: (context, index) {
                          final b = _bookmarks[index];
                          return ListTile(
                            onTap: () => _goToBookmark(b),
                            dense: true,
                            leading: const Icon(Icons.bookmark_outline),
                            title: Text(b.label),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () {
                                setState(() => _bookmarks.removeAt(index));
                                _persistSettings();
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Text('Highlights', style: Theme.of(context).textTheme.titleLarge),
                    ),
                    Expanded(
                      child: _highlights.isEmpty
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.w),
                                child: Text(
                                  'No highlights yet',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _highlights.length,
                              itemBuilder: (context, index) {
                                final h = _highlights[index];
                                return ListTile(
                                  onTap: () => _controller?.display(cfi: h.cfi),
                                  dense: true,
                                  leading: Container(
                                    width: 32.w,
                                    height: 32.h,
                                    decoration: BoxDecoration(
                                      color: h.color.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: h.color, width: 2),
                                    ),
                                    child: Icon(
                                      Icons.highlight_outlined,
                                      size: 18.sp,
                                      color: h.color,
                                    ),
                                  ),
                                  title: Text(
                                    h.text.isNotEmpty
                                        ? (h.text.length > 50 ? '${h.text.substring(0, 50)}...' : h.text)
                                        : 'Highlight ${index + 1}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  subtitle: Text(
                                    _getColorName(h.color),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: h.color,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () async {
                                      final cfi = h.cfi;
                                      setState(() => _highlights.removeAt(index));
                                      _persistSettings();
                                      await _controller?.removeHighlight(cfi: cfi);
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
      body: (controller == null || _source == null)
          ? _buildEmptyState()
          : SafeArea(
              child: EpubViewer(
                epubSource: _source!,
                epubController: controller,
                displaySettings: EpubDisplaySettings(
                  flow: EpubFlow.paginated,
                  snap: true,
                  theme: _resolveEpubTheme(context),
                ),
                onChaptersLoaded: (chapters) async {
                  setState(() => _chapters = chapters);
                },
                onEpubLoaded: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final cfi = prefs.getString(_prefsKeyCfi);
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
                selectionContextMenu: _buildHighlightContextMenu(),
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
          : _buildProgressBar(),
    );
  }

  Widget _buildEmptyState() {
    // If assetPath is provided, show loading state instead of file picker
    if (widget.assetPath != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              SizedBox(height: 16.h),
              Text(
                'Loading book...',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }
    
    // Otherwise show file picker option
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined, size: 72.sp),
            SizedBox(height: 16.h),
            Text(
              'Open an EPUB to start reading',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 12.h),
            FilledButton.icon(
              onPressed: _pickEpub,
              icon: const Icon(Icons.folder_open),
              label: const Text('Pick EPUB'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = _progress.clamp(0.0, 1.0);
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(value: progress),
          ),
          SizedBox(width: 12.w),
          Text(_progressLabel),
        ],
      ),
    );
  }

  EpubTheme _resolveEpubTheme(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.scaffoldBackgroundColor;
    final fg = theme.colorScheme.onBackground;
    return EpubTheme.custom(
      backgroundColor: bg,
      foregroundColor: fg,
    );
  }

  ContextMenu _buildHighlightContextMenu() {
    final menuItems = <ContextMenuItem>[];
    
    // Add highlight color options
    // Start from 1 to avoid conflicts with system menu items (0 is typically reserved)
    for (int i = 0; i < _highlightColors.length; i++) {
      final color = _highlightColors[i];
      menuItems.add(
        ContextMenuItem(
          id: i + 1, // Use integer ID starting from 1
          title: 'Highlight (${_getColorName(color)})',
          action: () => _applyHighlight(color),
        ),
      );
    }
    
    return ContextMenu(
      settings: ContextMenuSettings(
        hideDefaultSystemContextMenuItems: false,
      ),
      menuItems: menuItems,
    );
  }

  Future<void> _applyHighlight(Color color) async {
    final cfi = _selectedCfi;
    final text = _selectedText ?? '';
    
    if (cfi == null || cfi.isEmpty) return;
    
    await _controller?.addHighlight(cfi: cfi, color: color, opacity: 0.5);
    
    setState(() {
      _highlights.add(_Highlight(
        cfi: cfi,
        color: color,
        text: text,
      ));
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
              Text('Text highlighted in ${_getColorName(color)}'),
            ],
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: color,
        ),
      );
    }
  }

  String _getColorName(Color color) {
    if (color == Colors.yellow) return 'Yellow';
    if (color == Colors.green) return 'Green';
    if (color == Colors.blue) return 'Blue';
    if (color == Colors.pink) return 'Pink';
    if (color == Colors.orange) return 'Orange';
    if (color == Colors.purple) return 'Purple';
    return 'Custom';
  }


  void _openControls() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final controller = _controller;
        final textController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reader controls', style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: textController,
                            decoration: const InputDecoration(
                              labelText: 'Search in book',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) async {
                              final q = textController.text.trim();
                              if (q.isEmpty) return;
                              final results = await controller?.search(query: q) ?? [];
                              setSheetState(() => _searchResults = results);
                            },
                          ),
                        ),
                        SizedBox(width: 8.w),
                        FilledButton(
                          onPressed: () async {
                            final q = textController.text.trim();
                            if (q.isEmpty) return;
                            final results = await controller?.search(query: q) ?? [];
                            setSheetState(() => _searchResults = results);
                          },
                          child: const Text('Search'),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 240.h),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final r = _searchResults[index] as dynamic;
                          final preview = (r?.excerpt ?? r?.text ?? 'Result');
                          return ListTile(
                            dense: true,
                            title: Text('$preview', maxLines: 2, overflow: TextOverflow.ellipsis),
                            onTap: () {
                              final cfi = r?.cfi as String?;
                              if (cfi != null) {
                                Navigator.of(context).pop();
                                _controller?.display(cfi: cfi);
                              }
                            },
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.view_agenda_outlined),
                          label: const Text('Flow: Paginated'),
                          onPressed: () => _controller?.setFlow(flow: EpubFlow.paginated),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.view_stream_outlined),
                          label: const Text('Flow: Scrolled'),
                          onPressed: () => _controller?.setFlow(flow: EpubFlow.scrolled),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.auto_awesome_motion),
                          label: const Text('Spread: Auto'),
                          onPressed: () => _controller?.setSpread(spread: EpubSpread.auto),
                        ),
                        // Additional spread options can be added if exposed by the package
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _Bookmark {
  _Bookmark({required this.label, required this.cfi});
  final String label;
  final String cfi;
}

class _Highlight {
  _Highlight({
    required this.cfi,
    required this.color,
    required this.text,
  });

  final String cfi;
  final Color color;
  final String text;

  Map<String, dynamic> toJson() {
    return {
      'cfi': cfi,
      'color': color.value,
      'text': text,
    };
  }

  factory _Highlight.fromJson(Map<String, dynamic> json) {
    return _Highlight(
      cfi: json['cfi'] as String,
      color: Color(json['color'] as int? ?? Colors.yellow.value),
      text: json['text'] as String? ?? '',
    );
  }
}

