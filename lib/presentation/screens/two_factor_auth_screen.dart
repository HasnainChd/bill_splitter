import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/utils/app_snackbar.dart';
import '../../providers/settings_provider.dart';

final tfaSetupStartedProvider = StateProvider.autoDispose<bool>((ref) => false);
final tfaCodeSentProvider = StateProvider.autoDispose<bool>((ref) => false);

final tfaCodeControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

class TwoFactorAuthScreen extends ConsumerWidget {
  const TwoFactorAuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tfaEnabled = ref.watch(twoFactorAuthEnabledProvider);
    final tfaMethod = ref.watch(twoFactorMethodProvider);
    final setupStarted = ref.watch(tfaSetupStartedProvider);
    final codeController = ref.watch(tfaCodeControllerProvider);

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
                    'Two-Factor Auth',
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
                    // Main Status Card
                    AppCard(
                      padding: EdgeInsets.all(16.w),
                      child: Row(
                        children: [
                          Container(
                            width: 44.w,
                            height: 44.w,
                            decoration: BoxDecoration(
                              color: tfaEnabled
                                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                  : AppColors.white.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.security_rounded,
                              color: tfaEnabled ? const Color(0xFF10B981) : AppColors.textGrey,
                              size: 22.sp,
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  tfaEnabled ? 'Two-Factor Auth Enabled' : 'Two-Factor Auth Disabled',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.white,
                                ),
                                SizedBox(height: 2.h),
                                AppText(
                                  tfaEnabled
                                      ? 'Your account is secured with $tfaMethod verification'
                                      : 'Add an extra layer of security to your account',
                                  fontSize: 11,
                                  color: AppColors.white.withValues(alpha: 0.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),

                    if (!tfaEnabled && !setupStarted) ...[
                      _sectionLabel('CHOOSE VERIFICATION METHOD'),
                      SizedBox(height: 8.h),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _buildMethodTile(
                              ref: ref,
                              title: 'SMS Text Message',
                              desc: 'Verify using code sent to your phone number',
                              icon: Icons.sms_outlined,
                              value: 'SMS',
                              currentValue: tfaMethod,
                            ),
                            _buildDivider(),
                            _buildMethodTile(
                              ref: ref,
                              title: 'Authenticator App',
                              desc: 'Use apps like Google Authenticator or Authy',
                              icon: Icons.phonelink_setup_rounded,
                              value: 'Authenticator App',
                              currentValue: tfaMethod,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                      AppButton(
                        label: 'Setup Two-Factor Auth',
                        color: AppColors.onboardingViolet,
                        onTap: () {
                          ref.read(tfaSetupStartedProvider.notifier).state = true;
                          ref.read(tfaCodeSentProvider.notifier).state = true;
                        },
                      ),
                    ] else if (setupStarted) ...[
                      _sectionLabel('SETUP PROCESS'),
                      SizedBox(height: 8.h),
                      AppCard(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (tfaMethod == 'SMS') ...[
                              const AppText(
                                'Verify Your Phone Number',
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                              ),
                              SizedBox(height: 6.h),
                              AppText(
                                'A 6-digit confirmation code has been sent to +1 (•••) •••-4321.',
                                fontSize: 12,
                                color: AppColors.white.withValues(alpha: 0.45),
                              ),
                            ] else ...[
                              const AppText(
                                'Link Your Authenticator App',
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                              ),
                              SizedBox(height: 12.h),
                              Center(
                                child: Container(
                                  width: 140.w,
                                  height: 140.w,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16.r),
                                    image: const DecorationImage(
                                      image: NetworkImage(
                                        'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=otpauth://totp/Divvy:alex@email.com?secret=JBSWY3DPEHPK3PXP&issuer=Divvy',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Center(
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1C38),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: const AppText(
                                    'JBSW Y3DP EHPK 3PXP',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.onboardingCyan,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              AppText(
                                'Scan the QR code or enter the code manually inside your authenticator app.',
                                fontSize: 11,
                                color: AppColors.white.withValues(alpha: 0.4),
                                align: TextAlign.center,
                              ),
                            ],
                            SizedBox(height: 20.h),
                            AppTextField(
                              label: 'Verification Code',
                              hint: '000000',
                              controller: codeController,
                              keyboardType: TextInputType.number,
                              prefix: Icon(
                                Icons.pin_rounded,
                                color: AppColors.white.withValues(alpha: 0.35),
                                size: 18.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Cancel',
                              isOutlined: true,
                              color: AppColors.white.withValues(alpha: 0.35),
                              onTap: () {
                                ref.read(tfaSetupStartedProvider.notifier).state = false;
                                ref.read(tfaCodeSentProvider.notifier).state = false;
                                codeController.clear();
                              },
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: AppButton(
                              label: 'Verify & Enable',
                              color: AppColors.onboardingViolet,
                              onTap: () {
                                if (codeController.text.length == 6) {
                                  ref.read(twoFactorAuthEnabledProvider.notifier).state = true;
                                  ref.read(tfaSetupStartedProvider.notifier).state = false;
                                  ref.read(tfaCodeSentProvider.notifier).state = false;
                                  codeController.clear();
                                  AppSnackBar.showSuccess(
                                    context,
                                    'Two-factor authentication successfully enabled!',
                                  );
                                } else {
                                  AppSnackBar.showError(
                                    context,
                                    'Please enter a valid 6-digit confirmation code.',
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Enabled configurations (Disable option, backup recovery codes)
                      _sectionLabel('BACKUP RECOVERY CODES'),
                      SizedBox(height: 8.h),
                      AppCard(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              'Save these codes in a safe place. They can be used to log in if you lose access to your verification device.',
                              fontSize: 11,
                              color: AppColors.white.withValues(alpha: 0.45),
                            ),
                            SizedBox(height: 12.h),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              childAspectRatio: 3.5,
                              mainAxisSpacing: 8.h,
                              crossAxisSpacing: 8.w,
                              children: [
                                'ABCD-1234',
                                'EFGH-5678',
                                'IJKL-9012',
                                'MNOP-3456',
                              ].map((code) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1C38),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  alignment: Alignment.center,
                                  child: AppText(
                                    code,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.white.withValues(alpha: 0.7),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                      AppButton(
                        label: 'Disable Two-Factor Auth',
                        color: const Color(0xFFEF4444),
                        onTap: () {
                          ref.read(twoFactorAuthEnabledProvider.notifier).state = false;
                          AppSnackBar.showSuccess(
                            context,
                            'Two-factor authentication disabled.',
                          );
                        },
                      ),
                    ],
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

  Widget _buildMethodTile({
    required WidgetRef ref,
    required String title,
    required String desc,
    required IconData icon,
    required String value,
    required String currentValue,
  }) {
    final isSelected = value == currentValue;
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      leading: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1C38),
          borderRadius: BorderRadius.circular(8.r),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: AppColors.onboardingViolet, size: 18.sp),
      ),
      title: AppText(
        title,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      ),
      subtitle: AppText(
        desc,
        fontSize: 11,
        color: AppColors.white.withValues(alpha: 0.35),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: AppColors.onboardingViolet, size: 20.sp)
          : Icon(Icons.circle_outlined, color: AppColors.white.withValues(alpha: 0.15), size: 20.sp),
      onTap: () {
        ref.read(twoFactorMethodProvider.notifier).state = value;
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
