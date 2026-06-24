import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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
    final profilePhoto = ref.watch(profilePhotoProvider);

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
                        backgroundColor: AppColors.white.withValues(alpha: 0.1),
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
                      color: AppColors.white,
                      height: 1.15,
                    ),
                    SizedBox(height: 6.h),
                    const AppText(
                      'Join Equaly and split smarter.',
                      fontSize: 15,
                      color: AppColors.textGrey,
                    ),
                    SizedBox(height: 28.h),

                    // ── Profile Photo ────────────────────────────────────
                    GestureDetector(
                      onTap: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          ref.read(profilePhotoProvider.notifier).state = image.path;
                        }
                      },
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              profilePhoto != null
                                  ? Container(
                                      width: 56.w,
                                      height: 56.w,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16.r),
                                        image: DecorationImage(
                                          image: FileImage(File(profilePhoto)),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 56.w,
                                      height: 56.w,
                                      decoration: BoxDecoration(
                                        color: AppColors.onboardingViolet,
                                        borderRadius: BorderRadius.circular(16.r),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.person_rounded,
                                        color: AppColors.white,
                                        size: 28,
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
                                    color: AppColors.white,
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
                                color: AppColors.white,
                              ),
                              SizedBox(height: 2.h),
                              AppText(
                                profilePhoto != null
                                    ? 'Photo selected · tap to change'
                                    : 'Optional · tap to upload',
                                fontSize: 13,
                                color: AppColors.textGrey,
                              ),
                            ],
                          ),
                        ],
                      ),
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
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controllers.password,
                      builder: (context, value, child) {
                        return _PasswordStrengthBar(
                          password: value.text,
                        );
                      },
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
                          profilePhotoPath: profilePhoto,
                        );
                      },
                      isLoading: registerState.isLoading,
                      color: AppColors.onboardingViolet,
                      textColor: AppColors.white,
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
            color: AppColors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.white,
          size: 16,
        ),
      ),
    );
  }
}

class _PasswordStrengthBar extends ConsumerWidget {
  final String password;

  const _PasswordStrengthBar({
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
      labelColor = AppColors.error; // Red
      activeSegments = 1;
    } else if (strength <= 0.5) {
      label = 'Fair';
      labelColor = AppColors.warning; // Orange
      activeSegments = 2;
    } else if (strength <= 0.75) {
      label = 'Medium';
      labelColor = AppColors.warning; // Orange/Amber
      activeSegments = 3;
    } else {
      label = 'Strong';
      labelColor = AppColors.success; // Emerald Green
      activeSegments = 4;
    }

    final colors = [
      AppColors.error, // Red
      AppColors.warning, // Orange
      AppColors.onboardingViolet, // Indigo/Violet
      AppColors.success, // Emerald
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
              color: AppColors.white.withValues(alpha: 0.45),
            ),
            if (password.isNotEmpty)
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
            final color = isActive ? colors[index] : AppColors.white.withValues(alpha: 0.05);

            return Expanded(
              child: Container(
                height: 4.h,
                margin: EdgeInsets.only(right: index == 3 ? 0 : 6.w),
                decoration: BoxDecoration(
                  color: color,
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
              color: AppColors.white.withValues(alpha: 0.2),
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
