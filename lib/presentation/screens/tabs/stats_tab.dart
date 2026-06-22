import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/utils/financial_calculator.dart';

final statsPeriodProvider = StateProvider.autoDispose<String>((ref) => '6M');
final selectedStatsMonthProvider =
    StateProvider.autoDispose<String>((ref) => 'May');

class StatsTab extends ConsumerWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePeriod = ref.watch(statsPeriodProvider);
    final selectedMonth = ref.watch(selectedStatsMonthProvider);
    final defaultCurrency = ref.watch(defaultCurrencyProvider);

    final expenseState = ref.watch(expenseProvider);
    final currentUserId = ref.watch(supabaseUserProvider)?.id;

    // Dynamic metrics based on active period selection
    String spentVal = '$defaultCurrency 0';
    String receivedVal = '$defaultCurrency 0';
    String netVal = '+$defaultCurrency 0';

    if (currentUserId != null) {
      // In a fully built app, we'd filter expenses by activePeriod here
      // For now, we use all expenses dynamically to ensure synchronization
      final totals = FinancialCalculator.calculateUserGlobalBalances(currentUserId, expenseState.expenses);
      final owes = totals['owes'] ?? 0.0;
      final owedToYou = totals['owedToYou'] ?? 0.0;
      final net = totals['net'] ?? 0.0;

      spentVal = '$defaultCurrency ${owes.toStringAsFixed(0)}';
      receivedVal = '$defaultCurrency ${owedToYou.toStringAsFixed(0)}';
      netVal = '${net >= 0 ? '+' : '-'}$defaultCurrency ${net.abs().toStringAsFixed(0)}';
    }

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Column(
          children: [
            SizedBox(height: 30.h),
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              child: Row(
                children: [
                  const AppText(
                    'Analytics',
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                  const Spacer(),
                  // Period selector
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.05),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: ['1M', '3M', '6M', '1Y'].map((period) {
                        final isActive = activePeriod == period;
                        return GestureDetector(
                          onTap: () {
                            ref.read(statsPeriodProvider.notifier).state =
                                period;
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.white.withValues(alpha: 0.04)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10.r),
                              border: isActive
                                  ? Border.all(
                                      color: AppColors.white
                                          .withValues(alpha: 0.1),
                                      width: 1)
                                  : null,
                            ),
                            child: AppText(
                              period,
                              fontSize: 12,
                              fontWeight:
                                  isActive ? FontWeight.w800 : FontWeight.w600,
                              color: isActive
                                  ? AppColors.white
                                  : AppColors.white.withValues(alpha: 0.35),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Spending Summary Cards row
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Total Spent',
                            value: spentVal,
                            subtitle: '↓ 12% vs last period',
                            valueColor: const Color(0xFFF43F5E), // Red/coral
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Received',
                            value: receivedVal,
                            subtitle: '↑ 24% vs last period',
                            valueColor: const Color(0xFF10B981), // Green
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Net',
                            value: netVal,
                            subtitle: 'Overall balance',
                            valueColor: const Color(0xFF10B981), // Green
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Monthly Activity Card
                    AppCard(
                      padding: EdgeInsets.all(18.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const AppText(
                                'Monthly Activity',
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                              ),
                              Row(
                                children: [
                                  _buildLegendDot(
                                      const Color(0xFFF43F5E), 'Spent'),
                                  SizedBox(width: 12.w),
                                  _buildLegendDot(
                                      const Color(0xFF10B981), 'Received'),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 30.h),
                          // Custom Bar Chart
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildDualBar(
                                  ref, 'Jan', 40.h, 20.h, selectedMonth),
                              _buildDualBar(
                                  ref, 'Feb', 80.h, 60.h, selectedMonth),
                              _buildDualBar(
                                  ref, 'Mar', 30.h, 80.h, selectedMonth),
                              _buildDualBar(
                                  ref, 'Apr', 88.h, 50.h, selectedMonth),
                              _buildDualBar(
                                  ref, 'May', 75.h, 100.h, selectedMonth,
                                  showBadge: true, badgeText: '$defaultCurrency 620'),
                              _buildDualBar(
                                  ref, 'Jun', 35.h, 120.h, selectedMonth),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // By Category section label
                    const AppText(
                      'By Category',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                    SizedBox(height: 12.h),

                    // By Category items
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildCategoryRow(
                            icon: Icons.restaurant_rounded,
                            iconColor: const Color(0xFF6366F1),
                            title: 'Food & Dining',
                            amount: '$defaultCurrency 412',
                            percentage: '38%',
                            progress: 0.38,
                            themeColor: const Color(0xFF6366F1),
                          ),
                          _buildCategoryDivider(),
                          _buildCategoryRow(
                            icon: Icons.flight_takeoff_rounded,
                            iconColor: const Color(0xFF0EA5E9),
                            title: 'Travel',
                            amount: '$defaultCurrency 324',
                            percentage: '30%',
                            progress: 0.30,
                            themeColor: const Color(0xFF0EA5E9),
                          ),
                          _buildCategoryDivider(),
                          _buildCategoryRow(
                            icon: Icons.home_filled,
                            iconColor: const Color(0xFF10B981),
                            title: 'Rent & Bills',
                            amount: '$defaultCurrency 216',
                            percentage: '20%',
                            progress: 0.20,
                            themeColor: const Color(0xFF10B981),
                          ),
                          _buildCategoryDivider(),
                          _buildCategoryRow(
                            icon: Icons.theater_comedy_rounded,
                            iconColor: const Color(0xFFF59E0B),
                            title: 'Entertainment',
                            amount: '$defaultCurrency 130',
                            percentage: '12%',
                            progress: 0.12,
                            themeColor: const Color(0xFFF59E0B),
                          ),
                        ],
                      ),
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

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color valueColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.04),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            title,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.white.withValues(alpha: 0.45),
          ),
          SizedBox(height: 6.h),
          AppText(
            value,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
          SizedBox(height: 6.h),
          AppText(
            subtitle,
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: AppColors.white.withValues(alpha: 0.3),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 6.w,
          height: 6.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 6.w),
        AppText(
          text,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.white.withValues(alpha: 0.45),
        ),
      ],
    );
  }

  Widget _buildDualBar(
    WidgetRef ref,
    String label,
    double spentHeight,
    double receivedHeight,
    String selectedMonth, {
    bool showBadge = false,
    String badgeText = '',
  }) {
    final isSelected = selectedMonth == label;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        ref.read(selectedStatsMonthProvider.notifier).state = label;
      },
      child: Column(
        children: [
          // Selected Month Badge
          Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // Keep vertical height space occupied so chart doesn't layout jump
              SizedBox(height: 24.h),
              if (isSelected && showBadge)
                Positioned(
                  bottom: 2.h,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                        width: 0.5,
                      ),
                    ),
                    child: AppText(
                      badgeText,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 6.h),
          // Dual Bars
          Opacity(
            opacity: isSelected ? 1.0 : 0.45,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Spent bar (Red)
                Container(
                  width: 10.w,
                  height: spentHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF43F5E),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(3.r)),
                  ),
                ),
                SizedBox(width: 4.w),
                // Received bar (Green)
                Container(
                  width: 10.w,
                  height: receivedHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(3.r)),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          AppText(
            label,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? AppColors.white
                : AppColors.white.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String amount,
    required String percentage,
    required double progress,
    required Color themeColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1C38),
              borderRadius: BorderRadius.circular(10.r),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 16.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      title,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                    Row(
                      children: [
                        AppText(
                          amount,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                        SizedBox(width: 8.w),
                        AppText(
                          percentage,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: themeColor,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Container(
                  width: double.infinity,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1C38),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: themeColor,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
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

  Widget _buildCategoryDivider() {
    return Divider(
      color: Colors.white.withValues(alpha: 0.04),
      height: 1,
      thickness: 1,
      indent: 64.w,
    );
  }
}
