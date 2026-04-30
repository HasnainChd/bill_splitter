import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    
    // Generate consistent color based on name
    final color = backgroundColor ?? _generateColorFromName(name);
    
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: (avatarSize * 0.4).sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Color _generateColorFromName(String name) {
    final colors = [
      const Color(0xFF1976D2), // Blue
      const Color(0xFF388E3C), // Green
      const Color(0xFFD32F2F), // Red
      const Color(0xFF7B1FA2), // Purple
      const Color(0xFFE64A19), // Orange
      const Color(0xFF00796B), // Teal
      const Color(0xFF303F9F), // Indigo
      const Color(0xFFC2185B), // Pink
    ];
    
    if (name.isEmpty) return colors[0];
    
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    return colors[hash.abs() % colors.length];
  }
}
