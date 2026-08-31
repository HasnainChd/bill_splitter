import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_text.dart';
import '../../../core/utils/app_dialog.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../providers/settings_provider.dart';
import '../../providers/tab_providers.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../providers/profile_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/group_icon_helper.dart';
import '../../../core/utils/debt_calculator.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/models/group.dart';

class GlobalSettlement {
  final Group group;
  final Settlement settlement;
  GlobalSettlement({required this.group, required this.settlement});
}

final settleLoadingProvider =
    StateProvider.autoDispose<Set<String>>((ref) => {});
final settleAllLoadingProvider =
    StateProvider.autoDispose<bool>((ref) => false);

class SettleTab extends ConsumerWidget {
  const SettleTab({super.key});

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Color _getAvatarColor(String name) {
    final colors = [
      AppColors.avatarAmber,
      AppColors.avatarRose,
      AppColors.avatarEmerald,
      AppColors.onboardingCyan,
      AppColors.primaryPurple,
    ];
    if (name.isEmpty) return colors[0];
    final index =
        name.codeUnits.fold<int>(0, (sum, next) => sum + next) % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settleFilter = ref.watch(settleFilterProvider);
    final defaultCurrency = ref.watch(defaultCurrencyProvider);
    final currentUserId = ref.watch(supabaseUserProvider)?.id;
    final groups = ref.watch(groupProvider).groups;
    final loadingSettlements = ref.watch(settleLoadingProvider);
    final isSettleAllLoading = ref.watch(settleAllLoadingProvider);

    if (currentUserId == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.onboardingViolet,
        ),
      );
    }

    final List<GlobalSettlement> globalSettlements = [];
    final Map<String, UserProfile> userProfiles = {};
    final Map<String, Map<String, double>> groupBalances = {};

    for (final group in groups) {
      final balances = ref.watch(balancesForGroupProvider(group.groupId));
      groupBalances[group.groupId] = balances;
      final membersAsync = ref.watch(groupMembersProvider(group.groupId));

      membersAsync.whenData((members) {
        for (final m in members) {
          userProfiles[m.id] = m;
        }
      });

      // Map balances to Member list for debt calculator
      final membersList = balances.entries.map((entry) {
        final balance = entry.value;
        return Member(
          name: entry.key,
          totalPaid: balance > 0 ? balance : 0,
          totalShare: balance < 0 ? balance.abs() : 0,
        );
      }).toList();

      final groupSettlements = DebtCalculator.calculate(membersList);
      for (final s in groupSettlements) {
        globalSettlements.add(GlobalSettlement(group: group, settlement: s));
      }
    }

    // Filter settlements where current user is involved
    final myOwe = globalSettlements.where((gs) {
      return gs.settlement.fromMember == currentUserId &&
          gs.settlement.amount > 0.01;
    }).toList();

    final myOwed = globalSettlements.where((gs) {
      return gs.settlement.toMember == currentUserId &&
          gs.settlement.amount > 0.01;
    }).toList();

    // Summarize amounts per currency
    final Map<String, double> owesPerCurrency = {};
    for (final gs in myOwe) {
      owesPerCurrency[gs.group.currency] =
          (owesPerCurrency[gs.group.currency] ?? 0.0) + gs.settlement.amount;
    }

    final Map<String, double> owedPerCurrency = {};
    for (final gs in myOwed) {
      owedPerCurrency[gs.group.currency] =
          (owedPerCurrency[gs.group.currency] ?? 0.0) + gs.settlement.amount;
    }

    final String owesSummaryStr = owesPerCurrency.isEmpty
        ? '${_getSymbolForCurrency(defaultCurrency)} 0'
        : owesPerCurrency.entries
            .map((e) =>
                '${_getSymbolForCurrency(e.key)} ${e.value.toStringAsFixed(0)}')
            .join(', ');

    final String owedSummaryStr = owedPerCurrency.isEmpty
        ? '${_getSymbolForCurrency(defaultCurrency)} 0'
        : owedPerCurrency.entries
            .map((e) =>
                '${_getSymbolForCurrency(e.key)} ${e.value.toStringAsFixed(0)}')
            .join(', ');

    final owePeopleCount =
        myOwe.map((gs) => gs.settlement.toMember).toSet().length;
    final owedPeopleCount =
        myOwed.map((gs) => gs.settlement.fromMember).toSet().length;

    final hasSettlements = myOwe.isNotEmpty || myOwed.isNotEmpty;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          // Title
          const AppText(
            'Settle Up',
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
          ),
          SizedBox(height: 16.h),

          // ── Summary Cards ──
          Row(
            children: [
              _buildSummaryCard(
                'You Owe Others',
                owesSummaryStr,
                '$owePeopleCount ${owePeopleCount == 1 ? 'person' : 'people'}',
                AppColors.balanceOwed,
              ),
              SizedBox(width: 12.w),
              _buildSummaryCard(
                'Others Owe You',
                owedSummaryStr,
                '$owedPeopleCount ${owedPeopleCount == 1 ? 'person' : 'people'}',
                AppColors.balanceOwedTo,
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // ── Filter Chips ──
          Row(
            children: [
              _buildChip(ref, 'All', settleFilter),
              SizedBox(width: 8.w),
              _buildChip(ref, 'I Owe', settleFilter),
              SizedBox(width: 8.w),
              _buildChip(ref, 'Others Owe Me', settleFilter),
            ],
          ),
          SizedBox(height: 16.h),

          // ── Person Cards / List ──
          Expanded(
            child: !hasSettlements
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64.w,
                          height: 64.w,
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppColors.success,
                            size: 32.sp,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        const AppText(
                          'All Squared Up!',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                        SizedBox(height: 6.h),
                        AppText(
                          'You have no pending settlements.',
                          fontSize: 12,
                          color: AppColors.white.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(bottom: 16.h),
                    children: [
                      if (settleFilter == 'All' || settleFilter == 'I Owe') ...[
                        if (myOwe.isNotEmpty) ...[
                          _buildSectionLabel('YOU OWE OTHERS'),
                          ...myOwe.map((gs) {
                            final otherUserId = gs.settlement.toMember;
                            final otherName =
                                userProfiles[otherUserId]?.fullName ??
                                    'Other User';
                            final key =
                                '${gs.group.groupId}_${otherUserId}_${gs.settlement.amount}';
                            final isLoading = loadingSettlements.contains(key);

                            return Padding(
                              padding: EdgeInsets.only(bottom: 12.h),
                              child: _buildPersonCard(
                                context,
                                name: otherName,
                                sub: GroupIconHelper.getCleanGroupName(
                                    gs.group.name),
                                amount: (() {
                                  final rawCurrency = gs.group.currency;
                                  final clean = rawCurrency.contains(' ') ? rawCurrency.split(' ')[0] : rawCurrency;
                                  final clean3 = clean.length >= 3 ? clean.substring(0, 3) : clean;
                                  return '-$clean3 ${_getSymbolForCurrency(rawCurrency)}${gs.settlement.amount.toStringAsFixed(0)}';
                                })(),
                                amountColor: AppColors.balanceOwed,
                                buttonLabel: 'Pay',
                                isOwe: true,
                                initials: _getInitials(otherName),
                                avatarColor: _getAvatarColor(otherName),
                                isLoading: isLoading,
                                onTapButton: () async {
                                  final rawCurrency = gs.group.currency;
                                  final clean = rawCurrency.contains(' ') ? rawCurrency.split(' ')[0] : rawCurrency;
                                  final clean3 = clean.length >= 3 ? clean.substring(0, 3) : clean;
                                  final grpSymbol = _getSymbolForCurrency(rawCurrency);
                                  final confirm = await AppDialog.showConfirm(
                                    context,
                                    title: 'Confirm Payment',
                                    message:
                                        'Settle your debt of $clean3 $grpSymbol${gs.settlement.amount.toStringAsFixed(0)} with $otherName?',
                                    confirmText: 'Settle',
                                    cancelText: 'Cancel',
                                  );
                                  if (confirm == true) {
                                    ref
                                        .read(settleLoadingProvider.notifier)
                                        .update((state) => {...state, key});
                                    try {
                                      await ref
                                          .read(expenseProvider.notifier)
                                          .addExpense(
                                            groupId: gs.group.groupId,
                                            title: 'Settle Payment',
                                            amount: gs.settlement.amount,
                                            currency: gs.group.currency,
                                            paidBy: currentUserId,
                                            splitAmong: {
                                              otherUserId: gs.settlement.amount
                                            },
                                            categoryIconCodePoint: Icons
                                                .handshake_rounded.codePoint,
                                            splitType: 'Equal',
                                          );
                                      AnalyticsService.logSettleUpCompleted(
                                        currency: gs.group.currency,
                                        amount: gs.settlement.amount,
                                      );
                                      if (context.mounted) {
                                        AppSnackBar.showSuccess(
                                          context,
                                          'Payment of $grpSymbol ${gs.settlement.amount.toStringAsFixed(0)} to $otherName registered!',
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        AppDialog.showError(
                                          context,
                                          title: 'Payment Failed',
                                          message: 'Failed to record payment: $e',
                                        );
                                      }
                                    } finally {
                                      ref
                                          .read(settleLoadingProvider.notifier)
                                          .update(
                                            (state) => state
                                                .where((k) => k != key)
                                                .toSet(),
                                          );
                                    }
                                  }
                                },
                              ),
                            );
                          }),
                        ],
                      ],
                      if (settleFilter == 'All' ||
                          settleFilter == 'Others Owe Me') ...[
                        if (myOwed.isNotEmpty) ...[
                          _buildSectionLabel('OTHERS OWE YOU'),
                          ...myOwed.map((gs) {
                            final otherUserId = gs.settlement.fromMember;
                            final balances = groupBalances[gs.group.groupId] ?? {};
                            final otherBalance = balances[otherUserId] ?? 0.0;
                            if (otherBalance >= -0.01) {
                              return const SizedBox.shrink();
                            }

                            final otherName =
                                userProfiles[otherUserId]?.fullName ??
                                    'Other User';
                            final remindKey =
                                'remind_${gs.group.groupId}_${otherUserId}_${gs.settlement.amount}';
                            final isLoading =
                                loadingSettlements.contains(remindKey);

                            return Padding(
                              padding: EdgeInsets.only(bottom: 12.h),
                              child: _buildPersonCard(
                                context,
                                name: otherName,
                                sub: GroupIconHelper.getCleanGroupName(
                                    gs.group.name),
                                amount: (() {
                                  final rawCurrency = gs.group.currency;
                                  final clean = rawCurrency.contains(' ') ? rawCurrency.split(' ')[0] : rawCurrency;
                                  final clean3 = clean.length >= 3 ? clean.substring(0, 3) : clean;
                                  return '+$clean3 ${_getSymbolForCurrency(rawCurrency)}${gs.settlement.amount.toStringAsFixed(0)}';
                                })(),
                                amountColor: AppColors.balanceOwedTo,
                                buttonLabel: 'Remind',
                                isOwe: false,
                                initials: _getInitials(otherName),
                                avatarColor: _getAvatarColor(otherName),
                                isLoading: isLoading,
                                onTapButton: () async {
                                  final currentBalances = ref.read(balancesForGroupProvider(gs.group.groupId));
                                  final currentOtherBalance = currentBalances[otherUserId] ?? 0.0;
                                  if (currentOtherBalance >= -0.01) {
                                    AppSnackBar.showError(
                                      context,
                                      'This member does not owe any money!',
                                    );
                                    return;
                                  }

                                  final rawCurrency = gs.group.currency;
                                  final clean = rawCurrency.contains(' ') ? rawCurrency.split(' ')[0] : rawCurrency;
                                  final clean3 = clean.length >= 3 ? clean.substring(0, 3) : clean;
                                  final grpSymbol = _getSymbolForCurrency(rawCurrency);
                                  final confirm = await AppDialog.showConfirm(
                                    context,
                                    title: 'Send Reminder',
                                    message:
                                        'Send a payment reminder to $otherName for $clean3 $grpSymbol${gs.settlement.amount.toStringAsFixed(0)}?',
                                    confirmText: 'Send',
                                    cancelText: 'Cancel',
                                  );
                                  if (confirm == true) {
                                    ref
                                        .read(settleLoadingProvider.notifier)
                                        .update(
                                            (state) => {...state, remindKey});
                                    try {
                                      final response = await Supabase
                                          .instance.client.functions
                                          .invoke(
                                        'send-notification',
                                        body: {
                                          'table': 'payment_reminders',
                                          'new_record': {
                                            'group_id': gs.group.groupId,
                                            'sender_id': currentUserId,
                                            'target_user_id': otherUserId,
                                            'amount': gs.settlement.amount,
                                            'currency': gs.group.currency,
                                          },
                                        },
                                      );

                                      if (response.status != 200 &&
                                          response.status != 204) {
                                        throw Exception(
                                            'Server returned status code ${response.status}');
                                      }
                                      AnalyticsService.logRemindToSettleSent(reminderType: 'person');

                                      if (context.mounted) {
                                        AppSnackBar.showSuccess(
                                          context,
                                          'Reminder sent to $otherName!',
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        AppDialog.showError(
                                          context,
                                          title: 'Reminder Failed',
                                          message: 'Failed to send reminder: $e',
                                        );
                                      }
                                    } finally {
                                      ref
                                          .read(settleLoadingProvider.notifier)
                                          .update(
                                            (state) => state
                                                .where((k) => k != remindKey)
                                                .toSet(),
                                          );
                                    }
                                  }
                                },
                              ),
                            );
                          }),
                        ],
                      ],
                    ],
                  ),
          ),

          // ── Settle All button ──
          if ((settleFilter == 'All' || settleFilter == 'I Owe') &&
              myOwe.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 16.h, top: 8.h),
              child: Container(
                height: 48.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.success, AppColors.successDark],
                  ),
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: isSettleAllLoading
                      ? null
                      : () async {
                          final confirm = await AppDialog.showConfirm(
                            context,
                            title: 'Confirm Settlement',
                            message:
                                'Settle all your pending debts totaling $owesSummaryStr?',
                            confirmText: 'Settle All',
                            cancelText: 'Cancel',
                          );
                          if (confirm == true) {
                            ref.read(settleAllLoadingProvider.notifier).state =
                                true;
                            try {
                              for (final gs in myOwe) {
                                final otherUserId = gs.settlement.toMember;
                                await ref
                                    .read(expenseProvider.notifier)
                                    .addExpense(
                                      groupId: gs.group.groupId,
                                      title: 'Settle Payment',
                                      amount: gs.settlement.amount,
                                      currency: gs.group.currency,
                                      paidBy: currentUserId,
                                      splitAmong: {
                                        otherUserId: gs.settlement.amount
                                      },
                                      categoryIconCodePoint:
                                          Icons.handshake_rounded.codePoint,
                                      splitType: 'Equal',
                                    );
                              }
                              if (context.mounted) {
                                AppSnackBar.showSuccess(
                                  context,
                                  'All pending debts marked as settled!',
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                AppDialog.showError(
                                  context,
                                  title: 'Settlement Failed',
                                  message: 'Failed to settle debts: $e',
                                );
                              }
                            } finally {
                              ref
                                  .read(settleAllLoadingProvider.notifier)
                                  .state = false;
                            }
                          }
                        },
                  icon: isSettleAllLoading
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded,
                          color: AppColors.white, size: 20),
                  label: AppText(
                    'Settle All — Pay $owesSummaryStr',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.transparent,
                    shadowColor: AppColors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Helpers ──

  Widget _buildSummaryCard(
      String label, String value, String subtitle, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(label,
                fontSize: 12, color: AppColors.white.withValues(alpha: 0.5)),
            SizedBox(height: 6.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: AppText(
                value,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
                maxLines: 1,
              ),
            ),
            SizedBox(height: 4.h),
            AppText(subtitle,
                fontSize: 11, color: AppColors.white.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(WidgetRef ref, String label, String current) {
    final isSelected = current == label;
    return GestureDetector(
      onTap: () => ref.read(settleFilterProvider.notifier).state = label,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.onboardingViolet : AppColors.cardDark,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? AppColors.transparent
                : AppColors.white.withValues(alpha: 0.06),
          ),
        ),
        child: AppText(
          label,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSelected
              ? AppColors.white
              : AppColors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, top: 4.h),
      child: AppText(
        text,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.white.withValues(alpha: 0.4),
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildPersonCard(
    BuildContext context, {
    required String name,
    required String sub,
    required String amount,
    required Color amountColor,
    required String buttonLabel,
    required bool isOwe,
    required String initials,
    required Color avatarColor,
    required bool isLoading,
    required VoidCallback onTapButton,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration:
                BoxDecoration(color: avatarColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: AppText(initials,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.white),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(name,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white),
                SizedBox(height: 4.h),
                AppText(sub,
                    fontSize: 11,
                    color: AppColors.white.withValues(alpha: 0.4)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppText(amount,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: amountColor),
              SizedBox(height: 8.h),
              SizedBox(
                height: 28.h,
                child: isLoading
                    ? SizedBox(
                        width: 28.w,
                        height: 28.w,
                        child: const CircularProgressIndicator(
                          color: AppColors.onboardingViolet,
                          strokeWidth: 2,
                        ),
                      )
                    : isOwe
                        ? ElevatedButton(
                            onPressed: onTapButton,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.onboardingViolet,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(horizontal: 14.w),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                            ),
                            child: AppText(buttonLabel,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white),
                          )
                        : OutlinedButton(
                            onPressed: onTapButton,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: AppColors.white.withValues(alpha: 0.15),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.notifications_none_rounded,
                                    color:
                                        AppColors.white.withValues(alpha: 0.6),
                                    size: 12.sp),
                                SizedBox(width: 4.w),
                                AppText(buttonLabel,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.white),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getSymbolForCurrency(String code) {
    if (code.contains('(') && code.contains(')')) {
      final open = code.indexOf('(');
      final close = code.indexOf(')');
      if (close > open) return code.substring(open + 1, close);
    }
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
    return symbols[code] ?? code;
  }
}
