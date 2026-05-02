import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final Color? color;
  final double? borderRadius;
  final bool highlighted;
  final bool gradient;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.color,
    this.borderRadius,
    this.highlighted = false,
    this.gradient = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.accentLight
            : (gradient ? null : (color ?? AppColors.surface)),
        gradient: gradient
            ? const LinearGradient(
                colors: [AppColors.surface, AppColors.surfaceVariant],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(borderRadius ?? 16.r),
        border: Border.all(
          color: highlighted ? AppColors.accent : AppColors.divider,
          width: highlighted ? 3 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? 16.r),
          splashColor: AppColors.primary.withValues(alpha: 0.04),
          highlightColor: AppColors.primary.withValues(alpha: 0.04),
          child: Padding(
            padding: padding ?? EdgeInsets.all(16.w),
            child: child,
          ),
        ),
      ),
    );
  }
}
