import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import 'app_text.dart';
import 'app_card.dart';

class ExpenseTile extends StatelessWidget {
  final String expenseName;
  final String paidByName;
  final double amount;
  final String date;
  final IconData categoryIcon;
  final VoidCallback? onTap;

  const ExpenseTile({
    super.key,
    required this.expenseName,
    required this.paidByName,
    required this.amount,
    required this.date,
    required this.categoryIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24.sp,
            backgroundColor: AppColors.primaryLight,
            child: Icon(
              categoryIcon,
              color: AppColors.primary,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  expenseName,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: 4.h),
                AppText(
                  'Paid by $paidByName',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText(
                '\$${amount.toStringAsFixed(2)}',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: 4.h),
              AppText(
                date,
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
