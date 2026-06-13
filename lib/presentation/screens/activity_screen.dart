import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_button.dart';

final activityFilterProvider = StateProvider<String>((ref) => 'All');

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilter = ref.watch(activityFilterProvider);

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
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
                  // Title
                  const AppText(
                    'Activity',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                  // Actions Row (Filter & Download)
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
                            Icons.tune_rounded,
                            color: AppColors.white,
                            size: 18.sp,
                          ),
                          onPressed: () {},
                        ),
                      ),
                      SizedBox(width: 8.w),
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
                            Icons.arrow_downward_rounded,
                            color: AppColors.white,
                            size: 18.sp,
                          ),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // ── Horizontal Filter Pills ──
            SizedBox(
              height: 38.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                children: [
                  _buildFilterPill(ref, 'All', activeFilter),
                  _buildFilterPill(ref, 'Expenses', activeFilter),
                  _buildFilterPill(ref, 'Payments', activeFilter),
                  _buildFilterPill(ref, 'Groups', activeFilter),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // ── Scrollable Activity Content ──
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    // May 2024 Header
                    _buildSectionHeader(
                      title: 'May 2024',
                      amountBadge: '-\$756',
                      isPositive: false,
                    ),
                    SizedBox(height: 12.h),

                    // May 2024 Grouped List Card
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildActivityItem(
                            emoji: '🏨',
                            title: 'Airbnb accommodation',
                            subtitle: 'Barcelona Trip · May 15 · by You',
                            amount: '-\$180',
                            amountColor: AppColors.coralRed,
                          ),
                          _buildDivider(),
                          _buildActivityItem(
                            emoji: '💸',
                            title: 'Sarah paid you back',
                            subtitle: 'Barcelona Trip · May 18',
                            amount: '+\$168',
                            amountColor: const Color(0xFF00C896),
                          ),
                          _buildDivider(),
                          _buildActivityItem(
                            emoji: '🎭',
                            title: 'Sagrada Família tickets',
                            subtitle: 'Barcelona Trip · May 17 · by Sarah',
                            amount: '-\$30',
                            amountColor: AppColors.coralRed,
                          ),
                          _buildDivider(),
                          _buildActivityItem(
                            emoji: '🍕',
                            title: 'Tapas dinner',
                            subtitle: 'Barcelona Trip · May 16 · by Sarah',
                            amount: '-\$42',
                            amountColor: AppColors.coralRed,
                          ),
                          _buildDivider(),
                          _buildActivityItem(
                            emoji: '👥',
                            title: 'Joined "NYC Getaway"',
                            subtitle: 'May 14',
                            amount: '',
                            amountColor: AppColors.white,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // April 2024 Header
                    _buildSectionHeader(
                      title: 'April 2024',
                      amountBadge: '+\$1,560',
                      isPositive: true,
                    ),
                    SizedBox(height: 12.h),

                    // April 2024 Grouped List Card
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildActivityItem(
                            emoji: '🏠',
                            title: 'Priya paid rent share',
                            subtitle: 'Grove Apartment · Apr 30',
                            amount: '+\$800',
                            amountColor: const Color(0xFF00C896),
                          ),
                          _buildDivider(),
                          _buildActivityItem(
                            emoji: '⚡',
                            title: 'Electricity bill',
                            subtitle: 'Grove Apartment · Apr 28 · by Priya',
                            amount: '-\$60',
                            amountColor: AppColors.coralRed,
                          ),
                          _buildDivider(),
                          _buildActivityItem(
                            emoji: '🏠',
                            title: 'Kai paid rent share',
                            subtitle: 'Grove Apartment · Apr 30',
                            amount: '+\$800',
                            amountColor: const Color(0xFF00C896),
                          ),
                          _buildDivider(),
                          _buildActivityItem(
                            emoji: '🛒',
                            title: 'Grocery run',
                            subtitle: 'Grove Apartment · Apr 22 · by You',
                            amount: '-\$47',
                            amountColor: AppColors.coralRed,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Load more activity button
                    AppButton(
                      label: 'Load more activity',
                      isOutlined: true,
                      textColor: AppColors.white.withValues(alpha: 0.6),
                      color: AppColors.cardDark,
                      onTap: () {},
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

  Widget _buildFilterPill(WidgetRef ref, String label, String activeFilter) {
    final isSelected = activeFilter == label;
    return GestureDetector(
      onTap: () => ref.read(activityFilterProvider.notifier).state = label,
      child: Container(
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.onboardingViolet : const Color(0xFF1E1C38),
          borderRadius: BorderRadius.circular(18.r),
        ),
        alignment: Alignment.center,
        child: AppText(
          label,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isSelected
              ? AppColors.white
              : AppColors.white.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String amountBadge,
    required bool isPositive,
  }) {
    final badgeColor =
        isPositive ? const Color(0xFF00C896) : AppColors.coralRed;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          title,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.white.withValues(alpha: 0.4),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: AppText(
            amountBadge,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: badgeColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required String emoji,
    required String title,
    required String subtitle,
    required String amount,
    required Color amountColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          // Emoji Card Container (No border, rounded card look matching screenshots)
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1C38),
              borderRadius: BorderRadius.circular(12.r),
            ),
            alignment: Alignment.center,
            child: AppText(
              emoji,
              fontSize: 16,
            ),
          ),
          SizedBox(width: 12.w),

          // Titles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                AppText(
                  subtitle,
                  fontSize: 11,
                  color: AppColors.white.withValues(alpha: 0.35),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),

          // Amount
          if (amount.isNotEmpty)
            AppText(
              amount,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: amountColor,
            ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withValues(alpha: 0.04),
      height: 1,
      thickness: 1,
      indent: 68.w,
    );
  }
}
