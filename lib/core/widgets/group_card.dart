import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import 'app_text.dart';
import 'app_avatar.dart';

class GroupCard extends StatelessWidget {
  final String groupName;
  final int memberCount;
  final double balance;
  final VoidCallback onTap;

  const GroupCard({
    super.key,
    required this.groupName,
    required this.memberCount,
    required this.balance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = balance > 0;
    final isNegative = balance < 0;

    final leftBorderColor = isPositive
        ? AppColors.accent
        : isNegative
            ? AppColors.error
            : AppColors.divider;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Left colored border
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: leftBorderColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  bottomLeft: Radius.circular(16.r),
                ),
              ),
            ),
          ),
          // Card border
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.divider,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16.r),
                child: Padding(
                  padding: EdgeInsets.all(14.w),
                  child: Row(
                    children: [
                      AppAvatar(name: groupName, size: 46.sp),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              groupName,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              maxLines: 1,
                            ),
                            SizedBox(height: 3.h),
                            AppText(
                              '$memberCount members',
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AppText(
                            balance >= 0
                                ? '+\$${balance.abs().toStringAsFixed(2)}'
                                : '-\$${balance.abs().toStringAsFixed(2)}',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: balance > 0
                                ? AppColors.success
                                : balance < 0
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                          ),
                          SizedBox(height: 3.h),
                          AppText(
                            balance > 0
                                ? 'others owe you'
                                : balance < 0
                                    ? 'you owe others'
                                    : 'settled',
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ],
                      ),
                      SizedBox(width: 8.w),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textHint,
                        size: 20.sp,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
