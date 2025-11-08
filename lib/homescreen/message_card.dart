import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:passage/models/snippet.dart';

class MessageCard extends StatelessWidget {
  const MessageCard({required this.snippet, super.key});

  final Snippet snippet;

  String _getBookInitials(String bookTitle) {
    final words = bookTitle.trim().split(RegExp(r'\s+'));
    final buffer = StringBuffer();
    for (final word in words) {
      if (word.isEmpty) continue;
      buffer.write(word[0].toUpperCase());
      if (buffer.length == 2) break;
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mutedBodyColor = textTheme.bodySmall?.color != null
        ? textTheme.bodySmall!.color!.withOpacity(0.7)
        : colorScheme.onSurfaceVariant.withOpacity(0.7);
    final mutedLabelColor = textTheme.labelSmall?.color != null
        ? textTheme.labelSmall!.color!.withOpacity(0.7)
        : colorScheme.onSurfaceVariant.withOpacity(0.7);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24.r,
              backgroundColor: colorScheme.primary.withOpacity(0.15),
              child: Text(
                snippet.sender?.initials ?? '?',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(snippet.text, style: textTheme.bodyLarge),
                  if (snippet.note != null && snippet.note!.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      snippet.note!,
                      style: textTheme.bodySmall?.copyWith(
                        color: mutedBodyColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  SizedBox(height: 8.h),
                  Text(
                    '— from ${snippet.book?.title ?? "Unknown Book"}',
                    style: textTheme.bodySmall?.copyWith(color: mutedBodyColor),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Shared by ${snippet.sender?.username ?? "Unknown"}',
                            style: textTheme.bodySmall?.copyWith(
                              color: mutedBodyColor,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            snippet.timeLabel,
                            style: textTheme.labelSmall?.copyWith(
                              color: mutedLabelColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            ClipRRect(
              borderRadius: BorderRadius.circular(14.r),
              child: Container(
                width: 54.w,
                height: 72.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.secondaryContainer,
                      colorScheme.primaryContainer,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _getBookInitials(snippet.book?.title ?? ''),
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
