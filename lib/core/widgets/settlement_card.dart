import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import 'app_text.dart';
import 'app_avatar.dart';
import 'app_button.dart';
import 'app_card.dart';

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
    return AppCard(
      padding: EdgeInsets.all(16.w),
      highlighted: !isPaid,
      color: isPaid ? AppColors.successLight : null,
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
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                    SizedBox(height: 4.h),
                    AppText(
                      '\$${amount.toStringAsFixed(2)}',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
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
            fontSize: 14,
            color: AppColors.textSecondary,
            align: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          if (isPaid)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  AppText(
                    'Paid',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ],
              ),
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
