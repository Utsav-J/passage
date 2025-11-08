import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:passage/homescreen/mate_card.dart';
import 'package:passage/homescreen/mate_requests_dialog.dart';
import 'package:passage/homescreen/message_card.dart';
import 'package:passage/homescreen/requests_button.dart';
import 'package:passage/models/mate.dart';
import 'package:passage/models/snippet.dart';
import 'package:passage/homescreen/section_header.dart';
import 'package:passage/services/mate_service.dart';
import 'package:passage/services/snippet_service.dart';
import 'package:passage/profile/mate_detail_dialog.dart';

class MyMatesTab extends StatefulWidget {
  const MyMatesTab({super.key});

  @override
  State<MyMatesTab> createState() => MyMatesTabState();
}

class MyMatesTabState extends State<MyMatesTab> {
  final SnippetService _snippetService = SnippetService();
  final MateService _mateService = MateService();
  List<Snippet> _snippets = [];
  List<Mate> _mates = [];
  bool _isLoadingMates = true;
  bool _isLoadingSnippets = true;
  String? _errorMessageMates;
  String? _errorMessageSnippets;

  @override
  void initState() {
    super.initState();
    _loadMates();
    _loadSnippets();
  }

  Future<void> _loadMates() async {
    setState(() {
      _isLoadingMates = true;
      _errorMessageMates = null;
    });

    try {
      final mates = await _mateService.getMates();
      if (!mounted) return;
      setState(() {
        _mates = mates;
        _isLoadingMates = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessageMates = e.toString().replaceFirst('Exception: ', '');
        _isLoadingMates = false;
      });
    }
  }

  Future<void> _loadSnippets() async {
    setState(() {
      _isLoadingSnippets = true;
      _errorMessageSnippets = null;
    });

    try {
      final snippets = await _snippetService.getReceivedSnippets();
      if (!mounted) return;
      setState(() {
        _snippets = snippets;
        _isLoadingSnippets = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessageSnippets = e.toString().replaceFirst('Exception: ', '');
        _isLoadingSnippets = false;
      });
    }
  }

  Future<void> _removeMate(String username) async {
    try {
      await _mateService.removeMate(username);
      if (!mounted) return;
      _loadMates();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mate removed successfully')),
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

  void _showMateDetailDialog(Mate mate) {
    final mateUser = mate.mate;
    showDialog(
      context: context,
      builder: (context) => MateDetailDialog(mate: mate, mateUser: mateUser),
    );
  }

  Future<void> _showMateRequestsDialog() async {
    await showDialog(
      context: context,
      builder: (context) => const MateRequestsDialog(),
    );
  }

  /// Builds an adaptive mates list that adjusts to content height dynamically
  /// Uses LayoutBuilder to get constraints and SingleChildScrollView with Row
  /// for responsive sizing across different screen sizes
  Widget _buildAdaptiveMatesList() {
    if (_mates.isEmpty) {
      return const SizedBox.shrink();
    }

    // Use LayoutBuilder to get available constraints and calculate responsive height
    // MateCard structure: Avatar (60.w) + spacing (8.h) + text (~20.h)
    // Since w and h scale with screen size, we calculate dynamically
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate height based on content structure
        // Avatar size (60.w) + spacing (8.h) + text line height (~24.h with font scaling)
        // Add some padding for safety
        final avatarHeight = 60.w; // Avatar diameter
        final spacing = 8.h; // Spacing between avatar and text
        final textHeight = 24.h; // Approximate text height
        final calculatedHeight = avatarHeight + spacing + textHeight;

        // Use SingleChildScrollView with Row for horizontal scrolling
        // Constrain height to calculated value but allow Row to size naturally
        return SizedBox(
          height: calculatedHeight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int index = 0; index < _mates.length; index++) ...[
                  if (index > 0) SizedBox(width: 16.w),
                  MateCard(
                    mate: _mates[index],
                    onRemove: () =>
                        _removeMate(_mates[index].mate?.username ?? ''),
                    onTap: () => _showMateDetailDialog(_mates[index]),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isLoadingMates || _isLoadingSnippets;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([_loadMates(), _loadSnippets()]);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Mates Section
          SliverPadding(
            padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 8.h),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F0), // Light beige/off-white
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with title and requests button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'My mates',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(
                                  0xFF2C2C2C,
                                ), // Dark grey/black
                                fontSize: 18.sp,
                              ),
                        ),
                        RequestsButton(onPressed: _showMateRequestsDialog),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    // Mates list
                    if (_errorMessageMates != null)
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Error loading mates',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              _errorMessageMates!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            SizedBox(height: 8.h),
                            ElevatedButton(
                              onPressed: _loadMates,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    else if (_mates.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.h),
                        child: Row(
                          children: [
                            Icon(
                              Icons.people_outline,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                'No mates yet. Add mates to start sharing snippets!',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      _buildAdaptiveMatesList(),
                  ],
                ),
              ),
            ),
          ),

          // Snippets Section
          SliverPadding(
            padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 8.h),
            sliver: SliverToBoxAdapter(
              child: SectionHeader(title: 'Received Snippets'),
            ),
          ),
          if (_errorMessageSnippets != null)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Error loading snippets',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _errorMessageSnippets!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      SizedBox(height: 8.h),
                      ElevatedButton(
                        onPressed: _loadSnippets,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_snippets.isEmpty)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.message_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'No snippets yet',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Share reading snippets with your mates',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 100.h),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final snippet = _snippets[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: MessageCard(snippet: snippet),
                  );
                }, childCount: _snippets.length),
              ),
            ),
        ],
      ),
    );
  }
}
