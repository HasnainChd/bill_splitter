import 'dart:ui';
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

                        // ── Security Lock Icon ──
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
                                  Icons.lock_reset_rounded,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 32.h),

                        // ── Text Headers ──
                        const AppText(
                          'Forgot Password?',
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          align: TextAlign.center,
                        ),
                        SizedBox(height: 10.h),
                        const AppText(
                          "No worries! Enter your email below and we'll send you a link to securely recover your account.",
                          fontSize: 14,
                          color: AppColors.textGrey,
                          align: TextAlign.center,
                        ),
                        SizedBox(height: 36.h),

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
                              AppTextField(
                                label: 'Email Address',
                                hint: 'name@example.com',
                                controller: controllers.email,
                                keyboardType: TextInputType.emailAddress,
                                prefix: Icon(
                                  Icons.mail_outline_rounded,
                                  color:
                                      AppColors.white.withValues(alpha: 0.35),
                                  size: 18.sp,
                                ),
                              ),
                              SizedBox(height: 24.h),
                              AppButton(
                                label: 'Send Reset Link',
                                height: 50.h,
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
                            ],
                          ),
                        ),
                        SizedBox(height: 36.h),

                        // ── Sign In Navigation ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const AppText(
                              "Remember your password? ",
                              fontSize: 14,
                              color: AppColors.textGrey,
                            ),
                            GestureDetector(
                              onTap: () => context.canPop()
                                  ? context.pop()
                                  : context.go(AppRouter.login),
                              child: const AppText(
                                'Sign In',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onboardingViolet,
                              ),
                            ),
                          ],
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

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.canPop() ? context.pop() : context.go(AppRouter.login),
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
