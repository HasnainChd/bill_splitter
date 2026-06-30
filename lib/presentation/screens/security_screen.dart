import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_card.dart';
import '../../providers/settings_provider.dart';

class SessionDevice {
  final String id;
  final String device;
  final String location;
  final IconData icon;

  SessionDevice({
    required this.id,
    required this.device,
    required this.location,
    required this.icon,
  });
}

final securityActiveSessionsProvider =
    StateProvider.autoDispose<List<SessionDevice>>((ref) => [
          SessionDevice(
            id: 'macbook',
            device: 'MacBook Pro',
            location: 'New York, US · 2h ago',
            icon: Icons.laptop_chromebook_rounded,
          ),
          SessionDevice(
            id: 'ipad',
            device: 'iPad Air',
            location: 'Boston, US · 3 days ago',
            icon: Icons.tablet_mac_rounded,
          ),
        ]);

class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final faceIdEnabled = ref.watch(faceIdEnabledProvider);
    final requireOnLaunch = ref.watch(requireOnLaunchProvider);
    final autoLock = ref.watch(autoLockProvider);
    final activeSessions = ref.watch(securityActiveSessionsProvider);

    // Calculate dynamic security score
    int score = 65;
    if (faceIdEnabled) score += 10;
    if (requireOnLaunch) score += 10;

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Column(
          children: [
            SizedBox(height: 30.h),
            // ── Header ──
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppText(
                          'Security',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Container(
                              width: 6.w,
                              height: 6.w,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            const AppText(
                              'Account is secure',
                              fontSize: 12,
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // ── Scrollable Content ──
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Security Score Card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.04),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  'Security Score',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white.withValues(alpha: 0.4),
                                ),
                                SizedBox(height: 6.h),
                                AppText(
                                  '$score/100',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF10B981),
                                ),
                                SizedBox(height: 12.h),
                                AppText(
                                  score < 100
                                      ? 'Enable 2FA to reach 100'
                                      : 'Your account is fully optimized',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white.withValues(alpha: 0.6),
                                ),
                                SizedBox(height: 12.h),
                                // Linear Progress bar
                                Container(
                                  width: double.infinity,
                                  height: 6.h,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1C38),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: score / 100,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        borderRadius:
                                            BorderRadius.circular(10.r),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 20.w),
                          // Circle shield check
                          Container(
                            width: 58.w,
                            height: 58.w,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.shield_rounded,
                              color: const Color(0xFF10B981),
                              size: 26.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // AUTHENTICATION Section
                    _sectionLabel('AUTHENTICATION'),
                    SizedBox(height: 12.h),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildSwitchRow(
                            icon: Icons.fingerprint_rounded,
                            iconColor: AppColors.onboardingViolet,
                            title: 'Face ID / Touch ID',
                            subtitle: 'Unlock app with biometrics',
                            value: faceIdEnabled,
                            onChanged: (val) {
                              ref
                                  .read(faceIdEnabledProvider.notifier)
                                  .setFaceId(val);
                            },
                          ),
                          _buildDivider(),
                          _buildSwitchRow(
                            icon: Icons.phonelink_lock_rounded,
                            iconColor: AppColors.onboardingCyan,
                            title: 'Require on Launch',
                            subtitle: 'Always authenticate on open',
                            value: requireOnLaunch,
                            onChanged: (val) {
                              ref
                                  .read(requireOnLaunchProvider.notifier)
                                  .setRequireOnLaunch(val);
                            },
                          ),
                          _buildDivider(),
                          _buildActionRow(
                            icon: Icons.hourglass_empty_rounded,
                            iconColor: AppColors.orange,
                            title: 'Auto-Lock',
                            subtitle: 'After 5 minutes of inactivity',
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppText(
                                  autoLock,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white.withValues(alpha: 0.4),
                                ),
                                SizedBox(width: 6.w),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.white.withValues(alpha: 0.2),
                                  size: 20.sp,
                                ),
                              ],
                            ),
                            onTap: () {
                              _showAutoLockPicker(context, ref, autoLock);
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // TWO-FACTOR AUTHENTICATION Section
                    _sectionLabel('TWO-FACTOR AUTHENTICATION'),
                    SizedBox(height: 12.h),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildBadgeRow(
                            icon: Icons.chat_bubble_outline_rounded,
                            iconColor: AppColors.onboardingCyan,
                            title: 'SMS Code',
                            subtitle: '+1 (555) 234-5678',
                            badgeText: 'ACTIVE',
                            badgeColor: const Color(0xFF10B981),
                          ),
                          _buildDivider(),
                          _buildBadgeRow(
                            icon: Icons.phonelink_setup_rounded,
                            iconColor: AppColors.onboardingViolet,
                            title: 'Authenticator App',
                            subtitle: 'Google / Authy TOTP',
                            badgeText: 'SET UP',
                            badgeColor: AppColors.onboardingViolet,
                          ),
                          _buildDivider(),
                          _buildBadgeRow(
                            icon: Icons.key_rounded,
                            iconColor: AppColors.orange,
                            title: 'Backup Codes',
                            subtitle: '8 codes remaining',
                            badgeText: 'VIEW',
                            badgeColor: Colors.amber,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // PASSWORD Section
                    _sectionLabel('PASSWORD'),
                    SizedBox(height: 12.h),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildActionRow(
                            icon: Icons.vpn_key_outlined,
                            iconColor: AppColors.orange,
                            title: 'Change Password',
                            subtitle: 'Last changed 30 days ago',
                            trailing: Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.white.withValues(alpha: 0.2),
                              size: 20.sp,
                            ),
                            onTap: () {},
                          ),
                          _buildDivider(),
                          _buildActionRow(
                            icon: Icons.link_rounded,
                            iconColor: AppColors.onboardingCyan,
                            title: 'Linked Accounts',
                            subtitle: 'Google · Apple',
                            trailing: Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.white.withValues(alpha: 0.2),
                              size: 20.sp,
                            ),
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // ACTIVE SESSIONS Section
                    _sectionLabel('ACTIVE SESSIONS'),
                    SizedBox(height: 12.h),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          // This Device
                          ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 6.h),
                            leading: Container(
                              width: 36.w,
                              height: 36.w,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1C38),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              alignment: Alignment.center,
                              child: Icon(Icons.phone_iphone_rounded,
                                  color: AppColors.onboardingCyan, size: 18.sp),
                            ),
                            title: const AppText(
                              'iPhone 15 Pro',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                            subtitle: AppText(
                              'New York, US · Now',
                              fontSize: 11,
                              color: AppColors.white.withValues(alpha: 0.35),
                            ),
                            trailing: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: const AppText(
                                'THIS DEVICE',
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                          if (activeSessions.isNotEmpty) ...[
                            _buildDivider(),
                            ...List.generate(activeSessions.length, (idx) {
                              final session = activeSessions[idx];
                              return Column(
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 14.w, vertical: 6.h),
                                    leading: Container(
                                      width: 36.w,
                                      height: 36.w,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E1C38),
                                        borderRadius:
                                            BorderRadius.circular(10.r),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(session.icon,
                                          color: AppColors.white
                                              .withValues(alpha: 0.4),
                                          size: 18.sp),
                                    ),
                                    title: AppText(
                                      session.device,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                    subtitle: AppText(
                                      session.location,
                                      fontSize: 11,
                                      color: AppColors.white
                                          .withValues(alpha: 0.35),
                                    ),
                                    trailing: TextButton(
                                      onPressed: () {
                                        ref
                                                .read(
                                                    securityActiveSessionsProvider
                                                        .notifier)
                                                .state =
                                            activeSessions
                                                .where(
                                                    (s) => s.id != session.id)
                                                .toList();
                                      },
                                      child: const AppText(
                                        'Revoke',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.coralRed,
                                      ),
                                    ),
                                  ),
                                  if (idx < activeSessions.length - 1)
                                    _buildDivider(),
                                ],
                              );
                            }),
                          ],
                        ],
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

  Widget _buildSwitchRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
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

  Widget _buildBadgeRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
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
      subtitle: AppText(
        subtitle,
        fontSize: 11,
        color: AppColors.white.withValues(alpha: 0.35),
      ),
      trailing: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: AppText(
          badgeText,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
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
      subtitle: AppText(
        subtitle,
        fontSize: 11,
        color: AppColors.white.withValues(alpha: 0.35),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withValues(alpha: 0.04),
      height: 1,
      thickness: 1,
      indent: 64.w,
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

  void _showAutoLockPicker(
      BuildContext context, WidgetRef ref, String currentValue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 16.h),
              const AppText(
                'Auto-Lock Duration',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
              SizedBox(height: 16.h),
              ...[
                'Immediately',
                'After 1 minute',
                'After 5 minutes',
                'After 15 minutes',
                'Never'
              ].map((option) {
                final isSelected = currentValue == option;
                return ListTile(
                  title: AppText(
                    option,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? AppColors.onboardingViolet
                        : AppColors.white,
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_rounded,
                          color: AppColors.onboardingViolet, size: 20.sp)
                      : null,
                  onTap: () {
                    ref.read(autoLockProvider.notifier).setAutoLock(option);
                    Navigator.pop(context);
                  },
                );
              }),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }
}
