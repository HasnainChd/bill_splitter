import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_button.dart';
import '../../core/router/app_router.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.backgroundGradientStart,
              AppColors.backgroundGradientEnd
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 10.h),

                // Logo and App Name
                _buildLogoSection()
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: -0.15, end: 0, curve: Curves.easeOutQuad),

                SizedBox(height: 38.h),

                // Main Balance Card
                _buildMainBalanceCard()
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 600.ms)
                    .slideY(begin: 0.12, end: 0, curve: Curves.easeOutQuad),

                SizedBox(height: 15.h),

                // Balance Summary Card (merged)
                _buildBalanceSummaryCard()
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 600.ms)
                    .slideY(begin: 0.12, end: 0, curve: Curves.easeOutQuad),

                SizedBox(height: 38.h),

                // Features List
                _buildFeaturesList()
                    .animate()
                    .fadeIn(delay: 450.ms, duration: 600.ms)
                    .slideY(begin: 0.12, end: 0, curve: Curves.easeOutQuad),

                SizedBox(height: 38.h),

                // Get Started Button
                _buildGetStartedButton(context)
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 600.ms)
                    .slideY(begin: 0.12, end: 0, curve: Curves.easeOutQuad),

                SizedBox(height: 16.h),

                // Sign In Link
                _buildSignInLink(context)
                    .animate()
                    .fadeIn(delay: 750.ms, duration: 600.ms),

                SizedBox(height: 22.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        // Logo with background container
        Container(
          width: 80.w,
          height: 80.w,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryPurple, AppColors.primaryPurpleLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Image.asset(
              'assets/zap.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        SizedBox(height: 14.h),
        const AppText(
          'Equaly',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
        SizedBox(height: 8.h),
        const AppText(
          'Split bills. Keep friends.',
          fontSize: 16,
          color: AppColors.textGrey,
        ),
      ],
    );
  }

  Widget _buildMainBalanceCard() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryPurple, AppColors.primaryPurpleDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText(
              'Total Others Owe You',
              fontSize: 14,
              color: AppColors.white,
            ),
            SizedBox(height: 8.h),
            const AppText(
              '\$1,036.00',
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCircle(AppColors.pink),
                    _buildCircle(AppColors.orange),
                    _buildCircle(AppColors.green, isLast: true),
                  ],
                ),
                SizedBox(width: 8.w),
                const AppText(
                  'across 3 groups',
                  fontSize: 14,
                  color: AppColors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircle(Color color, {bool isLast = false}) {
    return Align(
      widthFactor: isLast ? 1.0 : 0.6,
      child: Container(
        width: 20.w,
        height: 20.w,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primaryPurple, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildBalanceSummaryCard() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColors.cardDarkSecondary,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.arrow_upward,
                      size: 14.sp,
                      color: AppColors.error,
                    ),
                    SizedBox(width: 6.w),
                    AppText(
                      'You owe others',
                      fontSize: 11,
                      color: AppColors.textGrey,
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                AppText(
                  '\$41',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 36.h,
            color: AppColors.cardBorder,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppText(
                      'Others owe you',
                      fontSize: 11,
                      color: AppColors.textGrey,
                    ),
                    SizedBox(width: 6.w),
                    Icon(
                      Icons.arrow_downward,
                      size: 14.sp,
                      color: AppColors.success,
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                AppText(
                  '\$1,036',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    return Column(
      children: [
        _buildFeatureItem(
          asset: 'assets/zap_two.png',
          title: 'Split expenses in seconds',
        ),
        SizedBox(height: 16.h),
        _buildFeatureItem(
          asset: 'assets/users.png',
          title: 'Track group balances live',
        ),
        SizedBox(height: 16.h),
        _buildFeatureItem(
          asset: 'assets/check.png',
          title: 'Settle up with one tap',
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required String asset,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(6.w),
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
            ),
          ),
        ),
        SizedBox(width: 14.w),
        AppText(
          title,
          fontSize: 15,
          color: AppColors.white,
        ),
      ],
    );
  }

  Widget _buildGetStartedButton(BuildContext context) {
    return AppButton(
      label: 'Get Started',
      onTap: () {
        context.push(AppRouter.walkthrough);
      },
      color: AppColors.primaryPurple,
      textColor: AppColors.white,
      height: 56.h,
    );
  }

  Widget _buildSignInLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppText(
          'Already have an account? ',
          fontSize: 14,
          color: AppColors.textGrey,
        ),
        GestureDetector(
          onTap: () {
            context.push(AppRouter.login);
          },
          child: AppText(
            'Sign In',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryPurple,
          ),
        ),
      ],
    );
  }
}
