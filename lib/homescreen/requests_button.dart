import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RequestsButton extends StatelessWidget {
  const RequestsButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: const Color(0xFFE8D5C4), // Light muted orange/beige
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Requests',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF3A3A3A), // Dark brown/black
                fontSize: 13.sp,
                fontWeight: FontWeight.normal,
              ),
            ),
            SizedBox(width: 6.w),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16.sp,
              color: const Color(0xFF3A3A3A), // Dark brown/black
            ),
          ],
        ),
      ),
    );
  }
}
