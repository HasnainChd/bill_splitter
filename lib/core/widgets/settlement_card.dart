import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import 'app_text.dart';
import 'app_avatar.dart';
import 'app_button.dart';

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
        color: isPaid
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.cardDark,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isPaid
              ? AppColors.success
              : AppColors.white.withValues(alpha: 0.05),
          width: 1,
        ),
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
                  SizedBox(height: 6.h),
                  AppText(
                    fromMember,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ],
              ),
              // Center: arrow + amount
              Column(
                children: [
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.onboardingViolet,
                    size: 20.sp,
                  ),
                  SizedBox(height: 4.h),
                  AppText(
                    '\$${amount.toStringAsFixed(0)}',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isPaid ? AppColors.success : AppColors.white,
                  ),
                  SizedBox(height: 2.h),
                  AppText(
                    '$fromMember pays $toMember',
                    fontSize: 11,
                    color: AppColors.white.withValues(alpha: 0.4),
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
                  SizedBox(height: 6.h),
                  AppText(
                    toMember,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
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
                const AppText(
                  "Paid",
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              height: 38.h,
              child: ElevatedButton(
                onPressed: onMarkAsPaid,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success.withValues(alpha: 0.12),
                  elevation: 0,
                  side: BorderSide(
                    color: AppColors.success.withValues(alpha: 0.25),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: const AppText(
                  'Mark as Paid',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
