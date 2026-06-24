import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_text.dart';
import '../constants/app_colors.dart';

class AppEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? actionButton;

  const AppEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 48.sp,
                color: AppColors.onboardingViolet.withValues(alpha: 0.8),
              ),
            ),
            SizedBox(height: 24.h),
            AppText(
              title,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              align: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            AppText(
              subtitle,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.white.withValues(alpha: 0.5),
              align: TextAlign.center,
              height: 1.5,
            ),
            if (actionButton != null) ...[
              SizedBox(height: 32.h),
              actionButton!,
            ],
          ],
        ),
      ),
    );
  }
}
