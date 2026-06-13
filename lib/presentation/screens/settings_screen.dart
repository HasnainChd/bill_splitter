import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_card.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/app_snackbar.dart';
import '../../providers/settings_provider.dart';
import '../providers/tab_providers.dart';

final ratingStarsProvider = StateProvider.autoDispose<int>((ref) => 0);

final settingsFaceIdProvider = StateProvider.autoDispose<bool>((ref) => true);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final faceIdEnabled = ref.watch(settingsFaceIdProvider);
    final activeCurrency = ref.watch(defaultCurrencyProvider);
    final activeLanguage = ref.watch(languageProvider);
    final activeDateFormat = ref.watch(dateFormatProvider);
    final tfaEnabled = ref.watch(twoFactorAuthEnabledProvider);
    final tfaMethod = ref.watch(twoFactorMethodProvider);

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Column(
          children: [
            SizedBox(height: 30.h),
            // ── Custom Header ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              child: Row(
                children: [
                  // Back Button (No border card)
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
                        Icons.chevron_left_rounded,
                        color: AppColors.white,
                        size: 24.sp,
                      ),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  const AppText(
                    'Settings',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // ── Scrollable Settings List ──
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Card
                    AppCard(
                      padding: EdgeInsets.all(16.w),
                      child: Row(
                        children: [
                          Container(
                            width: 48.w,
                            height: 48.w,
                            decoration: BoxDecoration(
                              color: AppColors.onboardingViolet,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            alignment: Alignment.center,
                            child: const AppText(
                              'AJ',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AppText(
                                  'Alex Johnson',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                                SizedBox(height: 4.h),
                                AppText(
                                  'alex@email.com',
                                  fontSize: 12,
                                  color: AppColors.white.withValues(alpha: 0.4),
                                ),
                              ],
                            ),
                          ),
                          // Gold "PRO" Badge
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: AppColors.orange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: AppColors.orange.withValues(alpha: 0.4),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt_rounded, color: AppColors.orange, size: 12.sp),
                                SizedBox(width: 2.w),
                                const AppText(
                                  'PRO',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.orange,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // ACCOUNT Section
                    _sectionLabel('ACCOUNT'),
                    SizedBox(height: 12.h),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildSettingsRowItem(
                            icon: Icons.person_outline_rounded,
                            iconColor: AppColors.onboardingViolet,
                            title: 'Edit Profile',
                            subtitle: 'Alex Johnson · @alexj',
                            onTap: () => context.push(AppRouter.editProfile),
                          ),
                          _buildDivider(),
                          _buildSettingsRowItem(
                            icon: Icons.credit_card_rounded,
                            iconColor: AppColors.onboardingCyan,
                            title: 'Payment Methods',
                            subtitle: 'Venmo, Apple Pay',
                            onTap: () => context.push(AppRouter.paymentMethods),
                          ),
                          _buildDivider(),
                          _buildSettingsRowItem(
                            icon: Icons.link_rounded,
                            iconColor: const Color(0xFF10B981),
                            title: 'Connected Accounts',
                            subtitle: '2 connected',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // PREFERENCES Section
                    _sectionLabel('PREFERENCES'),
                    SizedBox(height: 12.h),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildSettingsRowItem(
                            icon: Icons.notifications_none_rounded,
                            iconColor: AppColors.orange,
                            title: 'Notifications',
                            subtitle: 'Push, email enabled',
                            onTap: () => context.push(AppRouter.notificationSettings),
                          ),
                          _buildDivider(),
                          _buildSettingsRowItem(
                            icon: Icons.currency_exchange_rounded,
                            iconColor: AppColors.onboardingViolet,
                            title: 'Default Currency',
                            subtitle: activeCurrency,
                            onTap: () => context.push(AppRouter.defaultCurrency),
                          ),
                          _buildDivider(),
                          _buildSettingsRowItem(
                            icon: Icons.language_rounded,
                            iconColor: AppColors.onboardingCyan,
                            title: 'Language',
                            subtitle: activeLanguage,
                            onTap: () => context.push(AppRouter.language),
                          ),
                          _buildDivider(),
                          _buildSettingsRowItem(
                            icon: Icons.calendar_today_rounded,
                            iconColor: const Color(0xFF10B981),
                            title: 'Date Format',
                            subtitle: activeDateFormat,
                            onTap: () => context.push(AppRouter.dateFormat),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // SECURITY Section
                    _sectionLabel('SECURITY'),
                    SizedBox(height: 12.h),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildSettingsRowItem(
                            icon: Icons.fingerprint_rounded,
                            iconColor: AppColors.onboardingViolet,
                            title: 'Face ID / Fingerprint',
                            trailing: Switch(
                              value: faceIdEnabled,
                              onChanged: (val) {
                                ref.read(settingsFaceIdProvider.notifier).state = val;
                              },
                              activeColor: AppColors.onboardingViolet,
                              activeTrackColor: AppColors.onboardingViolet.withValues(alpha: 0.3),
                              inactiveThumbColor: AppColors.white.withValues(alpha: 0.6),
                              inactiveTrackColor: const Color(0xFF1E1C38),
                            ),
                            onTap: () => context.push(AppRouter.security),
                          ),
                          _buildDivider(),
                          _buildSettingsRowItem(
                            icon: Icons.shield_outlined,
                            iconColor: const Color(0xFF10B981),
                            title: 'Two-Factor Auth',
                            subtitle: tfaEnabled ? 'Enabled via $tfaMethod' : 'Disabled',
                            onTap: () => context.push(AppRouter.twoFactorAuth),
                          ),
                          _buildDivider(),
                          _buildSettingsRowItem(
                            icon: Icons.key_rounded,
                            iconColor: AppColors.orange,
                            title: 'Change Password',
                            subtitle: 'Security updates',
                            onTap: () => context.push(AppRouter.changePassword),
                          ),
                          _buildDivider(),
                          _buildSettingsRowItem(
                            icon: Icons.privacy_tip_rounded,
                            iconColor: const Color(0xFF10B981),
                            title: 'Privacy Settings',
                            subtitle: 'Visibility, data sharing',
                            onTap: () => context.push(AppRouter.privacySettings),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // SUBSCRIPTION Section
                    _sectionLabel('SUBSCRIPTION'),
                    SizedBox(height: 12.h),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildSettingsRowItem(
                            icon: Icons.bolt_rounded,
                            iconColor: AppColors.orange,
                            title: 'Divvy Pro',
                            subtitle: 'Active · \$4.99/mo',
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.orange.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: const AppText(
                                    'PRO',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.orange,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.white.withValues(alpha: 0.2),
                                  size: 20.sp,
                                ),
                              ],
                            ),
                            onTap: () => context.push(AppRouter.divvyPro),
                          ),
                          _buildDivider(),
                          _buildSettingsRowItem(
                            icon: Icons.inventory_2_outlined,
                            iconColor: AppColors.onboardingViolet,
                            title: 'Manage Subscription',
                            subtitle: 'Billing, cancel',
                            onTap: () => context.push(AppRouter.divvyPro),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // SUPPORT Section
                    _sectionLabel('SUPPORT'),
                    SizedBox(height: 12.h),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildSettingsRowItem(
                            icon: Icons.help_outline_rounded,
                            iconColor: AppColors.coralRed,
                            title: 'Help Center',
                            onTap: () => context.push(AppRouter.helpSupport),
                          ),
                          _buildDivider(),
                          _buildSettingsRowItem(
                            icon: Icons.bug_report_outlined,
                            iconColor: const Color(0xFF10B981),
                            title: 'Report a Bug',
                            onTap: () => context.push(AppRouter.reportBug),
                          ),
                          _buildDivider(),
                          _buildSettingsRowItem(
                            icon: Icons.star_outline_rounded,
                            iconColor: AppColors.orange,
                            title: 'Rate Divvy',
                            onTap: () => _showRatingDialog(context),
                          ),
                          _buildDivider(),
                          _buildSettingsRowItem(
                            icon: Icons.info_outline_rounded,
                            iconColor: AppColors.onboardingCyan,
                            title: 'About & Legal',
                            subtitle: 'v2.4.1',
                            onTap: () => context.push(AppRouter.aboutLegal),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32.h),

                    // Sign Out Button
                    GestureDetector(
                      onTap: () async {
                        final router = GoRouter.of(context);
                        await Supabase.instance.client.auth.signOut();
                        ref.read(homeTabIndexProvider.notifier).state = 0;
                        router.go(AppRouter.login);
                      },
                      child: Container(
                        width: double.infinity,
                        height: 52.h,
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: AppColors.coralRed.withValues(alpha: 0.15),
                            width: 1.2.w,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const AppText(
                          'Sign Out',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.coralRed,
                        ),
                      ),
                    ),
                    SizedBox(height: 48.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsRowItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1C38),
          borderRadius: BorderRadius.circular(10.r),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: iconColor, size: 18.sp),
      ),
      title: AppText(
        title,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      ),
      subtitle: subtitle != null
          ? AppText(
              subtitle,
              fontSize: 11,
              color: AppColors.white.withValues(alpha: 0.35),
            )
          : null,
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.white.withValues(alpha: 0.2),
            size: 20.sp,
          ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withValues(alpha: 0.04),
      height: 1,
      thickness: 1,
      indent: 68.w, // indent to align with the start of row text (leading card is 36w + offsets)
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

  void _showRatingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final rating = ref.watch(ratingStarsProvider);
            return AlertDialog(
              backgroundColor: AppColors.cardDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              title: const Center(
                child: AppText(
                  'Rate Divvy',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppText(
                    'How is your experience splitting bills with Divvy?',
                    fontSize: 13,
                    color: AppColors.textGrey,
                    align: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      final isSelected = starIndex <= rating;
                      return GestureDetector(
                        onTap: () {
                          ref.read(ratingStarsProvider.notifier).state = starIndex;
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Icon(
                            isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: isSelected ? AppColors.orange : AppColors.white.withValues(alpha: 0.2),
                            size: 36.sp,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: AppText(
                    'Not Now',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white.withValues(alpha: 0.5),
                  ),
                ),
                TextButton(
                  onPressed: rating == 0
                      ? null
                      : () {
                          Navigator.of(ctx).pop();
                          AppSnackBar.showSuccess(
                            context,
                            'Thank you for rating us $rating stars!',
                          );
                        },
                  child: AppText(
                    'Submit',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: rating == 0
                        ? AppColors.white.withValues(alpha: 0.2)
                        : AppColors.onboardingViolet,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
