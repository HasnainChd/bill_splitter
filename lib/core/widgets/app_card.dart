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
    final radius = borderRadius ?? 16.r;

    // For highlighted cards, we need to use a custom painter or stack
    // because borderRadius + non-uniform border colors don't work together
    if (highlighted) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Stack(
          children: [
            // Gold left border
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(radius),
                    bottomLeft: Radius.circular(radius),
                  ),
                ),
              ),
            ),
            // Subtle border around the card
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.divider,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(radius),
                  splashColor: AppColors.primary.withValues(alpha: 0.04),
                  highlightColor: AppColors.primary.withValues(alpha: 0.04),
                  child: Padding(
                    padding: padding ?? EdgeInsets.all(16.w),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Normal card (not highlighted)
    return Container(
      decoration: BoxDecoration(
        color: gradient ? null : (color ?? AppColors.surface),
        gradient: gradient
            ? const LinearGradient(
                colors: [AppColors.surface, AppColors.surfaceVariant],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
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
