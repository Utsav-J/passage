import 'user.dart';
import 'book.dart';

class Snippet {
  Snippet({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.bookId,
    required this.text,
    required this.createdAt,
    this.note,
    this.sender,
    this.receiver,
    this.book,
  });

  final int id;
  final int senderId;
  final int receiverId;
  final int bookId;
  final String text;
  final String? note;
  final DateTime createdAt;
  final User? sender;
  final User? receiver;
  final Book? book;

  factory Snippet.fromJson(Map<String, dynamic> json) => Snippet(
        id: json['id'] as int,
        senderId: json['sender_id'] as int,
        receiverId: json['receiver_id'] as int,
        bookId: json['book_id'] as int,
        text: json['text'] as String,
        note: json['note'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        sender: json['sender'] != null
            ? User.fromJson(json['sender'] as Map<String, dynamic>)
            : null,
        receiver: json['receiver'] != null
            ? User.fromJson(json['receiver'] as Map<String, dynamic>)
            : null,
        book: json['book'] != null
            ? Book.fromJson(json['book'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'book_id': bookId,
        'text': text,
        if (note != null) 'note': note,
        'created_at': createdAt.toIso8601String(),
        if (sender != null) 'sender': sender!.toJson(),
        if (receiver != null) 'receiver': receiver!.toJson(),
        if (book != null) 'book': book!.toJson(),
      };

  String get timeLabel {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hrs ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${difference.inDays ~/ 7} weeks ago';
    }
  }
}

