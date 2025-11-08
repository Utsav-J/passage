import 'package:avatar_plus/avatar_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:passage/profile/avatar_picker_dialog.dart';
import 'package:passage/profile/mate_avatar.dart';
import 'package:passage/profile/mate_detail_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mate.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/mate_service.dart';
import '../utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final MateService _mateService = MateService();

  User? _user;
  List<Mate> _mates = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _localAvatarSeed;

  @override
  void initState() {
    super.initState();
    _loadLocalAvatar();
    _loadData();
  }

  Future<void> _loadLocalAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _localAvatarSeed = prefs.getString(ApiConstants.avatarSeedKey);
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _authService.getCurrentUser(),
        _mateService.getMates(),
      ]);

      if (!mounted) return;
      setState(() {
        _user = results[0] as User;
        _mates = results[1] as List<Mate>;
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

  Future<void> _showAvatarPicker() async {
    if (_user == null) return;

    await showDialog(
      context: context,
      builder: (context) => AvatarPickerDialog(
        currentUser: _user!,
        initialSeed:
            _localAvatarSeed ?? _user!.profileImageUrl ?? _user!.username,
        onAvatarSelected: (avatarSeed) async {
          // Save avatar seed locally
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(ApiConstants.avatarSeedKey, avatarSeed);

          if (!mounted) return;
          setState(() {
            _localAvatarSeed = avatarSeed;
          });

          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Avatar saved! (Note: Profile update API coming soon)',
              ),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _showMateDetailDialog(Mate mate) {
    final mateUser = mate.mate;
    showDialog(
      context: context,
      builder: (context) => MateDetailDialog(mate: mate, mateUser: mateUser),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48.sp,
                color: Theme.of(context).colorScheme.error,
              ),
              SizedBox(height: 16.h),
              Text(
                'Unable to load your profile',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final user = _user!;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 24.h),
        children: [
          _ProfileHeader(
            user: user,
            localAvatarSeed: _localAvatarSeed,
            onAvatarTap: _showAvatarPicker,
          ),
          SizedBox(height: 24.h),
          _ProfileInfoCard(user: user),
          SizedBox(height: 32.h),
          Text('Mates', style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 12.h),
          if (_mates.isEmpty)
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                      'You have no mates yet. Add mates to start sharing snippets!',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 16.w,
              runSpacing: 16.h,
              children: _mates
                  .map(
                    (mate) => _MateCard(
                      mate: mate,
                      onTap: () => _showMateDetailDialog(mate),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.onAvatarTap,
    this.localAvatarSeed,
  });

  final User user;
  final VoidCallback onAvatarTap;
  final String? localAvatarSeed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onAvatarTap,
          child: Stack(
            children: [
              _buildAvatar(context),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.edit,
                    size: 16.sp,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          user.username,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8.h),
        Text(
          user.email,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final double size = 110.w;

    // Priority: localAvatarSeed > profile_image_url (if URL) > profile_image_url (if seed) > username
    // If profile_image_url exists and is a URL (starts with http), use NetworkImage
    if (user.hasProfileImage &&
        user.profileImageUrl!.startsWith('http') &&
        localAvatarSeed == null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(user.profileImageUrl!),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      );
    }

    // Use local avatar seed, or profile_image_url, or username
    final seed = localAvatarSeed ?? user.profileImageUrl ?? user.username;

    return ClipOval(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: AvatarPlus(seed, width: size, height: size, trBackground: true),
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final createdAt = user.createdAt;
    final formattedDate = _formatDate(createdAt);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Details',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12.h),
          _InfoRow(
            icon: Icons.badge_outlined,
            label: 'User ID',
            value: '#${user.id}',
          ),
          SizedBox(height: 8.h),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Joined',
            value: formattedDate,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: Theme.of(context).colorScheme.primary),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _MateCard extends StatelessWidget {
  const _MateCard({required this.mate, required this.onTap});

  final Mate mate;
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
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MateAvatar(mateUser: mateUser, mateId: mate.mateId, size: 60.w),
            SizedBox(height: 12.h),
            Text(
              mateUser?.username ?? 'User ${mate.mateId}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
