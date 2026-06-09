import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_button.dart';
import '../../core/router/app_router.dart';
import '../../providers/register_provider.dart';

class RegisterScreen extends ConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registerState = ref.watch(registerProvider);
    final registerNotifier = ref.watch(registerProvider.notifier);
    final controllers = ref.watch(registerFormControllersProvider);
    final termsAccepted = ref.watch(termsAcceptedProvider);
    final obscure = ref.watch(registerObscureProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress bar + back ───────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Row(
                children: [
                  _BackButton(),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4.r),
                      child: LinearProgressIndicator(
                        value: 1.0,
                        minHeight: 4.h,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.onboardingViolet,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  const AppText(
                    'Step 1 of 1',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textGrey,
                  ),
                ],
              ),
            ),

            // ── Scrollable body ───────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16.h),

                    // ── Heading ─────────────────────────────────────────
                    const AppText(
                      'Create account',
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.15,
                    ),
                    SizedBox(height: 6.h),
                    const AppText(
                      'Join Divvy and split smarter.',
                      fontSize: 15,
                      color: AppColors.textGrey,
                    ),
                    SizedBox(height: 28.h),

                    // ── Profile Photo ────────────────────────────────────
                    Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 56.w,
                              height: 56.w,
                              decoration: BoxDecoration(
                                color: AppColors.onboardingViolet,
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              alignment: Alignment.center,
                              child: const AppText(
                                'NH',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 20.w,
                                height: 20.w,
                                decoration: const BoxDecoration(
                                  color: AppColors.onboardingGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 14.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppText(
                              'Profile photo',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            SizedBox(height: 2.h),
                            const AppText(
                              'Optional · tap to upload',
                              fontSize: 13,
                              color: AppColors.textGrey,
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 28.h),

                    // ── Full Name ────────────────────────────────────────
                    AppTextField(
                      label: 'Full Name',
                      hint: 'Your full name',
                      controller: controllers.fullName,
                      prefix: Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.textGrey.withValues(alpha: 0.5),
                        size: 18,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // ── Username ─────────────────────────────────────────
                    AppTextField(
                      label: 'Username',
                      hint: 'your_username',
                      controller: controllers.username,
                      prefix: Icon(
                        Icons.alternate_email_rounded,
                        color: AppColors.textGrey.withValues(alpha: 0.5),
                        size: 18,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // ── Email ────────────────────────────────────────────
                    AppTextField(
                      label: 'Email',
                      hint: 'you@email.com',
                      controller: controllers.email,
                      keyboardType: TextInputType.emailAddress,
                      prefix: Icon(
                        Icons.mail_outline_rounded,
                        color: AppColors.textGrey.withValues(alpha: 0.5),
                        size: 18,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // ── Password ─────────────────────────────────────────
                    AppTextField(
                      label: 'Password',
                      hint: '••••••••',
                      controller: controllers.password,
                      obscureText: obscure,
                      onChanged: (_) {
                        // Trigger rebuild to update password strength
                        ref.read(registerObscureProvider);
                      },
                      prefix: Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.textGrey.withValues(alpha: 0.5),
                        size: 18,
                      ),
                      suffix: GestureDetector(
                        onTap: () => ref
                            .read(registerObscureProvider.notifier)
                            .state = !obscure,
                        child: Icon(
                          obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textGrey.withValues(alpha: 0.5),
                          size: 18,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),

                    // ── Password Strength Bar ────────────────────────────
                    _PasswordStrengthBar(
                      controllers: controllers,
                      ref: ref,
                    ),
                    SizedBox(height: 24.h),

                    // ── Terms Checkbox ───────────────────────────────────
                    _TermsRow(
                      accepted: termsAccepted,
                      onChanged: (val) => ref
                          .read(termsAcceptedProvider.notifier)
                          .state = val ?? false,
                    ),
                    SizedBox(height: 28.h),

                    // ── Create Account Button ─────────────────────────────
                    AppButton(
                      label: 'Create Account',
                      height: 48.h,
                      onTap: () {
                        registerNotifier.signUp(
                          fullName: controllers.fullName.text,
                          username: controllers.username.text,
                          email: controllers.email.text,
                          password: controllers.password.text,
                          termsAccepted: termsAccepted,
                          context: context,
                        );
                      },
                      isLoading: registerState.isLoading,
                      color: AppColors.onboardingViolet,
                      textColor: Colors.white,
                    ),
                    SizedBox(height: 24.h),

                    // ── Footer ────────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AppText(
                          'Already have an account? ',
                          fontSize: 14,
                          color: AppColors.textGrey,
                        ),
                        GestureDetector(
                          onTap: () => context.go(AppRouter.login),
                          child: const AppText(
                            'Sign In',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onboardingViolet,
                          ),
                        ),
                      ],
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
}

// ─── Sub-widgets ────────────────────────────────────────────────────────────

class _BackButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.canPop() ? context.pop() : context.go(AppRouter.login),
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  final RegisterFormControllers controllers;
  final WidgetRef ref;

  const _PasswordStrengthBar({
    required this.controllers,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final password = controllers.password.text;
    final strength = ref.watch(passwordStrengthProvider(password));

    Color barColor;
    String label;
    if (strength <= 0.25) {
      barColor = AppColors.coralRed;
      label = 'Weak';
    } else if (strength <= 0.5) {
      barColor = AppColors.avatarAmber;
      label = 'Fair';
    } else if (strength <= 0.75) {
      barColor = AppColors.onboardingCyan;
      label = 'Good';
    } else {
      barColor = AppColors.mintGreen;
      label = 'Strong';
    }

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: strength,
              minHeight: 4.h,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        AppText(
          label,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: barColor,
        ),
      ],
    );
  }
}

class _TermsRow extends StatelessWidget {
  final bool accepted;
  final void Function(bool?) onChanged;

  const _TermsRow({required this.accepted, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 20.w,
          height: 20.w,
          child: Checkbox(
            value: accepted,
            onChanged: onChanged,
            activeColor: AppColors.onboardingViolet,
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'I agree to the ',
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textGrey,
              ),
              children: [
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    color: AppColors.onboardingViolet,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: AppColors.onboardingViolet,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
