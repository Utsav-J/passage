import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.isLoading = false,
    this.onPickFile,
  });

  final bool isLoading;
  final VoidCallback? onPickFile;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              SizedBox(height: 16.h),
              Text(
                'Loading book...',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined, size: 72.sp),
            SizedBox(height: 16.h),
            Text(
              'Open an EPUB to start reading',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (onPickFile != null) ...[
              SizedBox(height: 12.h),
              FilledButton.icon(
                onPressed: onPickFile,
                icon: const Icon(Icons.folder_open),
                label: const Text('Pick EPUB'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

