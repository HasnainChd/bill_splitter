import 'package:bill_splitter/presentation/providers/tab_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/router/app_router.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../core/utils/financial_calculator.dart';
import 'package:share_plus/share_plus.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final profile = profileState.profile;
    final defaultCurrency = ref.watch(defaultCurrencyProvider);
    final groupState = ref.watch(groupProvider);
    final expenseState = ref.watch(expenseProvider);

    int totalGroups = groupState.groups.length;
    int totalExpenses = expenseState.expenses.length;
    double totalSettled = FinancialCalculator.calculateTotalSettled(expenseState.expenses);

    if (profile == null) {
      if (profileState.error != null) {
        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.coralRed,
                  size: 48.sp,
                ),
                SizedBox(height: 16.h),
                const AppText(
                  'Error loading profile',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
                SizedBox(height: 8.h),
                AppText(
                  profileState.error!,
                  fontSize: 13,
                  color: AppColors.white.withValues(alpha: 0.5),
                  align: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(profileProvider.notifier).fetchProfile(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.onboardingViolet,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }

      return const Center(
        child: CircularProgressIndicator(color: AppColors.onboardingViolet),
      );
    }

    final names = profile.fullName.split(' ');
    final firstName = names.isNotEmpty ? names.first : '';
    final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';
    final initials = _getInitials(profile.fullName);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          // ── Header Row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                'Profile',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
              // Settings Icon Button (Rounded Card Container, No Border)
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryMid,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.settings_outlined,
                    color: AppColors.white,
                    size: 20.sp,
                  ),
                  onPressed: () => context.push(AppRouter.settings),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // ── Profile Details ──
          Center(
            child: Column(
              children: [
                // Avatar with green status dot
                Stack(
                  children: [
                    Container(
                      width: 96.w,
                      height: 96.w,
                      decoration: BoxDecoration(
                        color: AppColors.onboardingViolet,
                        borderRadius: BorderRadius.circular(24.r),
                        image: profile.avatarUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(profile.avatarUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: profile.avatarUrl.isEmpty
                          ? AppText(
                              initials,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 4.h,
                      right: 4.w,
                      child: Container(
                        width: 18.w,
                        height: 18.w,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.backgroundDark,
                            width: 3.w,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Name: profile.fullName
                if (firstName.isNotEmpty && lastName.isNotEmpty)
                  AppText(
                    '$firstName $lastName',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),

                SizedBox(height: 6.h),
                AppText(
                  '@${profile.username.isNotEmpty ? profile.username : "username"}',
                  fontSize: 13,
                  color: AppColors.white.withValues(alpha: 0.4),
                ),
                SizedBox(height: 16.h),

                // Edit Profile Button
                GestureDetector(
                  onTap: () => context.push(AppRouter.editProfile),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: AppColors.transparent,
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(
                        color:
                            AppColors.onboardingViolet.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const AppText(
                      'Edit Profile',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onboardingViolet,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 28.h),

          // ── Stats Row ──
          Row(
            children: [
              _buildStatCard(
                icon: Icons.people_outline_rounded,
                iconColor: AppColors.white.withValues(alpha: 0.5),
                value: '$totalGroups',
                label: 'Groups',
              ),
              SizedBox(width: 12.w),
              _buildStatCard(
                icon: Icons.description_outlined,
                iconColor: AppColors.white.withValues(alpha: 0.5),
                value: '$totalExpenses',
                label: 'Expenses',
              ),
              SizedBox(width: 12.w),
              _buildStatCard(
                icon: Icons.check_box_outlined,
                iconColor: const Color(0xFF10B981),
                value: '$defaultCurrency${totalSettled >= 1000 ? '${(totalSettled / 1000).toStringAsFixed(1)}k' : totalSettled.toStringAsFixed(0)}',
                label: 'Settled',
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // ── Achievements ──
          _sectionLabel('ACHIEVEMENTS'),
          SizedBox(height: 12.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildAchievementBadge(
                  icon: Icons.bolt_rounded,
                  label: 'Early Adopter',
                  color: AppColors.onboardingViolet,
                ),
                if (totalSettled >= 100) ...[
                  SizedBox(width: 8.w),
                  _buildAchievementBadge(
                    icon: Icons.emoji_events_rounded,
                    label: 'Top Settler',
                    color: AppColors.success,
                  ),
                ],
                if (totalGroups >= 3) ...[
                  SizedBox(width: 8.w),
                  _buildAchievementBadge(
                    icon: Icons.workspace_premium_rounded,
                    label: 'Group Creator',
                    color: AppColors.catGeneral,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // ── Active Groups ──
          _sectionLabel('ACTIVE GROUPS'),
          SizedBox(height: 12.h),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: () {
                final sortedGroups = List.from(groupState.groups)
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                final topGroups = sortedGroups.take(3).toList();
                
                if (topGroups.isEmpty) {
                  return [
                    Padding(
                      padding: EdgeInsets.all(24.w),
                      child: Center(
                        child: AppText(
                          'No active groups yet',
                          color: AppColors.white.withValues(alpha: 0.4),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ];
                }

                // Prepare grouped expenses
                final Map<String, List> groupExpensesMap = {};
                for (final e in expenseState.expenses) {
                  groupExpensesMap.putIfAbsent(e.groupId, () => []).add(e);
                }

                List<Widget> groupWidgets = [];
                for (int i = 0; i < topGroups.length; i++) {
                  final g = topGroups[i];
                  final groupExps = groupExpensesMap[g.groupId] ?? [];
                  final balances = FinancialCalculator.calculateGroupBalances(List.from(groupExps));
                  final myBalance = balances[profile.id] ?? 0.0;
                  
                  String amountStr;
                  Color amountColor;
                  if (myBalance < -0.01) {
                      amountStr = '-$defaultCurrency ${myBalance.abs().toStringAsFixed(0)}';
                      amountColor = AppColors.avatarRose;
                  } else if (myBalance > 0.01) {
                      amountStr = '+$defaultCurrency ${myBalance.toStringAsFixed(0)}';
                      amountColor = AppColors.success;
                  } else {
                      amountStr = 'Settled';
                      amountColor = AppColors.white.withValues(alpha: 0.5);
                  }
                  
                  groupWidgets.add(
                    _buildActiveGroupItem(
                      iconCodePoint: g.iconCodePoint,
                      name: g.name,
                      amount: amountStr,
                      amountColor: amountColor,
                    ),
                  );
                  if (i < topGroups.length - 1) {
                    groupWidgets.add(_buildDivider());
                  }
                }
                return groupWidgets;
              }(),
            ),
          ),
          SizedBox(height: 24.h),

          // ── Menu items Card ──
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildMenuRowItem(
                  emoji: '💳',
                  title: 'Payment Methods',
                  onTap: () => context.push(AppRouter.paymentMethods),
                ),
                _buildDivider(),
                _buildMenuRowItem(
                  emoji: '🔒',
                  title: 'Privacy Settings',
                  onTap: () => context.push(AppRouter.privacySettings),
                ),
                _buildDivider(),
                _buildMenuRowItem(
                  emoji: '👋',
                  title: 'Invite Friends',
                  onTap: () async {
                    // ignore: deprecated_member_use
                    await Share.share('Join me on Equaly to easily split bills! Download here: https://equaly.app');
                  },
                ),
                _buildDivider(),
                _buildMenuRowItem(
                  emoji: '⬅️',
                  title: 'Sign Out',
                  textColor: AppColors.coralRed,
                  onTap: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.onboardingViolet,
                        ),
                      ),
                    );
                    try {
                      await Supabase.instance.client.auth.signOut();
                      ref.read(homeTabIndexProvider.notifier).state = 0;
                      // No need to manually pop or route; GoRouter redirect handles it via auth state listener
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 48.h),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: AppCard(
        padding: EdgeInsets.all(12.w),
        child: Column(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 20.sp,
            ),
            SizedBox(height: 8.h),
            SizedBox(
              height: 22.h,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AppText(
                    value,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                    maxLines: 1,
                  ),
                ),
              ),
            ),
            SizedBox(height: 4.h),
            AppText(
              label,
              fontSize: 12,
              color: AppColors.white.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14.sp),
          SizedBox(width: 6.w),
          AppText(
            label,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveGroupItem({
    required int? iconCodePoint,
    required String name,
    required String amount,
    required Color amountColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.primaryMid,
              borderRadius: BorderRadius.circular(12.r),
            ),
            alignment: Alignment.center,
            child: Icon(
              iconCodePoint != null ? IconData(iconCodePoint, fontFamily: 'MaterialIcons') : Icons.group_rounded,
              color: AppColors.white,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: AppText(
              name,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          AppText(
            amount,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: amountColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuRowItem({
    required String emoji,
    required String title,
    Color? textColor,
    Widget? trailingBadge,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: AppText(
        emoji,
        fontSize: 18,
      ),
      title: AppText(
        title,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: textColor ?? AppColors.white,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingBadge != null) ...[
            trailingBadge,
            SizedBox(width: 8.w),
          ],
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.white.withValues(alpha: 0.2),
            size: 20.sp,
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withValues(alpha: 0.04),
      height: 1,
      thickness: 1,
    );
  }

  Widget _sectionLabel(String text) {
    return AppText(
      text,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      color: AppColors.white.withValues(alpha: 0.4),
      letterSpacing: 1.2,
    );
  }
}
