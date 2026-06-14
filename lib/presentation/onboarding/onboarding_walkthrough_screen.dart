import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_button.dart';
import '../../core/router/app_router.dart';
import '../../providers/onboarding_provider.dart';

class OnboardingWalkthroughScreen extends ConsumerWidget {
  const OnboardingWalkthroughScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageIndex = ref.watch(onboardingPageIndexProvider);
    final pageController = ref.watch(onboardingPageControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      context.go(AppRouter.login);
                    },
                    child: AppText(
                      'Skip',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGrey.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            // PageView Card Container
            Expanded(
              child: PageView(
                controller: pageController,
                onPageChanged: (index) {
                  ref.read(onboardingPageIndexProvider.notifier).state = index;
                },
                children: [
                  // Page 1: Split any expense instantly (Matches Screenshot 1/3)
                  _buildPageCard(
                    context: context,
                    pageIndexText: '1 / 3',
                    title: 'Split any expense\ninstantly',
                    description:
                        'Dinners, trips, rent — add an expense and it\'s split in seconds. Divvy handles the math.',
                    cardColor: AppColors.onboardingViolet,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildExpenseCapsule(
                          title: 'Airbnb',
                          totalAmount: '€540',
                          shareAmount: '€180',
                        ),
                        SizedBox(height: 12.h),
                        _buildExpenseCapsule(
                          title: 'Dinner',
                          totalAmount: '€126',
                          shareAmount: '€42',
                        ),
                        SizedBox(height: 12.h),
                        _buildExpenseCapsule(
                          title: 'Tickets',
                          totalAmount: '€90',
                          shareAmount: '€30',
                        ),
                      ],
                    ),
                  ),

                  // Page 2: Track balances in real-time (Matches Screenshot 2/3)
                  _buildPageCard(
                    context: context,
                    pageIndexText: '2 / 3',
                    title: 'Always know\nwho owes what',
                    description:
                        'Real-time balances across every group. No more awkward \'can you pay me back?\' texts.',
                    cardColor: AppColors.onboardingCyan,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildBalanceCapsule(
                          initials: 'SC',
                          avatarBgColor: AppColors.avatarRose,
                          name: 'Sarah',
                          balanceText: '+\$337',
                          isPositive: true,
                        ),
                        SizedBox(height: 12.h),
                        _buildBalanceCapsule(
                          initials: 'MT',
                          avatarBgColor: AppColors.avatarAmber,
                          name: 'Marcus',
                          balanceText: '-\$41',
                          isPositive: false,
                        ),
                        SizedBox(height: 12.h),
                        _buildBalanceCapsule(
                          initials: 'PP',
                          avatarBgColor: AppColors.avatarEmerald,
                          name: 'Priya',
                          balanceText: '\$740',
                          isPositive: true,
                        ),
                      ],
                    ),
                  ),

                  // Page 3: Settle debts with one tap (Matches Screenshot 3/3)
                  _buildPageCard(
                    context: context,
                    pageIndexText: '3 / 3',
                    title: 'Settle up\nin one tap',
                    description:
                        'Connect Venmo, PayPal, or bank transfer. One tap and you\'re square — everyone notified.',
                    cardColor: AppColors.onboardingGreen,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // White circle checkmark
                        Container(
                          width: 64.w,
                          height: 64.w,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: AppColors.onboardingGreen,
                            size: 36,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        // Translucent pill card with transaction status
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 18.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const AppText(
                                'Sent \$41.00 to Marcus',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              SizedBox(height: 4.h),
                              AppText(
                                'via Apple Pay • just now',
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Page Indicator Dots
            _buildPageIndicator(pageIndex),

            SizedBox(height: 24.h),

            // Next / Get Started Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: AppButton(
                label: pageIndex == 2 ? 'Get Started →' : 'Next →',
                onTap: () {
                  if (pageIndex < 2) {
                    pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    context.go(AppRouter.login);
                  }
                },
                color: AppColors.onboardingViolet,
                textColor: AppColors.white,
              ),
            ),

            SizedBox(height: 16.h),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppText(
                  'Already have an account? ',
                  fontSize: 14,
                  color: AppColors.textGrey,
                ),
                GestureDetector(
                  onTap: () {
                    context.go(AppRouter.login);
                  },
                  child: const AppText(
                    'Sign In',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onboardingViolet,
                  ),
                ),
              ],
            ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildPageCard({
    required BuildContext context,
    required String pageIndexText,
    required String title,
    required String description,
    required Color cardColor,
    required Widget child,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(32.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Circular ornaments in top-right
          Positioned(
            top: -60.h,
            right: -60.w,
            child: Container(
              width: 200.w,
              height: 200.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -120.h,
            right: -120.w,
            child: Container(
              width: 320.w,
              height: 320.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Slide Index indicator inside card
                AppText(
                  pageIndexText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                SizedBox(height: 24.h),

                // Visual content section
                Expanded(
                  child: Center(
                    child: child
                        .animate(key: ValueKey('${pageIndexText}_child'))
                        .fadeIn(duration: 500.ms)
                        .scale(
                          begin: const Offset(0.9, 0.9),
                          end: const Offset(1.0, 1.0),
                          curve: Curves.easeOutBack,
                        ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Title
                AppText(
                  title,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.15,
                )
                    .animate(key: ValueKey('${pageIndexText}_title'))
                    .fadeIn(delay: 150.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                SizedBox(height: 12.h),

                // Description
                AppText(
                  description,
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.4,
                )
                    .animate(key: ValueKey('${pageIndexText}_desc'))
                    .fadeIn(delay: 300.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                SizedBox(height: 8.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCapsule({
    required String title,
    required String totalAmount,
    required String shareAmount,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              AppText(
                title,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              AppText(
                ' • $totalAmount',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ],
          ),
          AppText(
            '$shareAmount each',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.mintGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCapsule({
    required String initials,
    required Color avatarBgColor,
    required String name,
    required String balanceText,
    required bool isPositive,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: avatarBgColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: AppText(
                  initials,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12.w),
              AppText(
                name,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ],
          ),
          AppText(
            balanceText,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isPositive ? AppColors.mintGreen : AppColors.coralRed,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int currentIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          height: 8.h,
          width: isActive ? 24.w : 8.w,
          decoration: BoxDecoration(
            color:
                isActive ? AppColors.onboardingViolet : const Color(0xFF3A3A4A),
            borderRadius: BorderRadius.circular(4.r),
          ),
        );
      }),
    );
  }
}
