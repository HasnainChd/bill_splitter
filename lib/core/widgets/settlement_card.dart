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
  final String currency;
  final bool isLoading;
  final VoidCallback? onMarkAsPaid;

  final String? fromAvatarUrl;
  final String? toAvatarUrl;

  const SettlementCard({
    super.key,
    required this.fromMember,
    required this.toMember,
    required this.amount,
    required this.isPaid,
    this.currency = 'USD',
    this.isLoading = false,
    this.onMarkAsPaid,
    this.fromAvatarUrl,
    this.toAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final cleanCurrency = currency.contains(' ') ? currency.split(' ')[0] : currency;
    final cleanCurrency3 = cleanCurrency.length >= 3 ? cleanCurrency.substring(0, 3) : cleanCurrency;
    final symbol = (() {
      final Map<String, String> symbols = {
        'USD': '\$',
        'EUR': '€',
        'GBP': '£',
        'INR': '₹',
        'PKR': 'Rs',
        'JPY': '¥',
        'AUD': 'A\$',
        'CAD': 'C\$',
        'CHF': 'CHF',
        'CNY': '¥',
        'SGD': 'S\$',
        'NZD': 'NZ\$',
      };
      return symbols[cleanCurrency3] ?? cleanCurrency3;
    })();
    final formattedAmount = '$cleanCurrency3 $symbol${amount.toStringAsFixed(0)}';

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
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppAvatar(
                      name: fromMember,
                      size: 44.sp,
                      avatarUrl: fromAvatarUrl,
                    ),
                    SizedBox(height: 6.h),
                    AppText(
                      fromMember,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                      align: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Center: arrow + amount
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.onboardingViolet,
                      size: 20.sp,
                    ),
                    SizedBox(height: 4.h),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: AppText(
                        formattedAmount,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isPaid ? AppColors.success : AppColors.white,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    AppText(
                      '$fromMember pays $toMember',
                      fontSize: 10,
                      color: AppColors.white.withValues(alpha: 0.4),
                      align: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // To member
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppAvatar(
                      name: toMember,
                      size: 44.sp,
                      avatarUrl: toAvatarUrl,
                    ),
                    SizedBox(height: 6.h),
                    AppText(
                      toMember,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                      align: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
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
                onPressed: isLoading ? null : onMarkAsPaid,
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
                child: isLoading
                    ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
                        ),
                      )
                    : const AppText(
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
