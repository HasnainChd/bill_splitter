import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import 'app_text.dart';
import 'app_avatar.dart';

class BalanceRow extends StatelessWidget {
  final String memberName;
  final double balance;

  const BalanceRow({
    super.key,
    required this.memberName,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = balance > 0;
    final isZero = balance == 0;

    String balanceText;
    Color balanceColor;

    if (isZero) {
      balanceText = 'settled';
      balanceColor = AppColors.textHint;
    } else if (isPositive) {
      balanceText = 'gets back \$${balance.abs().toStringAsFixed(2)}';
      balanceColor = AppColors.success;
    } else {
      balanceText = 'owes \$${balance.abs().toStringAsFixed(2)}';
      balanceColor = AppColors.error;
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          AppAvatar(
            name: memberName,
            size: 40.sp,
          ),
          SizedBox(width: 16.w),
          AppText(
            memberName,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          const Spacer(),
          AppText(
            balanceText,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: balanceColor,
          ),
        ],
      ),
    );
  }
}
