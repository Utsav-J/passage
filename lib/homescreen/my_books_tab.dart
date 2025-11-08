import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:passage/homescreen/book_card.dart';
import 'package:passage/homescreen/section_header.dart';
import 'package:passage/models/book.dart';

class MyBooksTab extends StatelessWidget {
  const MyBooksTab({
    required this.onOpenBook,
    required this.books,
    required this.isLoading,
    required this.onDeleteBook,
    this.errorMessage,
    this.onRefresh,
    super.key
  });

  final ValueChanged<Book> onOpenBook;
  final List<Book> books;
  final bool isLoading;
  final ValueChanged<int> onDeleteBook;
  final String? errorMessage;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error loading books',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRefresh, child: const Text('Retry')),
          ],
        ),
      );
    }

    final crossAxisCount = ScreenUtil().screenWidth > 540 ? 3 : 2;

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh?.call();
        await Future.delayed(const Duration(seconds: 1));
      },
      child: books.isEmpty
          ? CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 64.sp,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No books yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Add books to start reading',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                  sliver: SliverToBoxAdapter(
                    child: SectionHeader(title: 'My Books'),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16.w,
                      mainAxisSpacing: 16.h,
                      childAspectRatio: 0.68,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final book = books[index];
                      // Prevent deletion of the sample book
                      final isSampleBook = book.title == 'Sample Book' && book.author == 'Demo Author';
                      return BookCard(
                        book: book,
                        onTap: () => onOpenBook(book),
                        onDelete: isSampleBook ? null : () => onDeleteBook(book.id),
                      );
                    }, childCount: books.length),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 24.h)),
              ],
            ),
    );
  }
}