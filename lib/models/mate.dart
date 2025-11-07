import 'user.dart';

class Mate {
  Mate({
    required this.id,
    required this.userId,
    required this.mateId,
    required this.status,
    required this.createdAt,
    this.mate,
    this.user,
  });

  final int id;
  final int userId;
  final int mateId;
  final String status;
  final DateTime createdAt;
  final User? mate; // For accepted mates (from /mates endpoint)
  final User? user; // For incoming requests (from /mates/requests endpoint)

  // Get the user object (either mate or user, whichever is available)
  User? get requesterOrMate => user ?? mate;

  factory Mate.fromJson(Map<String, dynamic> json) => Mate(
        id: json['id'] as int,
        userId: json['user_id'] as int,
        mateId: json['mate_id'] as int,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        mate: json['mate'] != null
            ? User.fromJson(json['mate'] as Map<String, dynamic>)
            : null,
        user: json['user'] != null
            ? User.fromJson(json['user'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'mate_id': mateId,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        if (mate != null) 'mate': mate!.toJson(),
      };
}

