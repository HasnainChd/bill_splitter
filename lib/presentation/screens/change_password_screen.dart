import 'dart:ui';
import 'package:bill_splitter/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/utils/app_snackbar.dart';
import '../../providers/register_provider.dart';

final changePasswordCurrentObscureProvider =
    StateProvider.autoDispose<bool>((ref) => true);
final changePasswordNewObscureProvider =
    StateProvider.autoDispose<bool>((ref) => true);
final changePasswordConfirmObscureProvider =
    StateProvider.autoDispose<bool>((ref) => true);
final changePasswordLoadingProvider =
    StateProvider.autoDispose<bool>((ref) => false);

final currentPasswordControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final newPasswordControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final confirmPasswordControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

class ChangePasswordScreen extends ConsumerWidget {
  final bool isRecovery;

  const ChangePasswordScreen({
    super.key,
    this.isRecovery = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPasswordController =
        ref.watch(currentPasswordControllerProvider);
    final newPasswordController = ref.watch(newPasswordControllerProvider);
    final confirmPasswordController =
        ref.watch(confirmPasswordControllerProvider);

    final obscureCurrent = ref.watch(changePasswordCurrentObscureProvider);
    final obscureNew = ref.watch(changePasswordNewObscureProvider);
    final obscureConfirm = ref.watch(changePasswordConfirmObscureProvider);
    final isLoading = ref.watch(changePasswordLoadingProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // ── Background Glow Blobs ──────────────────────────────────────────
          // Top-right purple glow
          Positioned(
            top: -50.h,
            right: -50.w,
            child: Container(
              width: 320.w,
              height: 320.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.onboardingViolet.withValues(alpha: 0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          // Center-left blue glow
          Positioned(
            bottom: 150.h,
            left: -80.w,
            child: Container(
              width: 300.w,
              height: 300.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.onboardingCyan.withValues(alpha: 0.1),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Header Bar ───────────────────────────────────────────
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  child: Row(
                    children: [
                      _BackButton(),
                      SizedBox(width: 16.w),
                      AppText(
                        isRecovery ? 'Reset Password' : 'Change Password',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 20.h),

                        // ── Security Key Icon ──
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Pulse ring 1
                              Container(
                                width: 100.w,
                                height: 100.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.onboardingViolet
                                      .withValues(alpha: 0.05),
                                ),
                              ),
                              // Pulse ring 2
                              Container(
                                width: 80.w,
                                height: 80.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.onboardingViolet
                                      .withValues(alpha: 0.1),
                                ),
                              ),
                              // Inner gradient circle
                              Container(
                                width: 62.w,
                                height: 62.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.onboardingViolet,
                                      AppColors.onboardingVioletDark,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.onboardingViolet
                                          .withValues(alpha: 0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.vpn_key_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 32.h),

                        // ── Text Headers ──
                        AppText(
                          isRecovery
                              ? 'Create New Password'
                              : 'Secure Your Account',
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          align: TextAlign.center,
                        ),
                        SizedBox(height: 10.h),
                        AppText(
                          isRecovery
                              ? 'Please enter your new password below. Ensure it is strong and easy to remember.'
                              : 'Update your password regularly to keep your wallet and splits secure.',
                          fontSize: 14,
                          color: AppColors.textGrey,
                          align: TextAlign.center,
                        ),
                        SizedBox(height: 32.h),

                        // ── Glassmorphic Form Container ──
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.w, vertical: 24.h),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF16161B).withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(24.r),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Current Password (only show if not recovery mode)
                              if (!isRecovery) ...[
                                AppTextField(
                                  label: 'Current Password',
                                  hint: '••••••••',
                                  controller: currentPasswordController,
                                  obscureText: obscureCurrent,
                                  prefix: Icon(
                                    Icons.lock_open_rounded,
                                    color:
                                        AppColors.white.withValues(alpha: 0.35),
                                    size: 18.sp,
                                  ),
                                  suffix: GestureDetector(
                                    onTap: () {
                                      ref
                                          .read(
                                              changePasswordCurrentObscureProvider
                                                  .notifier)
                                          .state = !obscureCurrent;
                                    },
                                    child: Icon(
                                      obscureCurrent
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.white
                                          .withValues(alpha: 0.35),
                                      size: 18.sp,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20.h),
                              ],

                              // New Password
                              AppTextField(
                                label: 'New Password',
                                hint: '••••••••',
                                controller: newPasswordController,
                                obscureText: obscureNew,
                                prefix: Icon(
                                  Icons.lock_outline_rounded,
                                  color:
                                      AppColors.white.withValues(alpha: 0.35),
                                  size: 18.sp,
                                ),
                                suffix: GestureDetector(
                                  onTap: () {
                                    ref
                                        .read(changePasswordNewObscureProvider
                                            .notifier)
                                        .state = !obscureNew;
                                  },
                                  child: Icon(
                                    obscureNew
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color:
                                        AppColors.white.withValues(alpha: 0.35),
                                    size: 18.sp,
                                  ),
                                ),
                              ),
                              SizedBox(height: 12.h),

                              // Live Password Strength Bar
                              ValueListenableBuilder<TextEditingValue>(
                                valueListenable: newPasswordController,
                                builder: (context, value, child) {
                                  return _ChangePasswordStrengthBar(
                                    password: value.text,
                                  );
                                },
                              ),
                              SizedBox(height: 24.h),

                              // Confirm New Password
                              AppTextField(
                                label: 'Confirm New Password',
                                hint: '••••••••',
                                controller: confirmPasswordController,
                                obscureText: obscureConfirm,
                                prefix: Icon(
                                  Icons.lock_reset_rounded,
                                  color:
                                      AppColors.white.withValues(alpha: 0.35),
                                  size: 18.sp,
                                ),
                                suffix: GestureDetector(
                                  onTap: () {
                                    ref
                                        .read(
                                            changePasswordConfirmObscureProvider
                                                .notifier)
                                        .state = !obscureConfirm;
                                  },
                                  child: Icon(
                                    obscureConfirm
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color:
                                        AppColors.white.withValues(alpha: 0.35),
                                    size: 18.sp,
                                  ),
                                ),
                              ),
                              SizedBox(height: 32.h),

                              // Update Button
                              AppButton(
                                label: isRecovery
                                    ? 'Set New Password'
                                    : 'Update Password',
                                color: AppColors.onboardingViolet,
                                isLoading: isLoading,
                                onTap: () async {
                                  final newPass = newPasswordController.text;
                                  final confirm =
                                      confirmPasswordController.text;

                                  if (!isRecovery) {
                                    final current =
                                        currentPasswordController.text;
                                    if (current.isEmpty) {
                                      AppSnackBar.showWarning(
                                        context,
                                        'Please enter your current password.',
                                      );
                                      return;
                                    }
                                  }

                                  if (newPass.isEmpty || confirm.isEmpty) {
                                    AppSnackBar.showWarning(
                                      context,
                                      'Please fill out all password fields.',
                                    );
                                    return;
                                  }

                                  if (newPass != confirm) {
                                    AppSnackBar.showWarning(
                                      context,
                                      'New passwords do not match.',
                                    );
                                    return;
                                  }

                                  if (newPass.length < 8) {
                                    AppSnackBar.showWarning(
                                      context,
                                      'Password must be at least 8 characters long.',
                                    );
                                    return;
                                  }

                                  ref.read(changePasswordLoadingProvider.notifier).state = true;
                                  try {
                                    await Supabase.instance.client.auth
                                        .updateUser(
                                      UserAttributes(password: newPass),
                                    );

                                    if (!context.mounted) return;
                                    AppSnackBar.showSuccess(
                                      context,
                                      'Password updated successfully!',
                                    );

                                    currentPasswordController.clear();
                                    newPasswordController.clear();
                                    confirmPasswordController.clear();

                                    if (isRecovery) {
                                      context.go(AppRouter.home);
                                    } else {
                                      context.pop();
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      AppSnackBar.showError(
                                        context,
                                        'Failed to update password: $e',
                                      );
                                    }
                                  } finally {
                                    ref.read(changePasswordLoadingProvider.notifier).state = false;
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordStrengthBar extends ConsumerWidget {
  final String password;

  const _ChangePasswordStrengthBar({
    required this.password,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strength = ref.watch(passwordStrengthProvider(password));

    String label = '';
    Color labelColor = AppColors.white.withValues(alpha: 0.25);
    int activeSegments = 0;

    if (password.isEmpty) {
      label = '';
      labelColor = AppColors.white.withValues(alpha: 0.25);
      activeSegments = 0;
    } else if (strength <= 0.25) {
      label = 'Weak';
      labelColor = const Color(0xFFEF4444); // Red
      activeSegments = 1;
    } else if (strength <= 0.5) {
      label = 'Fair';
      labelColor = const Color(0xFFF59E0B); // Orange
      activeSegments = 2;
    } else if (strength <= 0.75) {
      label = 'Medium';
      labelColor = const Color(0xFFF59E0B); // Orange/Amber
      activeSegments = 3;
    } else {
      label = 'Strong';
      labelColor = const Color(0xFF10B981); // Emerald Green
      activeSegments = 4;
    }

    final colors = [
      const Color(0xFFEF4444), // Red
      const Color(0xFFF59E0B), // Orange
      const Color(0xFF6366F1), // Indigo/Violet
      const Color(0xFF10B981), // Emerald
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(
              'Password strength',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.white.withValues(alpha: 0.35),
            ),
            AppText(
              label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: labelColor,
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: List.generate(4, (index) {
            final isActive = index < activeSegments;
            return Expanded(
              child: Container(
                height: 4.h,
                margin: EdgeInsets.only(
                  right: index == 3 ? 0 : 4.w,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? colors[index]
                      : AppColors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.canPop() ? context.pop() : context.go(AppRouter.home),
      child: Container(
        width: 42.w,
        height: 42.w,
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }
}
