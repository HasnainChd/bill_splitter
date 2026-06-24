import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../providers/settings_provider.dart';

final equalyProBillingCycleProvider =
    StateProvider.autoDispose<String>((ref) => 'Yearly');

class EqualyProScreen extends ConsumerWidget {
  const EqualyProScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billingCycle = ref.watch(equalyProBillingCycleProvider);
    final isYearly = billingCycle == 'Yearly';

    final defaultCurrency = ref.watch(defaultCurrencyProvider);
    final proPrice = isYearly ? '$defaultCurrency 3.49' : '$defaultCurrency 4.99';
    final teamPrice = isYearly ? '$defaultCurrency 6.99' : '$defaultCurrency 9.99';

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
                  const Spacer(),
                  // Gold Bolt + Equaly Pro Header
                  Row(
                    children: [
                      Icon(Icons.bolt_rounded,
                          color: Colors.amber, size: 20.sp),
                      SizedBox(width: 4.w),
                      const AppText(
                        'Equaly Pro',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.amber,
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(width: 42.w), // Balance spacer
                ],
              ),
            ),

            // ── Scrollable Content ──
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    SizedBox(height: 16.h),
                    // Centered Titles
                    const AppText(
                      'Upgrade your experience',
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.white,
                      align: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    AppText(
                      'Unlock unlimited groups, receipt scanning,\nand advanced analytics.',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white.withValues(alpha: 0.5),
                      align: TextAlign.center,
                      height: 1.4,
                    ),
                    SizedBox(height: 24.h),

                    // Monthly / Yearly billing selector
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildBillingCycleTab(
                            ref: ref,
                            label: 'Monthly',
                            cycleKey: 'Monthly',
                            activeCycle: billingCycle,
                          ),
                          _buildBillingCycleTab(
                            ref: ref,
                            label: 'Yearly · Save 30%',
                            cycleKey: 'Yearly',
                            activeCycle: billingCycle,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // ── Free Plan Card ──
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const AppText(
                                'Free',
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                              ),
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.w, vertical: 3.h),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: AppText(
                                  'CURRENT',
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              AppText(
                                '$defaultCurrency 0',
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                              ),
                              AppText(
                                ' /forever',
                                fontSize: 13,
                                color: AppColors.white.withValues(alpha: 0.4),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          // Chips wrap
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: const [
                              _PlanChip(label: 'Up to 3 groups'),
                              _PlanChip(label: 'Up to 5 members/group'),
                              _PlanChip(label: 'Basic expense splitting'),
                            ],
                          ),
                          SizedBox(height: 20.h),
                          // Current Plan disabled button
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: AppColors.white.withValues(alpha: 0.1),
                                width: .5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: AppText(
                              'Current Plan',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // ── Pro Plan Card (Popular - Indigo Gradient) ──
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.onboardingViolet,
                            AppColors.primaryPurpleDarker,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.onboardingViolet
                                .withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const AppText(
                                'Pro',
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                              ),
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.w, vertical: 3.h),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: const AppText(
                                  'POPULAR',
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              AppText(
                                proPrice,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                              ),
                              AppText(
                                ' /per month',
                                fontSize: 13,
                                color: AppColors.white.withValues(alpha: 0.8),
                              ),
                            ],
                          ),
                          SizedBox(height: 20.h),
                          // Checklist bullet items
                          _buildBulletPoint('Unlimited groups'),
                          _buildBulletPoint('Unlimited members'),
                          _buildBulletPoint('Advanced analytics'),
                          _buildBulletPoint('Receipt scanning (OCR)'),
                          _buildBulletPoint('Push & email notifications'),
                          SizedBox(height: 6.h),
                          Padding(
                            padding: EdgeInsets.only(left: 28.w),
                            child: AppText(
                              '+3 more features',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white.withValues(alpha: 0.6),
                            ),
                          ),
                          SizedBox(height: 24.h),
                          // Upgrade white button
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            alignment: Alignment.center,
                            child: const AppText(
                              'Upgrade to Pro',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onboardingViolet,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // ── Team Plan Card ──
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppText(
                            'Team',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              AppText(
                                teamPrice,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                              ),
                              AppText(
                                ' /per month',
                                fontSize: 13,
                                color: AppColors.white.withValues(alpha: 0.4),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: const [
                              _PlanChip(label: 'Everything in Pro'),
                              _PlanChip(label: 'Shared team dashboard'),
                              _PlanChip(label: 'Admin controls'),
                            ],
                          ),
                          SizedBox(height: 20.h),
                          // Get Team button
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: AppColors.white.withValues(alpha: 0.1),
                                width: .5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const AppText(
                              'Get Team',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Footer App Store notice
                    AppText(
                      'Cancel anytime · 7-day free trial · Secure payment via App Store',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white.withValues(alpha: 0.25),
                      align: TextAlign.center,
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

  Widget _buildBillingCycleTab({
    required WidgetRef ref,
    required String label,
    required String cycleKey,
    required String activeCycle,
  }) {
    final isSelected = activeCycle == cycleKey;
    return GestureDetector(
      onTap: () {
        ref.read(equalyProBillingCycleProvider.notifier).state = cycleKey;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.white.withValues(alpha: 0.02)
              : AppColors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: isSelected
              ? Border.all(
                  color: AppColors.white.withValues(alpha: 0.15), width: 1.2)
              : null,
        ),
        child: AppText(
          label,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
          color: isSelected
              ? AppColors.white
              : AppColors.white.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Container(
            width: 18.w,
            height: 18.w,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child:
                Icon(Icons.check_rounded, color: AppColors.white, size: 12.sp),
          ),
          SizedBox(width: 10.w),
          AppText(
            text,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ],
      ),
    );
  }
}

class _PlanChip extends StatelessWidget {
  final String label;
  const _PlanChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: AppText(
        label,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.white.withValues(alpha: 0.5),
      ),
    );
  }
}
