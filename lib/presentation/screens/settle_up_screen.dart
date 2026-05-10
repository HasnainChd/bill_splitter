import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/debt_calculator.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/settlement_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/utils/app_snackbar.dart';
import '../../providers/group_provider.dart';
import '../../providers/expense_provider.dart';

class SettleUpScreen extends ConsumerWidget {
  final String groupId;

  const SettleUpScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupNotifier = ref.read(groupProvider.notifier);
    final group = groupNotifier.getGroupById(groupId);
    final balances = ref.watch(balancesForGroupProvider(groupId));

    if (group == null) {
      return Scaffold(
        appBar: AppBar(
          title: const AppText('Group Not Found', color: AppColors.white),
        ),
        body: const Center(
          child: AppText('Group not found'),
        ),
      );
    }

    // Convert balances to Member list for debt calculator
    final members = balances.entries.map((entry) {
      final balance = entry.value;
      return Member(
        name: entry.key,
        totalPaid: balance > 0 ? balance : 0,
        totalShare: balance < 0 ? balance.abs() : 0,
      );
    }).toList();

    final settlements = DebtCalculator.calculate(members);
    final allSettled = settlements.every((s) => s.isPaid);
    final paidSettlements = settlements.where((s) => s.isPaid).toList();

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryMid, AppColors.primaryAccent],
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
              group.name,
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top summary card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppText(
                      "Minimum transactions to clear all debts",
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      align: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.swap_horiz_rounded,
                          color: AppColors.accent,
                          size: 20.sp,
                        ),
                        SizedBox(width: 6.w),
                        AppText(
                          "${settlements.length} transactions needed",
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ],
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
                    AppText(
                      "Settlements",
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
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
                            // TODo: Update settlement isPaid = true in provider
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
