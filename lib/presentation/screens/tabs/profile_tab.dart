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

    if (profile == null) {
      if (profileState.error != null) {
        return SizedBox(
          height: 400.h,
          child: Center(
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
          ),
        );
      }

      return SizedBox(
        height: 400.h,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.onboardingViolet),
        ),
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
                  color: const Color(0xFF1E1C38),
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
                value: '3',
                label: 'Groups',
              ),
              SizedBox(width: 12.w),
              _buildStatCard(
                icon: Icons.description_outlined,
                iconColor: AppColors.white.withValues(alpha: 0.5),
                value: '47',
                label: 'Expenses',
              ),
              SizedBox(width: 12.w),
              _buildStatCard(
                icon: Icons.check_box_outlined,
                iconColor: const Color(0xFF10B981),
                value: '\$3.2k',
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
                SizedBox(width: 8.w),
                _buildAchievementBadge(
                  icon: Icons.emoji_events_rounded,
                  label: 'Top Settler',
                  color: const Color(0xFF10B981),
                ),
                SizedBox(width: 8.w),
                _buildAchievementBadge(
                  icon: Icons.workspace_premium_rounded,
                  label: 'Group Creator',
                  color: const Color(0xFFF59E0B),
                ),
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
              children: [
                _buildActiveGroupItem(
                  emoji: '✈️',
                  name: 'Barcelona Trip',
                  amount: '+\$337',
                  amountColor: const Color(0xFF00C896),
                ),
                _buildDivider(),
                _buildActiveGroupItem(
                  emoji: '🏠',
                  name: 'Grove Apt',
                  amount: '+\$740',
                  amountColor: const Color(0xFF00C896),
                ),
                _buildDivider(),
                _buildActiveGroupItem(
                  emoji: '🍕',
                  name: 'Dinner Crew',
                  amount: '-\$41',
                  amountColor: AppColors.coralRed,
                ),
              ],
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
                  trailingBadge: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: const AppText(
                      'Get \$5',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  onTap: () {},
                ),
                _buildDivider(),
                _buildMenuRowItem(
                  emoji: '⬅️',
                  title: 'Sign Out',
                  textColor: AppColors.coralRed,
                  onTap: () async {
                    final router = GoRouter.of(context);
                    await Supabase.instance.client.auth.signOut();
                    ref.read(homeTabIndexProvider.notifier).state = 0;
                    router.go(AppRouter.login);
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

  // Helper: Stat Card
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
            AppText(
              value,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
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
    required String emoji,
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
              color: const Color(0xFF1E1C38),
              borderRadius: BorderRadius.circular(12.r),
            ),
            alignment: Alignment.center,
            child: AppText(
              emoji,
              fontSize: 16,
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
