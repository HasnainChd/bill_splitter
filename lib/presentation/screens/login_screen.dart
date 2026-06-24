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

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.watch(authProvider.notifier);
    final controllers = ref.watch(formControllersProvider);
    final obscure = ref.watch(loginObscureProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Decorative background circle (top-right)
          Positioned(
            top: 15,
            right: 3,
            child: Container(
              width: 250.w,
              height: 250.w,
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
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        SizedBox(height: 8.h),

                        // ── Heading ──────────────────────────────────────────
                        const AppText(
                          'Welcome back',
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                          height: 1.15,
                        ),
                        SizedBox(height: 6.h),
                        const AppText(
                          'Sign in to your Equaly account',
                          fontSize: 15,
                          color: AppColors.textGrey,
                        ),
                        SizedBox(height: 32.h),

                        // ── Social Auth Buttons ───────────────────────────────
                        if (Theme.of(context).platform == TargetPlatform.iOS) ...[
                          _SocialButton(
                            emoji: '🍎',
                            label: 'Continue with Apple',
                            onTap: () => authNotifier.signInWithApple(context),
                          ),
                          SizedBox(height: 12.h),
                        ],
                        _SocialButton(
                          emoji: '🌐',
                          label: 'Continue with Google',
                          onTap: () => authNotifier.signInWithGoogle(context),
                        ),
                        SizedBox(height: 24.h),

                        // ── Divider ───────────────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: AppColors.white.withValues(alpha: 0.1),
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                              child: AppText(
                                'or',
                                fontSize: 13,
                                color:
                                    AppColors.textGrey.withValues(alpha: 0.5),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: AppColors.white.withValues(alpha: 0.1),
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24.h),

                        // ── Email Field ───────────────────────────────────────
                        AppTextField(
                          label: 'Email',
                          hint: 'your@email.com',
                          controller: controllers.email,
                          keyboardType: TextInputType.emailAddress,
                          prefix: Icon(
                            Icons.mail_outline_rounded,
                            color: AppColors.textGrey.withValues(alpha: 0.5),
                            size: 18,
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // ── Password Field with Forgot Password ───────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const AppText(
                              'PASSWORD',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textGrey,
                              letterSpacing: 1.0,
                            ),
                            GestureDetector(
                              onTap: () =>
                                  context.push(AppRouter.forgotPassword),
                              child: const AppText(
                                'Forgot password?',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onboardingViolet,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        _PasswordField(
                          controller: controllers.password,
                          obscure: obscure,
                          onToggle: () => ref
                              .read(loginObscureProvider.notifier)
                              .state = !obscure,
                        ),
                        SizedBox(height: 28.h),

                        // ── Sign In Button ────────────────────────────────────
                        AppButton(
                          label: 'Sign In',
                          height: 48.h,
                          onTap: () {
                            authNotifier.handleAuth(
                              controllers.email.text,
                              controllers.password.text,
                              context,
                            );
                          },
                          isLoading: authState.isLoading,
                          color: AppColors.onboardingViolet,
                          textColor: AppColors.white,
                        ),
                        SizedBox(height: 24.h),

                        // ── Footer ────────────────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppText(
                              "Don't have an account? ",
                              fontSize: 14,
                              color: AppColors.textGrey,
                            ),
                            GestureDetector(
                              onTap: () => context.push(AppRouter.register),
                              child: const AppText(
                                'Create one',
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

// ─── Sub-widgets ────────────────────────────────────────────────────────────

class _BackButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.canPop() ? context.pop() : null,
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

class _SocialButton extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.cardDarkSecondary.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: TextStyle(fontSize: 18.sp)),
            SizedBox(width: 10.w),
            AppText(
              label,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      hint: '••••••••',
      controller: controller,
      obscureText: obscure,
      prefix: Icon(
        Icons.lock_outline_rounded,
        color: AppColors.textGrey.withValues(alpha: 0.5),
        size: 18,
      ),
      suffix: GestureDetector(
        onTap: onToggle,
        child: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.textGrey.withValues(alpha: 0.5),
          size: 18,
        ),
      ),
    );
  }
}
