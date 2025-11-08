import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:passage/models/snippet.dart';
import 'package:passage/profile/mate_avatar.dart';

class MessageCard extends StatelessWidget {
  const MessageCard({required this.snippet, super.key});

  final Snippet snippet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sender = snippet.sender;
    final book = snippet.book;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section with beige background
          Container(
            padding: EdgeInsets.symmetric(vertical: 9.h, horizontal: 16.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F0E7), // Light beige/cream
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile picture
                MateAvatar(
                  mateUser: sender,
                  mateId: sender?.id ?? 0,
                  size: 50.w,
                ),
                SizedBox(width: 12.w),
                // User name and book title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // User name (bold, dark)
                      Text(
                        "@${sender?.username ?? 'Unknown'}",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                          color: const Color(0xFF333333), // Dark grey/black
                        ),
                      ),
                      Text(
                        book?.title ?? 'Unknown Book',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w300,
                          fontSize: 14.sp,
                          color: const Color(0xFF333333), // Dark grey/black
                        ),
                      ),
                    ],
                  ),
                ),
                // Timestamp (top right)
                Text(
                  snippet.timeLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12.sp,
                    color: const Color(0xFF888888), // Lighter grey
                  ),
                ),
              ],
            ),
          ),
          // Body Section with white background
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quote with orange bullet point
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quote text
                    Expanded(
                      child: Text(
                        '"${snippet.text}"',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.normal,
                          color: const Color(0xFF333333), // Dark grey/black
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                // Separator line
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: Container(
                    height: 1.h,
                    color: const Color(0xFFDDDDDD), // Light grey
                  ),
                ),
                // Comment (note)
                if (snippet.note != null && snippet.note!.isNotEmpty)
                  Text(
                    snippet.note!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14.sp,
                      color: const Color(0xFF888888), // Lighter grey
                      height: 1.4,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
