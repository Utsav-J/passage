import 'package:avatar_plus/avatar_plus.dart';
import 'package:flutter/material.dart';
import 'package:passage/models/user.dart';

class MateAvatar extends StatelessWidget {
  const MateAvatar({
    required this.mateUser,
    required this.mateId,
    required this.size,
    super.key,
  });

  final User? mateUser;
  final int mateId;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (mateUser != null && mateUser!.hasProfileImage) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(mateUser!.profileImageUrl!),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      );
    }

    final seed = mateUser?.username ?? 'mate-$mateId';

    return ClipOval(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: AvatarPlus(seed, width: size, height: size, trBackground: true),
      ),
    );
  }
}
