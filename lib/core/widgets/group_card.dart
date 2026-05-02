import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import 'app_text.dart';
import 'app_card.dart';
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
    final isPositive = balance >= 0;
    final balanceText = isPositive
        ? '+\$${balance.abs().toStringAsFixed(2)}'
        : '-\$${balance.abs().toStringAsFixed(2)}';
    final balanceColor = isPositive ? AppColors.success : AppColors.error;
    final statusText = isPositive ? 'you are owed' : 'you owe';

    return AppCard(
      onTap: onTap,
      highlighted: isPositive && balance > 0,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          AppAvatar(
            name: groupName,
            size: 48.sp,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  groupName,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
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
                balanceText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: balanceColor,
              ),
              SizedBox(height: 2.h),
              AppText(
                statusText,
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          SizedBox(width: 8.w),
          Icon(
            Icons.arrow_forward_ios,
            size: 16.sp,
            color: AppColors.textHint,
          ),
        ],
      ),
    );
  }
}
