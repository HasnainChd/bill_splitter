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
import '../../providers/group_provider.dart';
import '../../providers/expense_provider.dart';
import '../../core/models/group.dart';
import '../../providers/profile_provider.dart';
import '../../core/utils/group_icon_helper.dart';

class SettleUpScreen extends ConsumerStatefulWidget {
  final String groupId;

  const SettleUpScreen({super.key, required this.groupId});

  @override
  ConsumerState<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends ConsumerState<SettleUpScreen> {
  final Set<String> _loadingSettlements = {};

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(groupProvider);
    final membersAsync = ref.watch(groupMembersProvider(widget.groupId));

    try {
      final group = groupState.groups.firstWhere(
        (g) => g.groupId == widget.groupId,
        orElse: () => Group(
          groupId: widget.groupId,
          name: 'Group Detail',
          members: const [],
          currency: 'PKR',
          createdAt: DateTime.now(),
        ),
      );
      final currencyCode = group.currency;
      final balances = ref.watch(balancesForGroupProvider(widget.groupId));

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

      // Lookup names map from UUIDs
      final memberMap = {
        for (final m in membersAsync.value ?? <UserProfile>[]) m.id: m.fullName,
      };

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
                GroupIconHelper.getCleanGroupName(group.name),
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
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 48.w,
                          height: 48.w,
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.handshake_rounded,
                            color: AppColors.success,
                            size: 24.sp,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        AppText(
                          allSettled ? 'All Settled!' : 'Pending Settlements',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                        SizedBox(height: 6.h),
                        AppText(
                          allSettled
                              ? 'Everyone in ${GroupIconHelper.getCleanGroupName(group.name)} is squared up!'
                              : 'Resolve balances below to square up the group.',
                          fontSize: 12,
                          color: AppColors.white.withValues(alpha: 0.4),
                          align: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // Active settlements
                if (settlements.isNotEmpty)
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
                        final fromProfile = (membersAsync.value ?? <UserProfile>[])
                            .firstWhere((m) => m.id == settlement.fromMember,
                                orElse: () => UserProfile(
                                      id: settlement.fromMember,
                                      fullName: settlement.fromMember,
                                      username: '',
                                      email: '',
                                      phone: '',
                                      bio: '',
                                      currency: '',
                                      avatarUrl: '',
                                    ));
                        final toProfile = (membersAsync.value ?? <UserProfile>[])
                            .firstWhere((m) => m.id == settlement.toMember,
                                orElse: () => UserProfile(
                                      id: settlement.toMember,
                                      fullName: settlement.toMember,
                                      username: '',
                                      email: '',
                                      phone: '',
                                      bio: '',
                                      currency: '',
                                      avatarUrl: '',
                                    ));

                        final fromName = fromProfile.fullName;
                        final toName = toProfile.fullName;

                        final key =
                            '${settlement.fromMember}_${settlement.toMember}_${settlement.amount}';
                        final isLoading = _loadingSettlements.contains(key);

                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: SettlementCard(
                            fromMember: fromName,
                            toMember: toName,
                            fromAvatarUrl: fromProfile.avatarUrl,
                            toAvatarUrl: toProfile.avatarUrl,
                            amount: settlement.amount,
                            isPaid: settlement.isPaid,
                            currency: currencyCode,
                            isLoading: isLoading,
                            onMarkAsPaid: () async {
                              setState(() {
                                _loadingSettlements.add(key);
                              });
                              try {
                                await ref
                                    .read(expenseProvider.notifier)
                                    .addExpense(
                                      groupId: widget.groupId,
                                      title: 'Settle Payment',
                                      amount: settlement.amount,
                                      currency: group.currency,
                                      paidBy: settlement.fromMember,
                                      splitAmong: {
                                        settlement.toMember: settlement.amount
                                      },
                                      categoryIconCodePoint:
                                          Icons.handshake_rounded.codePoint,
                                      splitType: 'Equal',
                                    );
                                if (context.mounted) {
                                  AppSnackBar.showSuccess(
                                      context, 'Payment recorded!');
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  AppSnackBar.showError(
                                      context, 'Failed to record payment: $e');
                                }
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _loadingSettlements.remove(key);
                                  });
                                }
                              }
                            },
                          ),
                        );
                      }),
                    ],
                  ),

                if (!allSettled) SizedBox(height: 16.h),

                // Recent settlements
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
                    final fromName = memberMap[settlement.fromMember] ??
                        settlement.fromMember;
                    final toName =
                        memberMap[settlement.toMember] ?? settlement.toMember;

                    return SettlementCard(
                      fromMember: fromName,
                      toMember: toName,
                      amount: settlement.amount,
                      isPaid: settlement.isPaid,
                      currency: currencyCode,
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
