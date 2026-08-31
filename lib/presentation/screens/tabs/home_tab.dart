import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/group.dart';
import '../../../core/models/expense.dart';
import '../../../core/widgets/app_text.dart';
import '../../../core/router/app_router.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../providers/tab_providers.dart';
import '../../../core/widgets/app_shimmer.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/notifications_provider.dart';
import '../../../core/utils/group_icon_helper.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/financial_calculator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/receipt_scanner_service.dart';
import '../../../core/services/analytics_service.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  Color _getAvatarColorForInitials(String initials) {
    final colors = [
      AppColors.avatarAmber,
      AppColors.avatarRose,
      AppColors.avatarEmerald,
      AppColors.onboardingCyan,
      AppColors.primaryPurple,
    ];
    if (initials.isEmpty) return colors[0];
    final index = initials.codeUnits.fold<int>(0, (sum, next) => sum + next) %
        colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupState = ref.watch(groupProvider);
    final groups = groupState.groups;
    final defaultGroup = groups.isNotEmpty ? groups.first : null;
    final defaultCurrency = ref.watch(defaultCurrencyProvider);
    final currencyCode =
        defaultCurrency.length >= 3 ? defaultCurrency.substring(0, 3) : 'PKR';
    final currentUserId = ref.watch(supabaseUserProvider)?.id;
    final profile = ref.watch(profileProvider).profile;
    final notifications = ref.watch(dynamicNotificationsProvider);
    final recentNotifications = notifications.take(4).toList();

    // Dynamic greeting based on time of day
    final hour = DateTime.now().hour;
    final String greeting;
    final String greetingIcon;
    if (hour < 12) {
      greeting = 'Good morning';
      greetingIcon = '☀️';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
      greetingIcon = '🌤️';
    } else if (hour < 21) {
      greeting = 'Good evening';
      greetingIcon = '🌆';
    } else {
      greeting = 'Good night';
      greetingIcon = '🌙';
    }

    // Calculate dynamic balance totals using central FinancialCalculator
    final expenseState = ref.watch(expenseProvider);
    final pageIndex = ref.watch(homeBalancePageIndexProvider);

    // Group expenses by currency code
    final Map<String, List<Expense>> currencyExpensesMap = {};
    if (currentUserId != null) {
      for (final e in expenseState.expenses) {
        currencyExpensesMap.putIfAbsent(e.currency, () => []).add(e);
      }
    }

    // If empty, default to user's default currency
    if (currencyExpensesMap.isEmpty) {
      currencyExpensesMap[currencyCode] = [];
    }

    final currencyKeys = currencyExpensesMap.keys.toList();
    currencyKeys.sort((a, b) {
      if (a == currencyCode) return -1;
      if (b == currencyCode) return 1;
      return a.compareTo(b);
    });

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(groupProvider.notifier).loadGroups();
        await ref.read(profileProvider.notifier).fetchProfile();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        '$greeting $greetingIcon',
                        fontSize: 14,
                        color: AppColors.white.withValues(alpha: 0.5),
                      ),
                      SizedBox(height: 4.h),
                      profile == null
                          ? AppShimmer(
                              width: 200.w,
                              height: 32.h,
                              borderRadius: BorderRadius.circular(8.r),
                            )
                          : AppText(
                              profile.fullName,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                            ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildHeaderIconButton(Icons.search_rounded, () {
                        ref.read(homeTabIndexProvider.notifier).state = 1;
                      }),
                      SizedBox(width: 12.w),
                      _buildHeaderIconButton(
                        Icons.notifications_none_rounded,
                        () => context.push(AppRouter.notifications),
                        hasBadge: notifications.isNotEmpty,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Balance Summary Card ──
            () {
              final List<Widget> balanceCards = [];

              for (final curKey in currencyKeys) {
                final curExps = currencyExpensesMap[curKey] ?? [];
                final totals = currentUserId != null
                    ? FinancialCalculator.calculateUserGlobalBalances(
                        currentUserId, curExps)
                    : {'owes': 0.0, 'owedToYou': 0.0, 'net': 0.0};

                final totalOwe = totals['owes'] ?? 0.0;
                final totalOwed = totals['owedToYou'] ?? 0.0;
                final netBalance = totals['net'] ?? 0.0;
                final curSymbol = _getSymbolForCurrency(curKey);

                balanceCards.add(
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Container(
                      width: double.infinity,
                      height: 185.h,
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.onboardingViolet,
                            AppColors.primaryPurpleDarker,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AppText(
                                "Total Others Owe You",
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white.withValues(alpha: 0.8),
                              ),
                              if (currencyKeys.length > 1)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: AppText(
                                    curKey,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.white,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          (groupState.isLoading && groups.isEmpty)
                              ? Padding(
                                  padding: EdgeInsets.symmetric(vertical: 6.h),
                                  child: AppShimmer(width: 120.w, height: 28.h),
                                )
                              : AppText(
                                  '$curSymbol ${totalOwed.toStringAsFixed(0)}',
                                  fontSize: 32.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.white,
                                ),
                          const Spacer(),
                          Row(
                            children: [
                              _buildBalanceSubCol(
                                  'You owe others',
                                  (groupState.isLoading && groups.isEmpty)
                                      ? null
                                      : '$curSymbol ${totalOwe.toStringAsFixed(0)}',
                                  AppColors.balanceOwed),
                              _buildBalanceDivider(),
                              _buildBalanceSubCol(
                                  'Others owe you',
                                  (groupState.isLoading && groups.isEmpty)
                                      ? null
                                      : '$curSymbol ${totalOwed.toStringAsFixed(0)}',
                                  AppColors.balanceOwedTo),
                              _buildBalanceDivider(),
                              _buildBalanceSubCol(
                                  'Overall net balance',
                                  (groupState.isLoading && groups.isEmpty)
                                      ? null
                                      : (netBalance > 0
                                          ? '+$curSymbol ${netBalance.toStringAsFixed(0)}'
                                          : netBalance < 0
                                              ? '-$curSymbol ${netBalance.abs().toStringAsFixed(0)}'
                                              : '$curSymbol 0'),
                                  netBalance > 0
                                      ? AppColors.balanceOwedTo
                                      : netBalance < 0
                                          ? AppColors.balanceOwed
                                          : AppColors.white),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (balanceCards.length == 1) {
                return balanceCards.first;
              }

              return Column(
                children: [
                  SizedBox(
                    height: 185.h,
                    child: PageView(
                      onPageChanged: (idx) {
                        ref.read(homeBalancePageIndexProvider.notifier).state =
                            idx;
                      },
                      children: balanceCards,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      balanceCards.length,
                      (index) => Container(
                        width: 6.w,
                        height: 6.w,
                        margin: EdgeInsets.symmetric(horizontal: 3.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: pageIndex == index
                              ? AppColors.onboardingViolet
                              : AppColors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }(),
            SizedBox(height: 24.h),

            // ── Quick Actions ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickAction(
                      'Add\nExpense', Icons.add, AppColors.onboardingViolet,
                      () {
                    // Navigate to add expense screen with default group
                    if (defaultGroup != null) {
                      context.push(AppRouter.addExpense, extra: defaultGroup);
                    }
                  }),
                  _buildQuickAction(
                      'Settle\nUp', Icons.check_rounded, AppColors.success, () {
                    ref.read(homeTabIndexProvider.notifier).state = 2;
                  }),
                  _buildQuickAction('Scan\nReceipt', Icons.camera_alt_outlined,
                      AppColors.onboardingCyan, () {
                    if (defaultGroup != null) {
                      _showScanReceiptSourceSheet(context, ref, defaultGroup);
                    } else {
                      AppSnackBar.showError(context,
                          'Please create a group first to scan receipts.');
                    }
                  }),
                  _buildQuickAction(
                      'Remind to\nSettle', Icons.send_rounded, AppColors.orange,
                      () {
                    _showSelectGroupSheet(context, ref, groups);
                  }),
                ],
              ),
            ),
            SizedBox(height: 28.h),
            // ── Active Groups Section ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppText(
                    'Active Groups',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                  GestureDetector(
                    onTap: () =>
                        ref.read(homeTabIndexProvider.notifier).state = 1,
                    child: const AppText(
                      'See all',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onboardingViolet,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              height: 156.h,
              child: (groupState.isLoading && groups.isEmpty)
                  ? ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      itemCount: 3,
                      separatorBuilder: (context, index) =>
                          SizedBox(width: 12.w),
                      itemBuilder: (context, index) {
                        return AppShimmer(
                          width: 148.w,
                          height: 156.h,
                          borderRadius: BorderRadius.circular(20.r),
                        );
                      },
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      itemCount: groups.length + 1,
                      separatorBuilder: (context, index) =>
                          SizedBox(width: 12.w),
                      itemBuilder: (context, index) {
                        if (index == groups.length) {
                          return _buildNewGroupCard(context);
                        }

                        final group = groups[index];
                        final balances =
                            ref.watch(balancesForGroupProvider(group.groupId));
                        final myBalance = currentUserId != null
                            ? (balances[currentUserId] ?? 0.0)
                            : 0.0;
                        final membersAsync =
                            ref.watch(groupMembersProvider(group.groupId));
                        final expenseState = ref.watch(expenseProvider);
                        final groupExpenses = expenseState.expenses
                            .where((e) => e.groupId == group.groupId)
                            .toList();

                        final groupIcon =
                            GroupIconHelper.getIconForGroup(group);

                        final gradients = [
                          [
                            AppColors.onboardingViolet,
                            AppColors.onboardingVioletDark
                          ],
                          [AppColors.groupBlue, AppColors.groupBlueDark],
                          [AppColors.groupOrange, AppColors.groupOrangeDark],
                        ];
                        final gradient = gradients[index % gradients.length];

                        final String balanceText;
                        final Color balanceColor;
                        if (myBalance > 0) {
                          balanceText =
                              '+${group.currency} ${myBalance.toStringAsFixed(0)}';
                          balanceColor = AppColors.balanceOwedTo;
                        } else if (myBalance < 0) {
                          balanceText =
                              '-${group.currency} ${myBalance.abs().toStringAsFixed(0)}';
                          balanceColor = AppColors.balanceOwed;
                        } else {
                          balanceText = groupExpenses.isEmpty
                              ? 'No expenses yet'
                              : 'Settled';
                          balanceColor = AppColors.white.withValues(alpha: 0.5);
                        }

                        final List<String> initialsList = membersAsync.when(
                          data: (members) => members.map((m) {
                            final name = m.fullName.trim();
                            if (name.isEmpty) return 'U';
                            final parts = name.split(' ');
                            if (parts.length > 1) {
                              return (parts[0][0] + parts[parts.length - 1][0])
                                  .toUpperCase();
                            }
                            return parts[0][0].toUpperCase();
                          }).toList(),
                          loading: () => ['?'],
                          error: (_, __) => ['?'],
                        );

                        return _buildGroupCard(
                          context: context,
                          group: group,
                          icon: groupIcon,
                          gradient: gradient,
                          expenses:
                              '${groupExpenses.length} ${groupExpenses.length == 1 ? 'expense' : 'expenses'}',
                          amount: balanceText,
                          amountColor: balanceColor,
                          avatars: initialsList,
                        );
                      },
                    ),
            ),
            SizedBox(height: 28.h),

            // ── Recent Activity Section ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppText(
                    'Recent Activity',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppRouter.activity),
                    child: const AppText(
                      'See all',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onboardingViolet,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: (groupState.isLoading && groups.isEmpty)
                    ? ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        itemCount: 3,
                        separatorBuilder: (context, index) =>
                            _buildActivityDivider(),
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 12.h),
                            child: Row(
                              children: [
                                AppShimmer(
                                    width: 38.w,
                                    height: 38.w,
                                    borderRadius: BorderRadius.circular(10.r)),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AppShimmer(width: 120.w, height: 12.h),
                                      SizedBox(height: 6.h),
                                      AppShimmer(width: 80.w, height: 10.h),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                AppShimmer(width: 45.w, height: 14.h),
                              ],
                            ),
                          );
                        },
                      )
                    : recentNotifications.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.h),
                              child: AppText(
                                'No recent activity yet.',
                                fontSize: 13,
                                color: AppColors.white.withValues(alpha: 0.4),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            itemCount: recentNotifications.length,
                            separatorBuilder: (context, index) =>
                                _buildActivityDivider(),
                            itemBuilder: (context, index) {
                              final item = recentNotifications[index];
                              final isPositive =
                                  item.amount?.startsWith('+') ?? false;
                              return InkWell(
                                onTap: () {
                                  if (item.groupId != null) {
                                    context.push(AppRouter.groupDetail,
                                        extra: item.groupId);
                                  }
                                },
                                child: _buildActivityRow(
                                  title: item.title,
                                  sub:
                                      '${GroupIconHelper.getCleanGroupName(item.groupName)} • ${item.subtitle}',
                                  amount: item.amount ?? '',
                                  isPositive: isPositive,
                                  icon: item.badgeIcon,
                                ),
                              );
                            },
                          ),
              ),
            ),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  // Helper: Header Icon Button
  Widget _buildHeaderIconButton(IconData icon, VoidCallback onTap,
      {bool hasBadge = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: AppColors.white, size: 20.sp),
            if (hasBadge)
              Positioned(
                top: 10.w,
                right: 10.w,
                child: Container(
                  width: 7.w,
                  height: 7.w,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper: Balance Summary Columns
  Widget _buildBalanceSubCol(String label, String? value, Color valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AppText(
              label,
              fontSize: 11.sp,
              color: AppColors.white.withValues(alpha: 0.6),
              maxLines: 1,
            ),
          ),
          SizedBox(height: 4.h),
          value == null
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  child: AppShimmer(width: 60.w, height: 14.h),
                )
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: AppText(
                    value,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                    maxLines: 1,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildBalanceDivider() {
    return Container(
      width: 1,
      height: 32.h,
      color: AppColors.white.withValues(alpha: 0.15),
      margin: EdgeInsets.symmetric(horizontal: 8.w),
    );
  }

  // Helper: Quick Action Button
  Widget _buildQuickAction(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: color, size: 22.sp),
          ),
          SizedBox(height: 8.h),
          AppText(
            label,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.white.withValues(alpha: 0.7),
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper: Horizontal Group Card
  Widget _buildGroupCard({
    required BuildContext context,
    required Group group,
    required IconData icon,
    required List<Color> gradient,
    required String expenses,
    required String amount,
    required Color amountColor,
    required List<String> avatars,
  }) {
    return Container(
      width: 148.w,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: InkWell(
        onTap: () {
          context.push(AppRouter.groupDetail, extra: group.groupId);
        },
        borderRadius: BorderRadius.circular(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.white, size: 24.sp),
            const Spacer(),
            AppText(
              GroupIconHelper.getCleanGroupName(group.name),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12.h),
            _buildOverlappingAvatars(avatars),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: AppText(
                    expenses,
                    fontSize: 10,
                    color: AppColors.white.withValues(alpha: 0.7),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 4.w),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: AppText(
                      amount,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: amountColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper: Dotted New Group Card
  Widget _buildNewGroupCard(BuildContext context) {
    return Container(
      width: 148.w,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.08),
          style: BorderStyle.solid,
        ),
      ),
      child: InkWell(
        onTap: () => context.push(AppRouter.createGroup),
        borderRadius: BorderRadius.circular(20.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add,
                  color: AppColors.white.withValues(alpha: 0.6), size: 20.sp),
            ),
            SizedBox(height: 10.h),
            AppText(
              'New\nGroup',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.white.withValues(alpha: 0.5),
              align: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper: Overlapping Avatars
  Widget _buildOverlappingAvatars(List<String> initials) {
    return SizedBox(
      height: 20.h,
      width: initials.isEmpty ? 0 : (initials.length - 1) * 12.w + 20.h,
      child: Stack(
        children: List.generate(initials.length, (index) {
          final initial = initials[index];
          final Color avatarBg = _getAvatarColorForInitials(initial);

          return Positioned(
            left: index * 12.w,
            child: Container(
              width: 20.h,
              height: 20.h,
              decoration: BoxDecoration(
                color: avatarBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.backgroundDark,
                  width: 1.5.w,
                ),
              ),
              alignment: Alignment.center,
              child: AppText(
                initial,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActivityRow({
    required String title,
    required String sub,
    required String amount,
    required bool isPositive,
    required IconData icon,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              icon,
              color: AppColors.white.withValues(alpha: 0.6),
              size: 18.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
                SizedBox(height: 4.h),
                AppText(
                  sub,
                  fontSize: 11.sp,
                  color: AppColors.white.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          AppText(
            amount,
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: isPositive ? AppColors.balanceOwedTo : AppColors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityDivider() {
    return Divider(
      color: AppColors.white.withValues(alpha: 0.04),
      height: 1,
      thickness: 1,
    );
  }

  void _showScanReceiptSourceSheet(
      BuildContext context, WidgetRef ref, Group defaultGroup) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText(
                'Scan Receipt',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
              SizedBox(height: 4.h),
              AppText(
                'Choose how you want to upload the receipt',
                fontSize: 12,
                color: AppColors.white.withValues(alpha: 0.5),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: _buildSourceButton(
                      sheetContext,
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _processReceipt(
                            context, ref, defaultGroup, ImageSource.camera);
                      },
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildSourceButton(
                      sheetContext,
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _processReceipt(
                            context, ref, defaultGroup, ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceButton(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.onboardingViolet, size: 28.sp),
            SizedBox(height: 8.h),
            AppText(
              label,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ],
        ),
      ),
    );
  }

  void _processReceipt(BuildContext context, WidgetRef ref, Group defaultGroup,
      ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: source);
      if (file == null) return;

      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _ReceiptProcessingDialog(),
      );

      final scanner = ReceiptScannerService();
      final result = await scanner.scanReceipt(file.path);
      scanner.dispose();

      if (!context.mounted) return;
      Navigator.pop(context); // Close dialog

      if (!result.hasAmount && context.mounted) {
        AppSnackBar.showError(
          context,
          'Could not extract amount from receipt. Please enter manually.',
        );
      }

      if (!context.mounted) return;
      context.push(AppRouter.addExpense, extra: {
        'group': defaultGroup,
        'scannedAmount': result.hasAmount
            ? (result.extractedAmount! % 1 == 0
                ? result.extractedAmount!.toStringAsFixed(0)
                : result.extractedAmount!.toStringAsFixed(2))
            : '',
        'scannedTitle': result.hasTitle ? result.extractedTitle : '',
        'scannedImagePath': file.path,
      });
    } catch (e) {
      debugPrint('Error scanning receipt: $e');
      if (context.mounted) {
        Navigator.pop(context); // Close dialog if open
        AppSnackBar.showError(
          context,
          'Failed to scan receipt. Please try again or enter manually.',
        );
      }
    }
  }

  void _showSelectGroupSheet(
      BuildContext context, WidgetRef ref, List<Group> groups) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText(
                'Remind to Settle',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
              SizedBox(height: 4.h),
              AppText(
                'Select a group to remind members to settle',
                fontSize: 12,
                color: AppColors.white.withValues(alpha: 0.5),
              ),
              SizedBox(height: 16.h),
              if (groups.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Center(
                    child: AppText(
                      'No active groups found.',
                      fontSize: 14,
                      color: AppColors.white.withValues(alpha: 0.4),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: groups.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: 10.h),
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 4.h),
                        tileColor: AppColors.white.withValues(alpha: 0.04),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.onboardingViolet.withValues(alpha: 0.1),
                          child: Icon(
                            GroupIconHelper.getIconForGroup(group),
                            color: AppColors.onboardingViolet,
                          ),
                        ),
                        title: AppText(
                          group.name,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.white.withValues(alpha: 0.4),
                        ),
                        onTap: () async {
                          // Insert into requests table, preventing duplicate pending requests
                          try {
                            // Check if group has any outstanding balances
                            final balances = ref
                                .read(balancesForGroupProvider(group.groupId));
                            final hasOutstandingBalances = balances.values
                                .any((balance) => balance.abs() > 0.01);

                            if (!hasOutstandingBalances) {
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                              if (context.mounted) {
                                AppSnackBar.showInfo(
                                  context,
                                  'Everyone in this group is already settled up!',
                                );
                              }
                              return;
                            }

                            final currentUserId =
                                Supabase.instance.client.auth.currentUser?.id;

                            // Check for existing pending request
                            final existing = await Supabase.instance.client
                                .from('requests')
                                .select('id')
                                .eq('group_id', group.groupId)
                                .eq('user_id', currentUserId ?? '')
                                .eq('status', 'pending')
                                .maybeSingle();

                            if (existing != null) {
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                              if (context.mounted) {
                                AppSnackBar.showError(context,
                                    'A reminder is already pending for this group!');
                              }
                              return;
                            }

                            await Supabase.instance.client
                                .from('requests')
                                .insert({
                              "group_id": group.groupId,
                              "user_id": currentUserId,
                            });
                            AnalyticsService.logRemindToSettleSent(reminderType: 'group');

                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                            if (context.mounted) {
                              AppSnackBar.showSuccess(
                                  context, 'Settle up reminder sent to group!');
                            }

                            // Wait a moment so the user can read the snackbar
                            await Future.delayed(
                                const Duration(milliseconds: 1500));
                          } catch (e) {
                            debugPrint(
                                'Failed to send request notification: $e');
                            if (context.mounted) {
                              AppSnackBar.showError(context,
                                  ErrorHandler.getUserFriendlyMessage(e));
                            }
                          }

                          if (context.mounted) {
                            context.push(AppRouter.settleUp,
                                extra: group.groupId);
                          }
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
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

class _ReceiptProcessingDialog extends StatefulWidget {
  const _ReceiptProcessingDialog();

  @override
  State<_ReceiptProcessingDialog> createState() =>
      _ReceiptProcessingDialogState();
}

class _ReceiptProcessingDialogState extends State<_ReceiptProcessingDialog> {
  int _currentStep = 0;
  final List<String> _steps = [
    'Scanning receipt...',
    'Reading text with ML Kit...',
    'Extracting amount...',
    'Receipt scanned successfully!'
  ];

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() {
          _currentStep = i;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60.w,
                  height: 60.w,
                  child: CircularProgressIndicator(
                    value: (_currentStep + 1) / _steps.length,
                    strokeWidth: 3,
                    color: AppColors.onboardingViolet,
                    backgroundColor: AppColors.white.withValues(alpha: 0.1),
                  ),
                ),
                Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.onboardingViolet,
                  size: 28.sp,
                ),
              ],
            ),
            SizedBox(height: 24.h),
            const AppText(
              'Scanning Receipt',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
            SizedBox(height: 8.h),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: AppText(
                _steps[_currentStep],
                key: ValueKey<int>(_currentStep),
                fontSize: 13,
                color: _currentStep == _steps.length - 1
                    ? AppColors.success
                    : AppColors.white.withValues(alpha: 0.6),
                align: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
