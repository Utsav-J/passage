import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

class ReaderControls extends StatefulWidget {
  const ReaderControls({
    super.key,
    required this.controller,
    required this.searchResults,
    required this.onSearch,
    required this.onSearchResultTap,
  });

  final EpubController? controller;
  final List<dynamic> searchResults;
  final void Function(String query) onSearch;
  final void Function(String cfi) onSearchResultTap;

  @override
  State<ReaderControls> createState() => _ReaderControlsState();
}

class _ReaderControlsState extends State<ReaderControls> {
  late final TextEditingController _textController;
  List<dynamic> _localSearchResults = [];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _localSearchResults = widget.searchResults;
  }

  @override
  void didUpdateWidget(ReaderControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchResults != oldWidget.searchResults) {
      setState(() {
        _localSearchResults = widget.searchResults;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final q = _textController.text.trim();
    if (q.isEmpty) return;
    widget.onSearch(q);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reader controls',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      labelText: 'Search in book',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                SizedBox(width: 8.w),
                FilledButton(
                  onPressed: _performSearch,
                  child: const Text('Search'),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 240.h),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _localSearchResults.length,
                itemBuilder: (context, index) {
                  final r = _localSearchResults[index] as dynamic;
                  final preview = (r?.excerpt ?? r?.text ?? 'Result');
                  return ListTile(
                    dense: true,
                    title: Text(
                      '$preview',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      final cfi = r?.cfi as String?;
                      if (cfi != null) {
                        Navigator.of(context).pop();
                        widget.onSearchResultTap(cfi);
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
                  onPressed: () =>
                      widget.controller?.setFlow(flow: EpubFlow.paginated),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.view_stream_outlined),
                  label: const Text('Flow: Scrolled'),
                  onPressed: () =>
                      widget.controller?.setFlow(flow: EpubFlow.scrolled),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.auto_awesome_motion),
                  label: const Text('Spread: Auto'),
                  onPressed: () =>
                      widget.controller?.setSpread(spread: EpubSpread.auto),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

