import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';

class AppAvatar extends StatelessWidget {
  final String name;
  final double? size;
  final Color? backgroundColor;
  final String? avatarUrl;

  const AppAvatar({
    super.key,
    required this.name,
    this.size,
    this.backgroundColor,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = size ?? 40.sp;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    // Generate consistent color based on name
    final color = backgroundColor ??
        AppColors.avatarColors[name.hashCode % AppColors.avatarColors.length];

    return CircleAvatar(
      radius: avatarSize / 2,
      backgroundColor: color,
      backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
          ? NetworkImage(avatarUrl!)
          : null,
      child: avatarUrl == null || avatarUrl!.isEmpty
          ? Text(
              initials,
              style: TextStyle(
                color: AppColors.white,
                fontSize: avatarSize * 0.4,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
    );
  }
}
