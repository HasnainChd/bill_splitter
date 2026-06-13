import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/group.dart';
import '../../../core/widgets/app_text.dart';
import '../../../core/router/app_router.dart';
import '../../../providers/group_provider.dart';
import '../../providers/tab_providers.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupState = ref.watch(groupProvider);
    final groups = groupState.groups;
    final defaultGroup = groups.isNotEmpty ? groups.first : null;

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
                    const AppText(
                      'Nain',
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
                      hasBadge: true,
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
                  const AppText(
                    '\$1,077.00',
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    children: [
                      _buildBalanceSubCol(
                          'You owe', '\$41', AppColors.balanceOwed),
                      _buildBalanceDivider(),
                      _buildBalanceSubCol(
                          'Owed to you', '\$1,077', AppColors.balanceOwedTo),
                      _buildBalanceDivider(),
                      _buildBalanceSubCol(
                          'Net balance', '\$1,036', AppColors.white),
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
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              children: [
                if (groups.isNotEmpty)
                  _buildGroupCard(
                    context: context,
                    group: groups[0],
                    icon: Icons.flight_takeoff_rounded,
                    gradient: const [
                      AppColors.onboardingViolet,
                      AppColors.onboardingVioletDark
                    ],
                    expenses: '8 expenses',
                    amount: '+\$337',
                    amountColor: AppColors.balanceOwedTo,
                    avatars: ['AJ', 'SC', 'MT'],
                  ),
                if (groups.length > 1) SizedBox(width: 12.w),
                if (groups.length > 1)
                  _buildGroupCard(
                    context: context,
                    group: groups[1],
                    icon: Icons.home_filled,
                    gradient: const [
                      AppColors.groupBlue,
                      AppColors.groupBlueDark
                    ],
                    expenses: '24 expenses',
                    amount: '+\$740',
                    amountColor: AppColors.balanceOwedTo,
                    avatars: ['AJ', 'PP', 'KW'],
                  ),
                if (groups.length > 2) SizedBox(width: 12.w),
                if (groups.length > 2)
                  _buildGroupCard(
                    context: context,
                    group: groups[2],
                    icon: Icons.local_pizza_rounded,
                    gradient: const [
                      AppColors.groupOrange,
                      AppColors.groupOrangeDark
                    ],
                    expenses: '5 expenses',
                    amount: '-\$41',
                    amountColor: AppColors.balanceOwed,
                    avatars: ['AJ', 'SC', 'MT', 'PP'],
                  ),
                SizedBox(width: 12.w),
                _buildNewGroupCard(context),
              ],
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
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(vertical: 8.h),
                children: [
                  _buildActivityRow(
                    title: 'Sarah paid you back',
                    sub: 'Barcelona Trip • 2 min ago',
                    amount: '+\$168',
                    isPositive: true,
                    icon: Icons.payments_outlined,
                  ),
                  _buildActivityDivider(),
                  _buildActivityRow(
                    title: 'Marcus added Thai dinner',
                    sub: 'Friday Crew • 12 min ago',
                    amount: '\$164',
                    isPositive: false,
                    icon: Icons.restaurant_rounded,
                  ),
                  _buildActivityDivider(),
                  _buildActivityRow(
                    title: 'Electricity bill',
                    sub: 'Grove Apt • 2 hours ago',
                    amount: '\$60',
                    isPositive: false,
                    icon: Icons.bolt_rounded,
                  ),
                  _buildActivityDivider(),
                  _buildActivityRow(
                    title: 'Kai settled up',
                    sub: 'Grove Apt • Yesterday',
                    amount: '+\$800',
                    isPositive: true,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ],
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
      width: 136.w,
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
              group.name,
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
                AppText(
                  expenses,
                  fontSize: 10,
                  color: AppColors.white.withValues(alpha: 0.7),
                ),
                AppText(
                  amount,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: amountColor,
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
      width: 136.w,
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
      width: (initials.length - 1) * 12.w + 20.h,
      child: Stack(
        children: List.generate(initials.length, (index) {
          final initial = initials[index];
          Color avatarBg = AppColors.onboardingViolet;
          if (initial == 'SC') avatarBg = AppColors.groupBlue;
          if (initial == 'MT') avatarBg = AppColors.groupOrange;
          if (initial == 'PP') avatarBg = const Color(0xFF10B981);
          if (initial == 'KW') avatarBg = Colors.purple;

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
