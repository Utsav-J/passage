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

  // Create a demo book that always shows the sample.epub
  Book _getDemoBook() {
    return Book(
      id: -1, // Special ID for demo book
      title: 'Sample Book',
      author: 'Demo Author',
      ownerId: 0,
      progress: 0.0,
      createdAt: DateTime.now(),
      coverImageUrl: null,
    );
  }

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

    // Always show demo book, even if user has no books

    final crossAxisCount = ScreenUtil().screenWidth > 540 ? 3 : 2;
    final demoBook = _getDemoBook();

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh?.call();
        await Future.delayed(const Duration(seconds: 1));
      },
      child: CustomScrollView(
        slivers: [
          // Demo Book Section
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            sliver: SliverToBoxAdapter(
              child: SectionHeader(title: 'Demo Book'),
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
                return BookCard(
                  book: demoBook,
                  onTap: () => onOpenBook(demoBook),
                  onDelete: null, // Demo book cannot be deleted
                );
              }, childCount: 1),
            ),
          ),
          // My Library Section
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            sliver: SliverToBoxAdapter(
              child: SectionHeader(title: 'My Library'),
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
                return BookCard(
                  book: book,
                  onTap: () => onOpenBook(book),
                  onDelete: () => onDeleteBook(book.id),
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