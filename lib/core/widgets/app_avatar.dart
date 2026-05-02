import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';

class AppAvatar extends StatelessWidget {
  final String name;
  final double? size;
  final Color? backgroundColor;

  const AppAvatar({
    super.key,
    required this.name,
    this.size,
    this.backgroundColor,
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
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.white,
          fontSize: avatarSize * 0.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
