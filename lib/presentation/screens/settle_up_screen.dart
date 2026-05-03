import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/debt_calculator.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/settlement_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/utils/app_snackbar.dart';

class SettleUpScreen extends StatelessWidget {
  final String groupId;

  SettleUpScreen({super.key, required this.groupId});

  // Mock data for demonstration
  final List<Member> _mockMembers = [
    Member(name: 'John', totalPaid: 200.0, totalShare: 100.0), // +100
    Member(name: 'Sarah', totalPaid: 50.0, totalShare: 100.0), // -50
    Member(name: 'Mike', totalPaid: 25.0, totalShare: 100.0), // -75
    Member(name: 'You', totalPaid: 125.0, totalShare: 100.0), // +25
  ];

  @override
  Widget build(BuildContext context) {
    final settlements = DebtCalculator.calculate(_mockMembers);
    final allSettled = settlements.every((s) => s.isPaid);
    final paidSettlements = settlements.where((s) => s.isPaid).toList();

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText(
                'Settle Up',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnPrimary,
              ),
              AppText(
                groupId,
                fontSize: 14,
                color: AppColors.textOnPrimary.withValues(alpha: 0.7),
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textOnPrimary),
            onPressed: () => context.go('/'),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top summary card
              AppCard(
                child: Column(
                  children: [
                    AppText(
                      'Minimum transactions to clear all debts',
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: 8.h),
                    AppText(
                      '${settlements.length} transactions needed',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Settlement cards or all settled message
              if (allSettled)
                AppCard(
                  child: Column(
                    children: [
                      Icon(
                        Icons.celebration,
                        size: 80.sp,
                        color: AppColors.accent,
                      ),
                      SizedBox(height: 16.h),
                      const AppText(
                        'All Settled Up! 🎉',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      SizedBox(height: 8.h),
                      const AppText(
                        'Everyone is even',
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: 16.h),
                      AppButton(
                        label: 'Back to Group',
                        onTap: () => context.pop(),
                        color: AppColors.success,
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    const AppText(
                      'Settlements',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    SizedBox(height: 16.h),
                    ...settlements.map((settlement) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: SettlementCard(
                          fromMember: settlement.fromMember,
                          toMember: settlement.toMember,
                          amount: settlement.amount,
                          isPaid: settlement.isPaid,
                          onMarkAsPaid: () {
                            // TODO: Update settlement isPaid = true in provider
                            AppSnackBar.showSuccess(
                                context, 'Payment recorded');
                          },
                        ),
                      );
                    }),
                  ],
                ),

              if (!allSettled) SizedBox(height: 16.h),

              // Recent settlements - only show if there are paid settlements
              if (paidSettlements.isNotEmpty) ...[
                SizedBox(height: 24.h),
                const AppText(
                  'Recent Settlements',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: 12.h),
                ...paidSettlements.map((settlement) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: SettlementCard(
                      fromMember: settlement.fromMember,
                      toMember: settlement.toMember,
                      amount: settlement.amount,
                      isPaid: settlement.isPaid,
                      onMarkAsPaid: () {
                        // Already paid, no action needed
                      },
                    ),
                  );
                }),
              ],

              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }
}
