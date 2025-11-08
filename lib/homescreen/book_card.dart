import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:passage/models/book.dart';
import 'package:passage/utils/image_utils.dart';

class BookCard extends StatelessWidget {
  const BookCard({
    required this.book,
    required this.onTap,
    this.onDelete,
    super.key,
  });

  final Book book;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  // Generate a color from the book title hash
  Color _getBookColor() {
    final hash = book.title.hashCode;
    final colors = [
      const Color(0xFF7B61FF),
      const Color(0xFFFF6584),
      const Color(0xFF00BFA5),
      const Color(0xFF4DD0E1),
      const Color(0xFFFFA726),
      const Color(0xFF26C6DA),
      const Color(0xFFA1887F),
    ];
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final bookColor = _getBookColor();
    final hasCoverImage =
        book.coverImageUrl != null && book.coverImageUrl!.isNotEmpty;
    final isBase64Image = hasCoverImage && ImageUtils.isBase64DataUrl(book.coverImageUrl!);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete != null
          ? () {
              // Show delete dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Book'),
                  content: Text(
                    'Are you sure you want to delete "${book.title}"?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onDelete!();
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            }
          : null,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: hasCoverImage
                  ? _buildCoverImage(book.coverImageUrl!, isBase64Image)
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [bookColor, bookColor.withValues(alpha: 0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
            ),
            if (hasCoverImage)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title on first line (max 2 lines)
                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    // Author on second line (max 1 line)
                    Text(
                      book.author,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SizedBox(
                height: 6.h,
                child: LinearProgressIndicator(
                  value: book.progress.clamp(0.0, 1.0),
                  color: Theme.of(context).colorScheme.primary,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage(String coverImageUrl, bool isBase64) {
    if (isBase64) {
      try {
        final base64String = ImageUtils.extractBase64FromDataUrl(coverImageUrl);
        final imageBytes = base64Decode(base64String);
        return Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(color: Colors.grey[300]);
          },
        );
      } catch (e) {
        return Container(color: Colors.grey[300]);
      }
    } else {
      return Image.network(
        coverImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(color: Colors.grey[300]);
        },
      );
    }
  }
}
