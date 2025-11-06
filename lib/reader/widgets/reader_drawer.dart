import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import '../models/bookmark.dart';
import '../models/highlight.dart';
import '../utils/color_utils.dart';

class ReaderDrawer extends StatelessWidget {
  const ReaderDrawer({
    super.key,
    required this.chapters,
    required this.bookmarks,
    required this.highlights,
    required this.controller,
    required this.onChapterTap,
    required this.onBookmarkTap,
    required this.onBookmarkDelete,
    required this.onHighlightTap,
    required this.onHighlightDelete,
  });

  final List<dynamic> chapters;
  final List<Bookmark> bookmarks;
  final List<Highlight> highlights;
  final EpubController? controller;
  final void Function(String cfi) onChapterTap;
  final void Function(Bookmark) onBookmarkTap;
  final void Function(int index) onBookmarkDelete;
  final void Function(String cfi) onHighlightTap;
  final void Function(int index, String cfi) onHighlightDelete;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Table of Contents
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                'Table of Contents',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: chapters.length,
                itemBuilder: (context, index) {
                  final chapter = chapters[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      (chapter as dynamic).title ??
                          (chapter as dynamic).label ??
                          (chapter as dynamic).href ??
                          'Chapter ${index + 1}',
                    ),
                    onTap: () {
                      final dyn = chapter as dynamic;
                      final cfi = dyn.cfi as String?;
                      if (cfi != null && cfi.isNotEmpty) {
                        onChapterTap(cfi);
                      }
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            // Bookmarks
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                'Bookmarks',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: bookmarks.length,
                itemBuilder: (context, index) {
                  final b = bookmarks[index];
                  return ListTile(
                    onTap: () => onBookmarkTap(b),
                    dense: true,
                    leading: const Icon(Icons.bookmark_outline),
                    title: Text(b.label),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => onBookmarkDelete(index),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            // Highlights
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                'Highlights',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: highlights.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Text(
                          'No highlights yet',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                              ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: highlights.length,
                      itemBuilder: (context, index) {
                        final h = highlights[index];
                        return ListTile(
                          onTap: () => onHighlightTap(h.cfi),
                          dense: true,
                          leading: Container(
                            width: 32.w,
                            height: 32.h,
                            decoration: BoxDecoration(
                              color: h.color.withOpacity(0.3),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: h.color,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.highlight_outlined,
                              size: 18.sp,
                              color: h.color,
                            ),
                          ),
                          title: Text(
                            h.text.isNotEmpty
                                ? (h.text.length > 50
                                      ? '${h.text.substring(0, 50)}...'
                                      : h.text)
                                : 'Highlight ${index + 1}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          subtitle: Text(
                            ColorUtils.getColorName(h.color),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: h.color,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => onHighlightDelete(index, h.cfi),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

