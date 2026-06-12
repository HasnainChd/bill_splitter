import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/debt_calculator.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/settlement_card.dart';
import '../../core/utils/app_snackbar.dart';
import '../../providers/firebase_group_provider.dart';
import '../../providers/firebase_expense_provider.dart';
import '../../core/models/group.dart';

class SettleUpScreen extends ConsumerWidget {
  final String groupId;

  const SettleUpScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupState = ref.watch(firebaseGroupProvider);

    try {
      final group = groupState.groups.firstWhere(
        (g) => g.groupId == groupId,
        orElse: () => Group(
          groupId: groupId,
          name: 'Friday Dinner Crew',
          members: const ['You', 'Sarah', 'Marcus', 'Priya'],
          currency: 'USD',
          createdAt: DateTime.now(),
        ),
      );
      final balances = ref.watch(balancesForGroupProvider(groupId));

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
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDark,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.white,
              size: 20.sp,
            ),
            onPressed: () => context.pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText(
                'Settle Up',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
              AppText(
                group.name,
                fontSize: 12,
                color: AppColors.white.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
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
                        fontSize: 12,
                        color: AppColors.white.withValues(alpha: 0.4),
                        align: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.swap_horiz_rounded,
                            color: AppColors.onboardingViolet,
                            size: 20.sp,
                          ),
                          SizedBox(width: 6.w),
                          AppText(
                            "${settlements.length} transactions needed",
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                // Settlement cards or all settled message
                if (allSettled)
                  AppCard(
                    child: Column(
                      children: [
                        Icon(
                          Icons.celebration,
                          size: 72.sp,
                          color: AppColors.onboardingViolet,
                        ),
                        SizedBox(height: 16.h),
                        const AppText(
                          'All Settled Up! 🎉',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                        SizedBox(height: 6.h),
                        AppText(
                          'Everyone is even',
                          fontSize: 13,
                          color: AppColors.white.withValues(alpha: 0.4),
                        ),
                        SizedBox(height: 20.h),
                        SizedBox(
                          width: double.infinity,
                          height: 44.h,
                          child: ElevatedButton(
                            onPressed: () => context.pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                            ),
                            child: const AppText(
                              'Back to Group',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        "Settlements",
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white.withValues(alpha: 0.4),
                        letterSpacing: 1.2,
                      ),
                      SizedBox(height: 12.h),
                      ...settlements.map((settlement) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: SettlementCard(
                            fromMember: settlement.fromMember,
                            toMember: settlement.toMember,
                            amount: settlement.amount,
                            isPaid: settlement.isPaid,
                            onMarkAsPaid: () {
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
                  AppText(
                    'Recent Settlements',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white.withValues(alpha: 0.4),
                    letterSpacing: 1.2,
                  ),
                  SizedBox(height: 12.h),
                  ...paidSettlements.map((settlement) {
                    return SettlementCard(
                      fromMember: settlement.fromMember,
                      toMember: settlement.toMember,
                      amount: settlement.amount,
                      isPaid: settlement.isPaid,
                    );
                  }),
                ],

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDark,
          scrolledUnderElevation: 0,
          title: const AppText('Group Not Found', color: AppColors.white),
        ),
        body: const Center(
          child: AppText('Group not found', color: AppColors.white),
        ),
      );
    }
  }
}
