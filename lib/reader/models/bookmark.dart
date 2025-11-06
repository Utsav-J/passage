class Bookmark {
  Bookmark({required this.label, required this.cfi, this.pageNumber});

  final String label;
  final String cfi;
  final int? pageNumber;

  // JSON serialization
  Map<String, dynamic> toJson() => {
        'label': label,
        'cfi': cfi,
        if (pageNumber != null) 'pageNumber': pageNumber,
      };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        label: json['label'] as String,
        cfi: json['cfi'] as String,
        pageNumber: json['pageNumber'] as int?,
      );
}

