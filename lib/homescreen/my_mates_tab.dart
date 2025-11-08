import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:passage/homescreen/mate_requests_dialog.dart';
import 'package:passage/homescreen/message_card.dart';
import 'package:passage/homescreen/requests_button.dart';
import 'package:passage/models/mate.dart';
import 'package:passage/models/snippet.dart';
import 'package:passage/homescreen/section_header.dart';
import 'package:passage/services/mate_service.dart';
import 'package:passage/services/snippet_service.dart';
import 'package:passage/profile/mate_avatar.dart';
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
                    SizedBox(height: 20.h),
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
                      SizedBox(
                        height: 120.h,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _mates.length,
                          separatorBuilder: (_, __) => SizedBox(width: 16.w),
                          itemBuilder: (context, index) {
                            final mate = _mates[index];
                            return _MateCard(
                              mate: mate,
                              onRemove: () =>
                                  _removeMate(mate.mate?.username ?? ''),
                              onTap: () => _showMateDetailDialog(mate),
                            );
                          },
                        ),
                      ),
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

class _MateCard extends StatelessWidget {
  const _MateCard({
    required this.mate,
    required this.onRemove,
    required this.onTap,
  });

  final Mate mate;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mateUser = mate.mate;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular avatar
          MateAvatar(mateUser: mateUser, mateId: mate.mateId, size: 60.w),
          SizedBox(height: 8.h),
          // Name below avatar
          Text(
            mateUser?.username ?? 'User ${mate.mateId}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF2C2C2C), // Dark grey/black
              fontSize: 13.sp,
              fontWeight: FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
