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
import 'package:intl/intl.dart';

final statsPeriodProvider = StateProvider.autoDispose<String>((ref) => '6M');
final selectedStatsMonthProvider = StateProvider.autoDispose<String>((ref) {
  return DateFormat('MMM').format(DateTime.now());
});

class StatsTab extends ConsumerWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePeriod = ref.watch(statsPeriodProvider);
    final selectedMonth = ref.watch(selectedStatsMonthProvider);
    final defaultCurrency = ref.watch(defaultCurrencyProvider);

    final expenseState = ref.watch(expenseProvider);
    final currentUserId = ref.watch(supabaseUserProvider)?.id;

    final currencyCode = defaultCurrency.length >= 3
        ? defaultCurrency.substring(0, 3)
        : 'PKR';
    final currencySymbol = (() {
      final openParen = defaultCurrency.indexOf('(');
      final closeParen = defaultCurrency.indexOf(')');
      if (openParen != -1 && closeParen != -1 && closeParen > openParen) {
        return defaultCurrency.substring(openParen + 1, closeParen);
      }
      return currencyCode;
    })();

    // Dynamic metrics based on active period selection
    String spentVal = '$currencySymbol 0';
    String receivedVal = '$currencySymbol 0';
    String netVal = '+$currencySymbol 0';
    String spentSubtitle = 'No change vs last period';
    String receivedSubtitle = 'No change vs last period';
    String netSubtitle = 'No change vs last period';

    if (currentUserId != null) {
      // Filter expenses based on activePeriod
      final now = DateTime.now();
      DateTime startDate;
      DateTime prevStartDate;
      
      switch (activePeriod) {
        case '1M': 
          startDate = DateTime(now.year, now.month - 1, now.day); 
          prevStartDate = DateTime(now.year, now.month - 2, now.day);
          break;
        case '3M': 
          startDate = DateTime(now.year, now.month - 3, now.day); 
          prevStartDate = DateTime(now.year, now.month - 6, now.day);
          break;
        case '1Y': 
          startDate = DateTime(now.year - 1, now.month, now.day); 
          prevStartDate = DateTime(now.year - 2, now.month, now.day);
          break;
        case '6M':
        default: 
          startDate = DateTime(now.year, now.month - 6, now.day); 
          prevStartDate = DateTime(now.year, now.month - 12, now.day);
          break;
      }

      final filteredExpenses = expenseState.expenses.where((e) => e.date.isAfter(startDate)).toList();
      final prevFilteredExpenses = expenseState.expenses.where((e) => e.date.isAfter(prevStartDate) && e.date.isBefore(startDate)).toList();

      final totals = FinancialCalculator.calculateUserGlobalBalances(currentUserId, filteredExpenses);
      final prevTotals = FinancialCalculator.calculateUserGlobalBalances(currentUserId, prevFilteredExpenses);

      final owes = totals['owes'] ?? 0.0;
      final owedToYou = totals['owedToYou'] ?? 0.0;
      final net = totals['net'] ?? 0.0;
      
      final prevOwes = prevTotals['owes'] ?? 0.0;
      final prevOwedToYou = prevTotals['owedToYou'] ?? 0.0;
      final prevNet = prevTotals['net'] ?? 0.0;

      String getChangeStr(double current, double prev) {
         if (prev == 0) return current > 0 ? '↑ 100% vs last period' : 'No change vs last period';
         double diff = current - prev;
         double pct = (diff.abs() / prev) * 100;
         if (pct < 1) return 'No change vs last period';
         return '${diff > 0 ? '↑' : '↓'} ${pct.toStringAsFixed(0)}% vs last period';
      }

      spentVal = '$currencySymbol ${owes.toStringAsFixed(0)}';
      receivedVal = '$currencySymbol ${owedToYou.toStringAsFixed(0)}';
      netVal = '${net >= 0 ? '+' : '-'}$currencySymbol ${net.abs().toStringAsFixed(0)}';
      
      spentSubtitle = getChangeStr(owes, prevOwes);
      receivedSubtitle = getChangeStr(owedToYou, prevOwedToYou);
      
      if (prevNet == 0) {
          netSubtitle = net != 0 ? 'Changed vs last period' : 'No change vs last period';
      } else {
          double netDiff = net - prevNet;
          double netPct = (netDiff.abs() / prevNet.abs()) * 100;
          if (netPct < 1) netSubtitle = 'No change vs last period';
          else netSubtitle = '${netDiff > 0 ? '↑' : '↓'} ${netPct.toStringAsFixed(0)}% vs last period';
      }
    }

    // --- Dynamic Monthly Chart ---
    final now = DateTime.now();
    final last6Months = <DateTime>[];
    for (int i = 5; i >= 0; i--) {
      last6Months.add(DateTime(now.year, now.month - i, 1));
    }

    Map<String, double> spentPerMonth = {};
    Map<String, double> receivedPerMonth = {};

    if (currentUserId != null) {
      for (var monthDate in last6Months) {
         final monthKey = DateFormat('MMM yyyy').format(monthDate);
         final monthExpenses = expenseState.expenses.where((e) {
             return e.date.year == monthDate.year && e.date.month == monthDate.month;
         }).toList();
         
         final monthTotals = FinancialCalculator.calculateUserGlobalBalances(currentUserId, monthExpenses);
         spentPerMonth[monthKey] = monthTotals['owes'] ?? 0.0;
         receivedPerMonth[monthKey] = monthTotals['owedToYou'] ?? 0.0;
      }
    }

    double maxMonthVal = 1.0; // avoid division by zero
    for (var m in last6Months) {
       final mk = DateFormat('MMM yyyy').format(m);
       if ((spentPerMonth[mk] ?? 0) > maxMonthVal) maxMonthVal = spentPerMonth[mk]!;
       if ((receivedPerMonth[mk] ?? 0) > maxMonthVal) maxMonthVal = receivedPerMonth[mk]!;
    }

    final double maxBarHeight = 120.h;
    List<Widget> barWidgets = last6Months.map((m) {
       final mk = DateFormat('MMM yyyy').format(m);
       final label = DateFormat('MMM').format(m);
       final spent = spentPerMonth[mk] ?? 0;
       final received = receivedPerMonth[mk] ?? 0;
       
       return _buildDualBar(
          ref, 
          label, 
          (spent / maxMonthVal) * maxBarHeight, 
          (received / maxMonthVal) * maxBarHeight, 
          selectedMonth,
          showBadge: label == selectedMonth,
          badgeText: '$currencySymbol ${(spent + received).toStringAsFixed(0)}'
       );
    }).toList();

    // --- Dynamic Categories ---
    DateTime filterStartDate;
    switch (activePeriod) {
      case '1M': filterStartDate = DateTime(now.year, now.month - 1, now.day); break;
      case '3M': filterStartDate = DateTime(now.year, now.month - 3, now.day); break;
      case '1Y': filterStartDate = DateTime(now.year - 1, now.month, now.day); break;
      case '6M':
      default: filterStartDate = DateTime(now.year, now.month - 6, now.day); break;
    }
    final filteredCatExpenses = expenseState.expenses.where((e) => e.date.isAfter(filterStartDate)).toList();

    Map<String, double> categoryTotals = {};
    double totalFilteredAmount = 0;

    for (var e in filteredCatExpenses) {
       String catName = 'Other';
       if (e.categoryIconCodePoint == Icons.restaurant_rounded.codePoint || e.categoryIconCodePoint == Icons.local_pizza_rounded.codePoint || e.categoryIconCodePoint == Icons.local_cafe_rounded.codePoint || e.categoryIconCodePoint == Icons.local_bar_rounded.codePoint || e.categoryIconCodePoint == Icons.shopping_basket_rounded.codePoint) {
         catName = 'Dining & Groceries';
       } else if (e.categoryIconCodePoint == Icons.flight_takeoff_rounded.codePoint || e.categoryIconCodePoint == Icons.directions_car_rounded.codePoint || e.categoryIconCodePoint == Icons.hotel_rounded.codePoint || e.categoryIconCodePoint == Icons.directions_boat_rounded.codePoint || e.categoryIconCodePoint == Icons.map_rounded.codePoint) {
         catName = 'Travel';
       } else if (e.categoryIconCodePoint == Icons.home_rounded.codePoint || e.categoryIconCodePoint == Icons.apartment_rounded.codePoint || e.categoryIconCodePoint == Icons.weekend_rounded.codePoint || e.categoryIconCodePoint == Icons.bolt_rounded.codePoint || e.categoryIconCodePoint == Icons.water_drop_rounded.codePoint) {
         catName = 'Housing & Utilities';
       } else if (e.categoryIconCodePoint == Icons.celebration_rounded.codePoint || e.categoryIconCodePoint == Icons.movie_creation_rounded.codePoint || e.categoryIconCodePoint == Icons.sports_esports_rounded.codePoint || e.categoryIconCodePoint == Icons.sports_soccer_rounded.codePoint || e.categoryIconCodePoint == Icons.shopping_bag_rounded.codePoint) {
         catName = 'Life & Entertainment';
       } else {
         catName = 'General';
       }

       categoryTotals[catName] = (categoryTotals[catName] ?? 0) + e.amount;
       totalFilteredAmount += e.amount;
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<Widget> categoryWidgets = [];
    if (sortedCategories.isEmpty) {
        categoryWidgets.add(Padding(
          padding: EdgeInsets.all(24.w),
          child: AppText('No expenses found for this period.', color: AppColors.white.withValues(alpha: 0.5)),
        ));
    } else {
        for (int i = 0; i < sortedCategories.length; i++) {
            final cat = sortedCategories[i];
            final pct = totalFilteredAmount > 0 ? (cat.value / totalFilteredAmount) : 0.0;
            
            IconData icon = Icons.category_rounded;
            Color iconColor = AppColors.catGeneral;
            if (cat.key.toLowerCase().contains('food') || cat.key.toLowerCase().contains('din')) { icon = Icons.restaurant_rounded; iconColor = AppColors.catFood; }
            else if (cat.key.toLowerCase().contains('travel') || cat.key.toLowerCase().contains('trans')) { icon = Icons.flight_takeoff_rounded; iconColor = AppColors.catTravel; }
            else if (cat.key.toLowerCase().contains('hous') || cat.key.toLowerCase().contains('rent')) { icon = Icons.home_filled; iconColor = AppColors.catHousing; }
            else if (cat.key.toLowerCase().contains('util')) { icon = Icons.bolt_rounded; iconColor = AppColors.catUtilities; }
            else if (cat.key.toLowerCase().contains('entert')) { icon = Icons.theater_comedy_rounded; iconColor = AppColors.catEntertainment; }

            categoryWidgets.add(
                _buildCategoryRow(
                   icon: icon,
                   iconColor: iconColor,
                   title: cat.key,
                   amount: '$currencySymbol ${cat.value.toStringAsFixed(0)}',
                   percentage: '${(pct * 100).toStringAsFixed(0)}%',
                   progress: pct,
                   themeColor: iconColor,
                )
            );
            if (i < sortedCategories.length - 1) {
                categoryWidgets.add(_buildCategoryDivider());
            }
        }
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
                            subtitle: spentSubtitle,
                            valueColor: AppColors.avatarRose,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Received',
                            value: receivedVal,
                            subtitle: receivedSubtitle,
                            valueColor: AppColors.success,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Net',
                            value: netVal,
                            subtitle: netSubtitle,
                            valueColor: netVal.startsWith('-') ? AppColors.avatarRose : AppColors.success,
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
                                      AppColors.avatarRose, 'Spent'),
                                  SizedBox(width: 12.w),
                                  _buildLegendDot(
                                      AppColors.success, 'Received'),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 30.h),
                          // Custom Bar Chart
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: barWidgets,
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
                        children: categoryWidgets,
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
                    color: AppColors.avatarRose,
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
                    color: AppColors.success,
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
