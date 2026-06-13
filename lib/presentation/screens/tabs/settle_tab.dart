import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_text.dart';
import '../../providers/tab_providers.dart';

class SettleTab extends ConsumerWidget {
  const SettleTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settleFilter = ref.watch(settleFilterProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.h),
              // Title
              const AppText(
                'Settle Up',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
              SizedBox(height: 16.h),

              // ── Summary Cards ──
              Row(
                children: [
                  _buildSummaryCard('You Owe', '\$41', '1 person',
                      AppColors.balanceOwed),
                  SizedBox(width: 12.w),
                  _buildSummaryCard('Owed to You', '\$908', '2 people',
                      AppColors.balanceOwedTo),
                ],
              ),
              SizedBox(height: 16.h),

              // ── Filter Chips ──
              Row(
                children: [
                  _buildChip(ref, 'All', settleFilter),
                  SizedBox(width: 8.w),
                  _buildChip(ref, 'I Owe', settleFilter),
                  SizedBox(width: 8.w),
                  _buildChip(ref, 'Owed to Me', settleFilter),
                ],
              ),
              SizedBox(height: 16.h),

              // ── Person Cards ──
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(bottom: 80.h),
                  children: [
                    if (settleFilter == 'All' || settleFilter == 'I Owe') ...[
                      _buildSectionLabel('YOU OWE'),
                      _buildPersonCard(
                        name: 'Marcus Thompson',
                        sub: 'Friday Crew • 3 days ago',
                        amount: '-\$41',
                        amountColor: AppColors.balanceOwed,
                        buttonLabel: 'Pay',
                        isOwe: true,
                        initials: 'MT',
                        avatarColor: AppColors.avatarAmber,
                      ),
                      SizedBox(height: 16.h),
                    ],
                    if (settleFilter == 'All' ||
                        settleFilter == 'Owed to Me') ...[
                      _buildSectionLabel('OWED TO YOU'),
                      _buildPersonCard(
                        name: 'Sarah Chen',
                        sub: 'Barcelona Trip • 5 days ago',
                        amount: '+\$168',
                        amountColor: AppColors.balanceOwedTo,
                        buttonLabel: 'Remind',
                        isOwe: false,
                        initials: 'SC',
                        avatarColor: AppColors.avatarRose,
                      ),
                      SizedBox(height: 12.h),
                      _buildPersonCard(
                        name: 'Priya Patel',
                        sub: 'Grove Apt • 1 month ago',
                        amount: '+\$740',
                        amountColor: AppColors.balanceOwedTo,
                        buttonLabel: 'Remind',
                        isOwe: false,
                        initials: 'PP',
                        avatarColor: AppColors.avatarEmerald,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // ── Pinned "Settle All" button ──
          if (settleFilter == 'All' || settleFilter == 'I Owe')
            Positioned(
              bottom: 16.h,
              left: 0,
              right: 0,
              child: Container(
                height: 48.h,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.success, AppColors.successDark],
                  ),
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.check_circle_rounded,
                      color: AppColors.white, size: 20),
                  label: const AppText(
                    'Settle All — Pay \$41',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Helpers ──

  Widget _buildSummaryCard(
      String label, String value, String subtitle, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16.r),
          border:
              Border.all(color: AppColors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(label, fontSize: 12,
                color: AppColors.white.withValues(alpha: 0.5)),
            SizedBox(height: 6.h),
            AppText(value, fontSize: 24,
                fontWeight: FontWeight.w800, color: color),
            SizedBox(height: 4.h),
            AppText(subtitle, fontSize: 11,
                color: AppColors.white.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(WidgetRef ref, String label, String current) {
    final isSelected = current == label;
    return GestureDetector(
      onTap: () =>
          ref.read(settleFilterProvider.notifier).state = label,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.onboardingViolet : AppColors.cardDark,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppColors.white.withValues(alpha: 0.06),
          ),
        ),
        child: AppText(
          label,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSelected
              ? AppColors.white
              : AppColors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, top: 4.h),
      child: AppText(
        text,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.white.withValues(alpha: 0.4),
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildPersonCard({
    required String name,
    required String sub,
    required String amount,
    required Color amountColor,
    required String buttonLabel,
    required bool isOwe,
    required String initials,
    required Color avatarColor,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16.r),
        border:
            Border.all(color: AppColors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
                color: avatarColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: AppText(initials, fontSize: 13,
                fontWeight: FontWeight.w700, color: AppColors.white),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(name, fontSize: 14,
                    fontWeight: FontWeight.w700, color: AppColors.white),
                SizedBox(height: 4.h),
                AppText(sub, fontSize: 11,
                    color: AppColors.white.withValues(alpha: 0.4)),
              ],
            ),
          ),
          Row(
            children: [
              AppText(amount, fontSize: 14,
                  fontWeight: FontWeight.w800, color: amountColor),
              SizedBox(width: 12.w),
              SizedBox(
                height: 28.h,
                child: isOwe
                    ? ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.onboardingViolet,
                          elevation: 0,
                          padding:
                              EdgeInsets.symmetric(horizontal: 14.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: AppText(buttonLabel, fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white),
                      )
                    : OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color:
                                AppColors.white.withValues(alpha: 0.15),
                          ),
                          padding:
                              EdgeInsets.symmetric(horizontal: 12.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.notifications_none_rounded,
                                color:
                                    AppColors.white.withValues(alpha: 0.6),
                                size: 12.sp),
                            SizedBox(width: 4.w),
                            AppText(buttonLabel, fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
