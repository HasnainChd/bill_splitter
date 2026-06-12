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
  final BoxBorder? border;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.color,
    this.borderRadius,
    this.highlighted = false,
    this.gradient = false,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? 16.r;
    final cardColor = color ?? AppColors.cardDark;
    final borderColor = AppColors.white.withValues(alpha: 0.05);
    final defaultBorder = Border.all(
      color: borderColor,
      width: 1,
    );

    if (highlighted) {
      return Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Stack(
          children: [
            // Left indicator border
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: AppColors.onboardingViolet,
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
                border: border ?? defaultBorder,
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(radius),
                  splashColor: AppColors.white.withValues(alpha: 0.04),
                  highlightColor: AppColors.white.withValues(alpha: 0.04),
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

    // Normal card
    return Container(
      decoration: BoxDecoration(
        color: gradient ? null : cardColor,
        gradient: gradient
            ? const LinearGradient(
                colors: [AppColors.cardDark, AppColors.cardDarkSecondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(radius),
        border: border ?? defaultBorder,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: AppColors.white.withValues(alpha: 0.04),
          highlightColor: AppColors.white.withValues(alpha: 0.04),
          child: Padding(
            padding: padding ?? EdgeInsets.all(16.w),
            child: child,
          ),
        ),
      ),
    );
  }
}
