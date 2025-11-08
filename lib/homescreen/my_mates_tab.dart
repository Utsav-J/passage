import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:passage/homescreen/message_card.dart';
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
      builder: (context) => const _MateRequestsDialog(),
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
              child: SectionHeader(
                title: 'My Mates',
                trailing: TextButton(
                  onPressed: _showMateRequestsDialog,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'requests',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_errorMessageMates != null)
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
                ),
              ),
            )
          else if (_mates.isEmpty)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: 140.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _mates.length,
                    separatorBuilder: (_, __) => SizedBox(width: 12.w),
                    itemBuilder: (context, index) {
                      final mate = _mates[index];
                      return _MateCard(
                        mate: mate,
                        onRemove: () => _removeMate(mate.mate?.username ?? ''),
                        onTap: () => _showMateDetailDialog(mate),
                      );
                    },
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
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100.w,
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MateAvatar(mateUser: mateUser, mateId: mate.mateId, size: 70.w),
                SizedBox(height: 8.h),
                Text(
                  mateUser?.username ?? 'User ${mate.mateId}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 16.sp,
                    color: colorScheme.onError,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MateRequestsDialog extends StatefulWidget {
  const _MateRequestsDialog();

  @override
  State<_MateRequestsDialog> createState() => _MateRequestsDialogState();
}

class _MateRequestsDialogState extends State<_MateRequestsDialog> {
  final MateService _mateService = MateService();
  List<Mate> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<String> _processingUsernames = {};

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final requests = await _mateService.getMateRequests();
      if (!mounted) return;
      setState(() {
        _requests = requests;
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

  Future<void> _acceptRequest(Mate request) async {
    final requester = request.requesterOrMate;
    if (requester == null) return;

    final username = requester.username;
    if (_processingUsernames.contains(username)) return;

    setState(() {
      _processingUsernames.add(username);
    });

    try {
      await _mateService.acceptMateRequest(username);
      if (!mounted) return;

      setState(() {
        _requests.removeWhere((r) => r.id == request.id);
        _processingUsernames.remove(username);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Accepted request from ${requester.username}'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processingUsernames.remove(username);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(Mate request) async {
    final requester = request.requesterOrMate;
    if (requester == null) return;

    final username = requester.username;
    if (_processingUsernames.contains(username)) return;

    setState(() {
      _processingUsernames.add(username);
    });

    try {
      await _mateService.rejectMateRequest(username);
      if (!mounted) return;

      setState(() {
        _requests.removeWhere((r) => r.id == request.id);
        _processingUsernames.remove(username);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rejected request from ${requester.username}'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processingUsernames.remove(username);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  Text(
                    'Mate Requests',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
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
                            'Error loading requests',
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
                            onPressed: _loadRequests,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _requests.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(40.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_add_outlined,
                            size: 64.sp,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No requests',
                            style: theme.textTheme.titleMedium,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'You have no pending mate requests',
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
                      itemCount: _requests.length,
                      itemBuilder: (context, index) {
                        final request = _requests[index];
                        final requester = request.requesterOrMate;
                        if (requester == null) {
                          return const SizedBox.shrink();
                        }

                        final isProcessing = _processingUsernames.contains(
                          requester.username,
                        );

                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 8.h,
                          ),
                          leading: MateAvatar(
                            mateUser: requester,
                            mateId: requester.id,
                            size: 50.w,
                          ),
                          title: Text(
                            requester.username,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            requester.email,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Accept Button
                              ElevatedButton(
                                onPressed: isProcessing
                                    ? null
                                    : () => _acceptRequest(request),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 8.h,
                                  ),
                                  minimumSize: Size(80.w, 36.h),
                                ),
                                child: isProcessing
                                    ? SizedBox(
                                        width: 16.w,
                                        height: 16.h,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Text('Accept'),
                              ),
                              SizedBox(width: 8.w),
                              // Reject Button
                              OutlinedButton(
                                onPressed: isProcessing
                                    ? null
                                    : () => _rejectRequest(request),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colorScheme.onSurface,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 8.h,
                                  ),
                                  minimumSize: Size(80.w, 36.h),
                                ),
                                child: const Text('Reject'),
                              ),
                            ],
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
