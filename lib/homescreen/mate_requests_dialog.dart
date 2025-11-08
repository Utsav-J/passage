import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:passage/models/mate.dart';
import 'package:passage/services/mate_service.dart';
import 'package:passage/profile/mate_avatar.dart';

class MateRequestsDialog extends StatefulWidget {
  const MateRequestsDialog({super.key});

  @override
  State<MateRequestsDialog> createState() => _MateRequestsDialogState();
}

class _MateRequestsDialogState extends State<MateRequestsDialog> {
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
