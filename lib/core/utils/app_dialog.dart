import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text.dart';

class AppDialog {
  static Future<bool?> showConfirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDanger = false,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.6),
      builder: (context) => Dialog(
        backgroundColor: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(
            color: AppColors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  color: isDanger
                      ? AppColors.error.withValues(alpha: 0.12)
                      : AppColors.onboardingViolet.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDanger
                      ? Icons.delete_outline_rounded
                      : Icons.help_outline_rounded,
                  size: 28.sp,
                  color: isDanger ? AppColors.error : AppColors.onboardingViolet,
                ),
              ),
              SizedBox(height: 20.h),
              AppText(
                title,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
                align: TextAlign.center,
              ),
              SizedBox(height: 10.h),
              AppText(
                message,
                fontSize: 14,
                color: AppColors.white.withValues(alpha: 0.6),
                align: TextAlign.center,
                height: 1.4,
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: cancelText,
                      onTap: () => Navigator.of(context).pop(false),
                      isOutlined: true,
                      color: AppColors.white.withValues(alpha: 0.2),
                      textColor: AppColors.white,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AppButton(
                      label: confirmText,
                      onTap: () => Navigator.of(context).pop(true),
                      color: isDanger ? AppColors.error : AppColors.onboardingViolet,
                      textColor: AppColors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'Done',
    VoidCallback? onDone,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.black.withValues(alpha: 0.5),
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72.w,
                height: 72.w,
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 36.sp,
                  color: AppColors.success,
                ),
              ),
              SizedBox(height: 16.h),
              AppText(
                title,
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                align: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              AppText(
                message,
                fontSize: 14.sp,
                color: AppColors.textSecondary,
                align: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              AppButton(
                label: buttonText,
                onTap: () {
                  Navigator.of(context).pop();
                  onDone?.call();
                },
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
