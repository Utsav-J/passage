class User {
  User({
    required this.id,
    required this.username,
    required this.email,
    required this.createdAt,
    this.profileImageUrl,
  });

  final int id;
  final String username;
  final String email;
  final DateTime createdAt;
  final String? profileImageUrl;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        username: json['username'] as String,
        email: json['email'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        profileImageUrl: json['profile_image_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
        'created_at': createdAt.toIso8601String(),
      };

  bool get hasProfileImage => profileImageUrl != null && profileImageUrl!.isNotEmpty;

  String get initials {
    final trimmed = username.trim();
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split(RegExp(r'\s+'));
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + last).toUpperCase();
  }
}

