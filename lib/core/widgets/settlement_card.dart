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
      decoration: BoxDecoration(
        color: isPaid ? AppColors.successLight : AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isPaid ? AppColors.success : AppColors.accent,
          width: 1.5,
        ),
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Row(
            children: [
              AppAvatar(
                name: fromMember,
                size: 40.sp,
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  children: [
                    Icon(
                      Icons.arrow_forward,
                      color: isPaid ? AppColors.textHint : AppColors.accent,
                      size: 24.sp,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '\$${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: isPaid ? 18.sp : 20.sp,
                        fontWeight: FontWeight.w700,
                        color: isPaid ? AppColors.textHint : AppColors.primary,
                        decoration: isPaid
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              AppAvatar(
                name: toMember,
                size: 40.sp,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          AppText(
            '$fromMember pays $toMember',
            fontSize: 13,
            color: AppColors.textSecondary,
            align: TextAlign.center,
          ),
          SizedBox(height: 16.h),
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
                Text(
                  'Paid',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            )
          else
            AppButton(
              label: 'Mark as Paid',
              onTap: onMarkAsPaid ?? () {},
              isOutlined: true,
              color: AppColors.success,
              width: double.infinity,
            ),
        ],
      ),
    );
  }
}
