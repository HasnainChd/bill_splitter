import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_card.dart';
import '../../core/utils/app_snackbar.dart';
import '../../providers/settings_provider.dart';

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPublic = ref.watch(privacyProfilePublicProvider);
    final allowInvites = ref.watch(privacyAllowInvitesProvider);
    final shareAnalytics = ref.watch(privacyShareAnalyticsProvider);
    final readReceipts = ref.watch(privacyReadReceiptsProvider);

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Column(
          children: [
            SizedBox(height: 30.h),
            // Header Row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              child: Row(
                children: [
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
                    'Privacy Settings',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PROFILE VISIBILITY
                    _sectionLabel('PROFILE VISIBILITY'),
                    SizedBox(height: 8.h),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildSwitchItem(
                            title: 'Public Profile',
                            subtitle:
                                'Allow others to find you via email or @username',
                            value: isPublic,
                            onChanged: (val) {
                              ref
                                  .read(privacyProfilePublicProvider.notifier)
                                  .state = val;
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // GROUP INVITES
                    _sectionLabel('GROUP INVITES'),
                    SizedBox(height: 8.h),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildInviteOption(
                            ref: ref,
                            title: 'Everyone',
                            subtitle: 'Any user can add you to a group',
                            value: 'Everyone',
                            currentValue: allowInvites,
                          ),
                          _buildDivider(),
                          _buildInviteOption(
                            ref: ref,
                            title: 'Contacts Only',
                            subtitle:
                                'Only people in your contacts can add you',
                            value: 'Contacts Only',
                            currentValue: allowInvites,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // DATA SHARING
                    _sectionLabel('DATA SHARING'),
                    SizedBox(height: 8.h),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildSwitchItem(
                            title: 'Share Spending Analytics',
                            subtitle: 'Let group members see summary analytics',
                            value: shareAnalytics,
                            onChanged: (val) {
                              ref
                                  .read(privacyShareAnalyticsProvider.notifier)
                                  .state = val;
                            },
                          ),
                          _buildDivider(),
                          _buildSwitchItem(
                            title: 'Read Receipts',
                            subtitle:
                                'Notify users when you view settle requests',
                            value: readReceipts,
                            onChanged: (val) {
                              ref
                                  .read(privacyReadReceiptsProvider.notifier)
                                  .state = val;
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // ACCOUNT MANAGEMENT
                    _sectionLabel('ACCOUNT MANAGEMENT'),
                    SizedBox(height: 8.h),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 4.h),
                            title: const AppText(
                              'Request Personal Data',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                            subtitle: AppText(
                              'Download a copy of your transaction history',
                              fontSize: 11,
                              color: AppColors.white.withValues(alpha: 0.35),
                            ),
                            trailing: Icon(
                              Icons.download_outlined,
                              color: AppColors.white.withValues(alpha: 0.45),
                              size: 20.sp,
                            ),
                            onTap: () {
                              AppSnackBar.showSuccess(
                                context,
                                'Data export request submitted. Check your email.',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      title: AppText(
        title,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      ),
      subtitle: AppText(
        subtitle,
        fontSize: 11,
        color: AppColors.white.withValues(alpha: 0.35),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.onboardingViolet,
        activeTrackColor: AppColors.onboardingViolet.withValues(alpha: 0.3),
        inactiveThumbColor: AppColors.white.withValues(alpha: 0.6),
        inactiveTrackColor: const Color(0xFF1E1C38),
      ),
    );
  }

  Widget _buildInviteOption({
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required String value,
    required String currentValue,
  }) {
    final isSelected = value == currentValue;
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      title: AppText(
        title,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      ),
      subtitle: AppText(
        subtitle,
        fontSize: 11,
        color: AppColors.white.withValues(alpha: 0.35),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded,
              color: AppColors.onboardingViolet, size: 20.sp)
          : Icon(Icons.circle_outlined,
              color: AppColors.white.withValues(alpha: 0.2), size: 20.sp),
      onTap: () {
        ref.read(privacyAllowInvitesProvider.notifier).state = value;
      },
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
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 2.h),
      child: AppText(
        text,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: AppColors.white.withValues(alpha: 0.45),
        letterSpacing: 1.2,
      ),
    );
  }

}
