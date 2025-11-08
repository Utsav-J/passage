import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:passage/models/mate.dart';
import 'package:passage/profile/mate_avatar.dart';


class MateCard extends StatelessWidget {
  const MateCard({
    required this.mate,
    required this.onRemove,
    required this.onTap,
    super.key
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
