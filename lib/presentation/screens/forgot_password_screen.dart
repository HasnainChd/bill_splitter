import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_button.dart';
import '../../core/router/app_router.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.watch(authProvider.notifier);
    final controllers = ref.watch(forgotPasswordControllersProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Decorative background circle (top-right)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 300.w,
              height: 300.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E1B4B).withValues(alpha: 0.45),
                    AppColors.backgroundDark,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.7, 1.0],
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top bar ──────────────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    child: Row(
                      children: [
                        _BackButton(),
                      ],
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 24.h),

                        // ── Heading ──────────────────────────────────────────
                        const AppText(
                          'Forgot password',
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.15,
                        ),
                        SizedBox(height: 8.h),
                        const AppText(
                          "Enter your email address and we'll send you a link to reset your password.",
                          fontSize: 15,
                          color: AppColors.textGrey,
                        ),
                        SizedBox(height: 36.h),

                        // ── Email Field ───────────────────────────────────────
                        AppTextField(
                          label: 'Email Address',
                          hint: 'your@email.com',
                          controller: controllers.email,
                          keyboardType: TextInputType.emailAddress,
                          prefix: Icon(
                            Icons.mail_outline_rounded,
                            color: AppColors.textGrey.withValues(alpha: 0.5),
                            size: 18,
                          ),
                        ),
                        SizedBox(height: 32.h),

                        // ── Reset Password Button ──────────────────────────────
                        AppButton(
                          label: 'Reset Password',
                          height: 48.h,
                          onTap: () {
                            authNotifier.sendPasswordReset(
                              controllers.email.text,
                              context,
                            );
                          },
                          isLoading: authState.isLoading,
                          color: AppColors.onboardingViolet,
                          textColor: Colors.white,
                        ),
                        SizedBox(height: 24.h),

                        // ── Footer ────────────────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppText(
                              "Remember your password? ",
                              fontSize: 14,
                              color: AppColors.textGrey,
                            ),
                            GestureDetector(
                              onTap: () => context.canPop() ? context.pop() : context.go(AppRouter.login),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }
}
