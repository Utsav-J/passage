class Book {
  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.ownerId,
    required this.progress,
    required this.createdAt,
    this.coverImageUrl,
  });

  final int id;
  final String title;
  final String author;
  final String? coverImageUrl;
  final int ownerId;
  final double progress;
  final DateTime createdAt;

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: json['id'] as int,
        title: json['title'] as String,
        author: json['author'] as String,
        coverImageUrl: json['cover_image_url'] as String?,
        ownerId: json['owner_id'] as int,
        progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
        'owner_id': ownerId,
        'progress': progress,
        'created_at': createdAt.toIso8601String(),
      };
}

