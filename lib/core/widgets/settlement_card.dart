import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import 'app_text.dart';
import 'app_avatar.dart';

class SettlementCard extends StatelessWidget {
  final String fromMember;
  final String toMember;
  final double amount;
  final bool isPaid;
  final VoidCallback? onMarkAsPaid;

  const SettlementCard({
    super.key,
    required this.fromMember,
    required this.toMember,
    required this.amount,
    required this.isPaid,
    this.onMarkAsPaid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isPaid ? AppColors.successLight : AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isPaid ? AppColors.success : AppColors.accent,
          width: 1.5,
        ),
        boxShadow: isPaid
            ? []
            : [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Avatar → Amount → Avatar row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // From member
              Column(
                children: [
                  AppAvatar(
                    name: fromMember,
                    size: 44.sp,
                  ),
                  SizedBox(height: 4.h),
                  AppText(
                    fromMember,
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              // Center: arrow + amount
              Column(
                children: [
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.accent,
                    size: 20.sp,
                  ),
                  SizedBox(height: 4.h),
                  AppText(
                    '\$${amount.toStringAsFixed(2)}',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 2.h),
                  AppText(
                    '$fromMember pays $toMember',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              // To member
              Column(
                children: [
                  AppAvatar(
                    name: toMember,
                    size: 44.sp,
                  ),
                  SizedBox(height: 4.h),
                  AppText(
                    toMember,
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 14.h),
          // Button or Paid state
          if (isPaid)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 18.sp,
                ),
                SizedBox(width: 6.w),
                AppText(
                  "Paid",
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onMarkAsPaid,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.success,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  foregroundColor: AppColors.success,
                ),
                child: Text(
                  "Mark as Paid",
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
