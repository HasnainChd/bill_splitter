import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/group.dart';
import '../../../core/widgets/app_text.dart';
import '../../../core/router/app_router.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../providers/tab_providers.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/notifications_provider.dart';
import '../../../core/utils/group_icon_helper.dart';

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
    final index = initials.codeUnits.fold<int>(0, (sum, next) => sum + next) % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupState = ref.watch(groupProvider);
    final groups = groupState.groups;
    final defaultGroup = groups.isNotEmpty ? groups.first : null;
    final defaultCurrency = ref.watch(defaultCurrencyProvider);
    final currentUserId = ref.watch(supabaseUserProvider)?.id;
    final profile = ref.watch(profileProvider).profile;
    final notifications = ref.watch(dynamicNotificationsProvider);
    final recentNotifications = notifications.take(4).toList();

    // Calculate dynamic balance totals across all groups
    double totalOwed = 0.0;
    double totalOwe = 0.0;
    for (final group in groups) {
      final balances = ref.watch(balancesForGroupProvider(group.groupId));
      final myBalance = currentUserId != null ? (balances[currentUserId] ?? 0.0) : 0.0;
      if (myBalance > 0) {
        totalOwed += myBalance;
      } else if (myBalance < 0) {
        totalOwe += myBalance.abs();
      }
    }
    final netBalance = totalOwed - totalOwe;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
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
                      'Good morning 👋',
                      fontSize: 14,
                      color: AppColors.white.withValues(alpha: 0.5),
                    ),
                    SizedBox(height: 4.h),
                    AppText(
                      profile?.fullName.split(' ').first ?? 'User',
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
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
                children: [
                  AppText(
                    "Total You're Owed",
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white.withValues(alpha: 0.8),
                  ),
                  SizedBox(height: 8.h),
                  AppText(
                    '$defaultCurrency ${totalOwed.toStringAsFixed(0)}',
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    children: [
                      _buildBalanceSubCol(
                          'You owe', '$defaultCurrency ${totalOwe.toStringAsFixed(0)}', AppColors.balanceOwed),
                      _buildBalanceDivider(),
                      _buildBalanceSubCol(
                          'Owed to you', '$defaultCurrency ${totalOwed.toStringAsFixed(0)}', AppColors.balanceOwedTo),
                      _buildBalanceDivider(),
                      _buildBalanceSubCol(
                          'Net balance',
                          netBalance > 0
                              ? '+$defaultCurrency ${netBalance.toStringAsFixed(0)}'
                              : netBalance < 0
                                  ? '-$defaultCurrency ${netBalance.abs().toStringAsFixed(0)}'
                                  : '$defaultCurrency 0',
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
          SizedBox(height: 24.h),

          // ── Quick Actions ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickAction(
                    'Add\nExpense', Icons.add, AppColors.onboardingViolet, () {
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
                    AppColors.onboardingCyan, () {}),
                _buildQuickAction('Request\nMoney', Icons.send_rounded,
                    AppColors.orange, () {}),
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
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              itemCount: groups.length + 1,
              separatorBuilder: (context, index) => SizedBox(width: 12.w),
              itemBuilder: (context, index) {
                if (index == groups.length) {
                  return _buildNewGroupCard(context);
                }

                final group = groups[index];
                final balances = ref.watch(balancesForGroupProvider(group.groupId));
                final myBalance = currentUserId != null ? (balances[currentUserId] ?? 0.0) : 0.0;
                final membersAsync = ref.watch(groupMembersProvider(group.groupId));
                final expenseState = ref.watch(expenseProvider);
                final groupExpenses = expenseState.expenses.where((e) => e.groupId == group.groupId).toList();

                final groupIcon = GroupIconHelper.getGroupIcon(group.name);

                final gradients = [
                  [AppColors.onboardingViolet, AppColors.onboardingVioletDark],
                  [AppColors.groupBlue, AppColors.groupBlueDark],
                  [AppColors.groupOrange, AppColors.groupOrangeDark],
                ];
                final gradient = gradients[index % gradients.length];

                final String balanceText;
                final Color balanceColor;
                if (myBalance > 0) {
                  balanceText = '+$defaultCurrency ${myBalance.toStringAsFixed(0)}';
                  balanceColor = AppColors.balanceOwedTo;
                } else if (myBalance < 0) {
                  balanceText = '-$defaultCurrency ${myBalance.abs().toStringAsFixed(0)}';
                  balanceColor = AppColors.balanceOwed;
                } else {
                  balanceText = 'Settled';
                  balanceColor = AppColors.white.withValues(alpha: 0.5);
                }

                final List<String> initialsList = membersAsync.when(
                  data: (members) => members.map((m) {
                    final name = m.fullName.trim();
                    if (name.isEmpty) return 'U';
                    final parts = name.split(' ');
                    if (parts.length > 1) {
                      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
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
                  expenses: '${groupExpenses.length} ${groupExpenses.length == 1 ? 'expense' : 'expenses'}',
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
              child: recentNotifications.isEmpty
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
                      separatorBuilder: (context, index) => _buildActivityDivider(),
                      itemBuilder: (context, index) {
                        final item = recentNotifications[index];
                        final isPositive = item.amount?.startsWith('+') ?? false;
                        return _buildActivityRow(
                          title: item.title,
                          sub: '${GroupIconHelper.getCleanGroupName(item.groupName)} • ${item.subtitle}',
                          amount: item.amount ?? '',
                          isPositive: isPositive,
                          icon: item.badgeIcon,
                        );
                      },
                    ),
            ),
          ),
          SizedBox(height: 32.h),
        ],
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
  Widget _buildBalanceSubCol(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            label,
            fontSize: 12,
            color: AppColors.white.withValues(alpha: 0.6),
          ),
          SizedBox(height: 4.h),
          AppText(
            value,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: valueColor,
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
}
