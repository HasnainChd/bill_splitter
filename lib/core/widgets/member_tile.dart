import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import 'app_text.dart';

class MemberTile extends StatelessWidget {
  final String name;
  final String username;
  final String initials;
  final Color avatarColor;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showAddButton;

  const MemberTile({
    super.key,
    required this.name,
    required this.username,
    required this.initials,
    required this.avatarColor,
    this.isSelected = false,
    this.onTap,
    this.showAddButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: avatarColor,
                borderRadius: BorderRadius.circular(14.r),
              ),
              alignment: Alignment.center,
              child: AppText(
                initials,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            SizedBox(width: 12.w),
            // Name and username
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    name,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                  SizedBox(height: 2.h),
                  AppText(
                    username,
                    fontSize: 13,
                    color: AppColors.white.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
            // Action button
            if (showAddButton)
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: AppColors.white.withValues(alpha: 0.4),
                  size: 18.sp,
                ),
              )
            else
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.onboardingViolet
                      : AppColors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        color: AppColors.white,
                        size: 18.sp,
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}
