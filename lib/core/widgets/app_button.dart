import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isOutlined;
  final bool isAccent;
  final double? width;
  final double? height;
  final Color? color;
  final Color? textColor;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.isOutlined = false,
    this.isAccent = false,
    this.width,
    this.height,
    this.color,
    this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 52.h,
      child: Container(
        decoration: BoxDecoration(
          gradient: !isOutlined
              ? (isAccent
                  ? const LinearGradient(
                      colors: [AppColors.accent, AppColors.accentDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        color ?? AppColors.primaryAccent,
                        color ?? AppColors.primary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ))
              : null,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: !isOutlined && !isLoading
              ? [
                  BoxShadow(
                    color: (isAccent
                            ? AppColors.accent
                            : (color ?? AppColors.primary))
                        .withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: Offset(0, 4.h),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : (onTap ?? () {}),
          style: ElevatedButton.styleFrom(
            backgroundColor: isOutlined
                ? Colors.transparent
                : (isAccent ? AppColors.accent : (color ?? AppColors.primary)),
            foregroundColor: textColor ??
                (isOutlined
                    ? (color ?? AppColors.primary)
                    : (isAccent
                        ? AppColors.textOnAccent
                        : AppColors.textOnPrimary)),
            side: isOutlined
                ? BorderSide(color: color ?? AppColors.primary, width: 2)
                : BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.symmetric(horizontal: 24.w),
          ),
          child: isLoading
              ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      textColor ??
                          (isOutlined
                              ? (color ?? AppColors.primary)
                              : AppColors.textOnPrimary),
                    ),
                  ),
                )
              : icon != null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
        ),
      ),
    );
  }
}
