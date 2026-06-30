import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/group_provider.dart';
import '../../../core/models/expense.dart';
import 'package:intl/intl.dart';

final statsPeriodProvider = StateProvider.autoDispose<String>((ref) => '6M');
final selectedStatsMonthProvider = StateProvider.autoDispose<String>((ref) {
  return DateFormat('MMM').format(DateTime.now());
});

class StatsTab extends ConsumerStatefulWidget {
  const StatsTab({super.key});

  @override
  ConsumerState<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends ConsumerState<StatsTab> {
  int _activeCurrencyIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _activeCurrencyIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getCategoryGroupName(int iconCodePoint) {
    if (iconCodePoint == Icons.restaurant_rounded.codePoint ||
        iconCodePoint == Icons.local_pizza_rounded.codePoint ||
        iconCodePoint == Icons.local_cafe_rounded.codePoint ||
        iconCodePoint == Icons.local_bar_rounded.codePoint ||
        iconCodePoint == Icons.shopping_basket_rounded.codePoint) {
      return 'Dining & Groceries';
    } else if (iconCodePoint == Icons.flight_takeoff_rounded.codePoint ||
        iconCodePoint == Icons.directions_car_rounded.codePoint ||
        iconCodePoint == Icons.hotel_rounded.codePoint ||
        iconCodePoint == Icons.directions_boat_rounded.codePoint ||
        iconCodePoint == Icons.map_rounded.codePoint) {
      return 'Travel';
    } else if (iconCodePoint == Icons.home_rounded.codePoint ||
        iconCodePoint == Icons.apartment_rounded.codePoint ||
        iconCodePoint == Icons.weekend_rounded.codePoint ||
        iconCodePoint == Icons.bolt_rounded.codePoint ||
        iconCodePoint == Icons.water_drop_rounded.codePoint) {
      return 'Housing & Utilities';
    } else if (iconCodePoint == Icons.celebration_rounded.codePoint ||
        iconCodePoint == Icons.movie_creation_rounded.codePoint ||
        iconCodePoint == Icons.sports_esports_rounded.codePoint ||
        iconCodePoint == Icons.sports_soccer_rounded.codePoint ||
        iconCodePoint == Icons.shopping_bag_rounded.codePoint) {
      return 'Life & Entertainment';
    } else {
      return 'General';
    }
  }

  void _showCategoryExpensesBottomSheet(
    BuildContext context,
    String categoryName,
    List<Expense> allExpenses,
    String? currentUserId,
  ) {
    final catExpenses = allExpenses.where((e) {
      final myShare = e.splitAmong[currentUserId] ?? 0.0;
      return myShare > 0 &&
          _getCategoryGroupName(e.categoryIconCodePoint) == categoryName;
    }).toList();

    // Sort by date descending
    catExpenses.sort((a, b) => b.date.compareTo(a.date));

    // Get group names map from groupProvider
    final groupState = ref.read(groupProvider);
    final groupNameMap = {for (final g in groupState.groups) g.groupId: g.name};

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Drag Handle Indicator
                SizedBox(height: 8.h),
                Container(
                  width: 38.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 16.h),
                // Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            categoryName,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                          ),
                          SizedBox(height: 4.h),
                          AppText(
                            '${catExpenses.length} ${catExpenses.length == 1 ? "expense" : "expenses"}',
                            fontSize: 12,
                            color: AppColors.white.withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10),
                Expanded(
                  child: catExpenses.isEmpty
                      ? Center(
                          child: AppText(
                            'No expenses found',
                            color: AppColors.white.withValues(alpha: 0.4),
                            fontSize: 14,
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.w, vertical: 8.h),
                          itemCount: catExpenses.length,
                          itemBuilder: (context, index) {
                            final exp = catExpenses[index];
                            final myShare =
                                exp.splitAmong[currentUserId] ?? 0.0;
                            final groupName =
                                groupNameMap[exp.groupId] ?? 'Unknown Group';
                            final formattedDate =
                                DateFormat('MMM d, yyyy').format(exp.date);

                            final cleanCurrency = exp.currency.contains(' ')
                                ? exp.currency.split(' ')[0]
                                : exp.currency;
                            final cleanCurrency3 = cleanCurrency.length >= 3
                                ? cleanCurrency.substring(0, 3)
                                : cleanCurrency;
                            final isPayer = exp.paidBy == currentUserId;

                            final Map<String, String> symbols = {
                              'USD': '\$',
                              'EUR': '€',
                              'GBP': '£',
                              'INR': '₹',
                              'PKR': 'Rs',
                              'JPY': '¥',
                              'AUD': 'A\$',
                              'CAD': 'C\$',
                              'CHF': 'CHF',
                              'CNY': '¥',
                              'SGD': 'S\$',
                              'NZD': 'NZ\$',
                            };
                            final symbol =
                                symbols[cleanCurrency3] ?? cleanCurrency3;

                            return Container(
                              margin: EdgeInsets.only(bottom: 12.h),
                              padding: EdgeInsets.all(14.w),
                              decoration: BoxDecoration(
                                color: AppColors.cardDark,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color:
                                      AppColors.white.withValues(alpha: 0.04),
                                  width: 1,
                                ),
                              ),
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
                                    child: Icon(
                                      IconData(exp.categoryIconCodePoint,
                                          fontFamily: 'MaterialIcons'),
                                      color: AppColors.white,
                                      size: 16.sp,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AppText(
                                          exp.title,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.white,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4.h),
                                        AppText(
                                          '$groupName • $formattedDate',
                                          fontSize: 11,
                                          color: AppColors.white
                                              .withValues(alpha: 0.4),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      AppText(
                                        '$cleanCurrency3 $symbol${myShare.toStringAsFixed(2)}',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: isPayer
                                            ? AppColors.success
                                            : AppColors.avatarRose,
                                      ),
                                      SizedBox(height: 4.h),
                                      AppText(
                                        'your share: $cleanCurrency3 $symbol${myShare.toStringAsFixed(2)}',
                                        fontSize: 10,
                                        color: AppColors.white
                                            .withValues(alpha: 0.35),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getSymbolForCurrency(String curCode) {
    final Map<String, String> symbols = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'INR': '₹',
      'PKR': 'Rs',
      'JPY': '¥',
      'AUD': 'A\$',
      'CAD': 'C\$',
      'CHF': 'CHF',
      'CNY': '¥',
      'SGD': 'S\$',
      'NZD': 'NZ\$',
    };
    return symbols[curCode.toUpperCase()] ?? curCode;
  }

  Map<String, dynamic> _calculateMetricsForCurrency(
    String curKey,
    List<Expense> expenses,
    String? currentUserId,
    String activePeriod,
    DateTime now,
  ) {
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

    final curSymbol = _getSymbolForCurrency(curKey);

    if (currentUserId == null) {
      return {
        'spent': '$curKey ${curSymbol}0',
        'received': '$curKey ${curSymbol}0',
        'net': '+$curKey ${curSymbol}0',
        'spentSubtitle': 'No change vs last period',
        'receivedSubtitle': 'No change vs last period',
        'netSubtitle': 'No change vs last period',
        'startDate': startDate,
      };
    }

    final filtered = expenses.where((e) {
      final clean = e.currency.trim().split(' ')[0];
      final code = clean.length >= 3 ? clean.substring(0, 3).toUpperCase() : clean.toUpperCase();
      final isSettlement = e.title == 'Settle Payment' ||
          e.categoryIconCodePoint == Icons.handshake_rounded.codePoint;
      return code == curKey && !isSettlement && e.date.isAfter(startDate);
    }).toList();

    final prevFiltered = expenses.where((e) {
      final clean = e.currency.trim().split(' ')[0];
      final code = clean.length >= 3 ? clean.substring(0, 3).toUpperCase() : clean.toUpperCase();
      final isSettlement = e.title == 'Settle Payment' ||
          e.categoryIconCodePoint == Icons.handshake_rounded.codePoint;
      return code == curKey && !isSettlement && e.date.isAfter(prevStartDate) && e.date.isBefore(startDate);
    }).toList();

    double owes = 0.0;
    double owedToYou = 0.0;
    for (final e in filtered) {
      final myShare = e.splitAmong[currentUserId] ?? 0.0;
      owes += myShare;
      if (e.paidBy == currentUserId) {
        owedToYou += e.amount - myShare;
      }
    }
    final net = owedToYou - owes;

    double prevOwes = 0.0;
    double prevOwedToYou = 0.0;
    for (final e in prevFiltered) {
      final myShare = e.splitAmong[currentUserId] ?? 0.0;
      prevOwes += myShare;
      if (e.paidBy == currentUserId) {
        prevOwedToYou += e.amount - myShare;
      }
    }
    final prevNet = prevOwedToYou - prevOwes;

    String getChangeStr(double current, double prev) {
      if (prev == 0) {
        return current > 0 ? '↑ 100% vs last period' : 'No change vs last period';
      }
      double diff = current - prev;
      double pct = (diff.abs() / prev) * 100;
      if (pct < 1) {
        return 'No change vs last period';
      }
      return '${diff > 0 ? '↑' : '↓'} ${pct.toStringAsFixed(0)}% vs last period';
    }

    final spentVal = '$curKey $curSymbol${owes.toStringAsFixed(0)}';
    final receivedVal = '$curKey $curSymbol${owedToYou.toStringAsFixed(0)}';
    final netVal = '${net >= 0 ? '+' : '-'}$curKey $curSymbol${net.abs().toStringAsFixed(0)}';

    final spentSubtitle = getChangeStr(owes, prevOwes);
    final receivedSubtitle = getChangeStr(owedToYou, prevOwedToYou);

    String netSubtitle;
    if (prevNet == 0) {
      netSubtitle = net != 0 ? 'Changed vs last period' : 'No change vs last period';
    } else {
      double netDiff = net - prevNet;
      double netPct = (netDiff.abs() / prevNet.abs()) * 100;
      if (netPct < 1) {
        netSubtitle = 'No change vs last period';
      } else {
        netSubtitle = '${netDiff > 0 ? '↑' : '↓'} ${netPct.toStringAsFixed(0)}% vs last period';
      }
    }

    return {
      'spent': spentVal,
      'received': receivedVal,
      'net': netVal,
      'spentSubtitle': spentSubtitle,
      'receivedSubtitle': receivedSubtitle,
      'netSubtitle': netSubtitle,
      'startDate': startDate,
    };
  }

  @override
  Widget build(BuildContext context) {
    final activePeriod = ref.watch(statsPeriodProvider);
    final selectedMonth = ref.watch(selectedStatsMonthProvider);
    final defaultCurrency = ref.watch(defaultCurrencyProvider);

    final expenseState = ref.watch(expenseProvider);
    final currentUserId = ref.watch(supabaseUserProvider)?.id;

    final defaultCurrencyCode =
        defaultCurrency.length >= 3 ? defaultCurrency.substring(0, 3).toUpperCase() : 'PKR';

    String getCurrencyCode(String currency) {
      final clean = currency.trim().split(' ')[0];
      return clean.length >= 3 ? clean.substring(0, 3).toUpperCase() : clean.toUpperCase();
    }

    // Detect all active currencies where user has activity (excluding settlements)
    final Map<String, List<Expense>> currencyExpensesMap = {};
    if (currentUserId != null) {
      for (final e in expenseState.expenses) {
        final isSettlement = e.title == 'Settle Payment' ||
            e.categoryIconCodePoint == Icons.handshake_rounded.codePoint;
        if (!isSettlement) {
          final isParticipant = e.paidBy == currentUserId || e.splitAmong.containsKey(currentUserId);
          if (isParticipant) {
            final code = getCurrencyCode(e.currency);
            currencyExpensesMap.putIfAbsent(code, () => []).add(e);
          }
        }
      }
    }

    if (currencyExpensesMap.isEmpty) {
      currencyExpensesMap[defaultCurrencyCode] = [];
    }

    final currencyKeys = currencyExpensesMap.keys.toList();
    currencyKeys.sort((a, b) {
      if (a == defaultCurrencyCode) return -1;
      if (b == defaultCurrencyCode) return 1;
      return a.compareTo(b);
    });

    if (_activeCurrencyIndex >= currencyKeys.length) {
      _activeCurrencyIndex = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }

    final activeCurrency = currencyKeys[_activeCurrencyIndex];
    final activeCurrencySymbol = _getSymbolForCurrency(activeCurrency);

    final now = DateTime.now();
    final activeMetrics = _calculateMetricsForCurrency(
      activeCurrency,
      expenseState.expenses,
      currentUserId,
      activePeriod,
      now,
    );

    final filterStartDate = activeMetrics['startDate'] as DateTime;

    // --- Dynamic Chart Period and Bars ---
    final List<Map<String, dynamic>> chartBarsData = [];

    if (activePeriod == '1M') {
      // Last 4 weeks
      for (int i = 3; i >= 0; i--) {
        final startOfWeek =
            now.subtract(Duration(days: i * 7 + now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        final label = 'Wk ${4 - i}';

        final weekExpenses = expenseState.expenses.where((e) {
          final expCurrency = getCurrencyCode(e.currency);
          final isSettlement = e.title == 'Settle Payment' ||
              e.categoryIconCodePoint == Icons.handshake_rounded.codePoint;
          return expCurrency == activeCurrency &&
              !isSettlement &&
              e.date
                  .isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
              e.date.isBefore(endOfWeek.add(const Duration(days: 1)));
        }).toList();

        double spent = 0.0;
        double received = 0.0;
        if (currentUserId != null) {
          for (final e in weekExpenses) {
            final myShare = e.splitAmong[currentUserId] ?? 0.0;
            if (myShare > 0) {
              spent += myShare;
            }
            if (e.paidBy == currentUserId) {
              received += e.amount - myShare;
            }
          }
        }
        chartBarsData.add({
          'label': label,
          'spent': spent,
          'received': received,
        });
      }
    } else {
      // Monthly bars
      int monthsCount = 6;
      if (activePeriod == '3M') monthsCount = 3;
      if (activePeriod == '1Y') monthsCount = 12;

      for (int i = monthsCount - 1; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final label = DateFormat('MMM').format(monthDate);

        final monthExpenses = expenseState.expenses.where((e) {
          final expCurrency = getCurrencyCode(e.currency);
          final isSettlement = e.title == 'Settle Payment' ||
              e.categoryIconCodePoint == Icons.handshake_rounded.codePoint;
          return expCurrency == activeCurrency &&
              !isSettlement &&
              e.date.year == monthDate.year &&
              e.date.month == monthDate.month;
        }).toList();

        double spent = 0.0;
        double received = 0.0;
        if (currentUserId != null) {
          for (final e in monthExpenses) {
            final myShare = e.splitAmong[currentUserId] ?? 0.0;
            if (myShare > 0) {
              spent += myShare;
            }
            if (e.paidBy == currentUserId) {
              received += e.amount - myShare;
            }
          }
        }
        chartBarsData.add({
          'label': label,
          'spent': spent,
          'received': received,
        });
      }
    }

    double maxMonthVal = 1.0; // avoid division by zero
    for (var data in chartBarsData) {
      final spent = data['spent'] as double;
      final received = data['received'] as double;
      if (spent > maxMonthVal) maxMonthVal = spent;
      if (received > maxMonthVal) maxMonthVal = received;
    }

    final double maxBarHeight = 120.h;
    List<Widget> barWidgets = chartBarsData.map((data) {
      final label = data['label'] as String;
      final spent = data['spent'] as double;
      final received = data['received'] as double;

      return _buildDualBar(
          label,
          (spent / maxMonthVal) * maxBarHeight,
          (received / maxMonthVal) * maxBarHeight,
          selectedMonth,
          showBadge: label == selectedMonth,
          badgeText:
              '$activeCurrency $activeCurrencySymbol${(spent + received).toStringAsFixed(0)}');
    }).toList();

    // --- Dynamic Categories ---
    final filteredCatExpenses = expenseState.expenses.where((e) {
      final expCurrency = getCurrencyCode(e.currency);
      final isSettlement = e.title == 'Settle Payment' ||
          e.categoryIconCodePoint == Icons.handshake_rounded.codePoint;
      return expCurrency == activeCurrency &&
          !isSettlement &&
          e.date.isAfter(filterStartDate);
    }).toList();

    Map<String, double> categoryTotals = {};
    double totalFilteredAmount = 0;

    for (var e in filteredCatExpenses) {
      final myShare = e.splitAmong[currentUserId] ?? 0.0;
      if (myShare <= 0) continue;

      final catName = _getCategoryGroupName(e.categoryIconCodePoint);
      categoryTotals[catName] = (categoryTotals[catName] ?? 0) + myShare;
      totalFilteredAmount += myShare;
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<Widget> categoryWidgets = [];
    if (sortedCategories.isEmpty) {
      categoryWidgets.add(Padding(
        padding: EdgeInsets.all(24.w),
        child: AppText('No expenses found for this period.',
            color: AppColors.white.withValues(alpha: 0.5)),
      ));
    } else {
      for (int i = 0; i < sortedCategories.length; i++) {
        final cat = sortedCategories[i];
        final pct =
            totalFilteredAmount > 0 ? (cat.value / totalFilteredAmount) : 0.0;

        IconData icon = Icons.category_rounded;
        Color iconColor = AppColors.catGeneral;
        if (cat.key.toLowerCase().contains('food') ||
            cat.key.toLowerCase().contains('din')) {
          icon = Icons.restaurant_rounded;
          iconColor = AppColors.catFood;
        } else if (cat.key.toLowerCase().contains('travel') ||
            cat.key.toLowerCase().contains('trans')) {
          icon = Icons.flight_takeoff_rounded;
          iconColor = AppColors.catTravel;
        } else if (cat.key.toLowerCase().contains('hous') ||
            cat.key.toLowerCase().contains('rent')) {
          icon = Icons.home_filled;
          iconColor = AppColors.catHousing;
        } else if (cat.key.toLowerCase().contains('util')) {
          icon = Icons.bolt_rounded;
          iconColor = AppColors.catUtilities;
        } else if (cat.key.toLowerCase().contains('entert')) {
          icon = Icons.theater_comedy_rounded;
          iconColor = AppColors.catEntertainment;
        }

        categoryWidgets.add(_buildCategoryRow(
          icon: icon,
          iconColor: iconColor,
          title: cat.key,
          amount:
              '$activeCurrency $activeCurrencySymbol${cat.value.toStringAsFixed(0)}',
          percentage: '${(pct * 100).toStringAsFixed(0)}%',
          progress: pct,
          themeColor: iconColor,
          onTap: () {
            _showCategoryExpensesBottomSheet(
                context, cat.key, filteredCatExpenses, currentUserId);
          },
        ));
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
                    // Currency Badge & Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          'Spending Summary',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white.withValues(alpha: 0.6),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.onboardingViolet.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: AppColors.onboardingViolet.withValues(alpha: 0.4),
                              width: 1.w,
                            ),
                          ),
                          child: AppText(
                            activeCurrency,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onboardingViolet,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    // Currency Pills Carousel Selector
                    if (currencyKeys.length > 1) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: currencyKeys.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final cur = entry.value;
                          final isActive = _activeCurrencyIndex == idx;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _activeCurrencyIndex = idx;
                                _pageController.animateToPage(
                                  idx,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: EdgeInsets.symmetric(horizontal: 4.w),
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.onboardingViolet
                                    : AppColors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: isActive
                                      ? AppColors.onboardingViolet
                                      : AppColors.white.withValues(alpha: 0.1),
                                  width: 1.w,
                                ),
                              ),
                              child: AppText(
                                cur,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 12.h),
                    ],

                    // Spending Summary Cards PageView
                    SizedBox(
                      height: 110.h,
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (idx) {
                          setState(() {
                            _activeCurrencyIndex = idx;
                          });
                        },
                        itemCount: currencyKeys.length,
                        itemBuilder: (context, pageIdx) {
                          final curKey = currencyKeys[pageIdx];
                          final metrics = _calculateMetricsForCurrency(
                            curKey,
                            expenseState.expenses,
                            currentUserId,
                            activePeriod,
                            now,
                          );

                          final spentVal = metrics['spent'] as String;
                          final receivedVal = metrics['received'] as String;
                          final netVal = metrics['net'] as String;
                          final spentSubtitle = metrics['spentSubtitle'] as String;
                          final receivedSubtitle = metrics['receivedSubtitle'] as String;
                          final netSubtitle = metrics['netSubtitle'] as String;

                          return Row(
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
                                  valueColor: netVal.contains('-$curKey')
                                      ? AppColors.avatarRose
                                      : AppColors.success,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    if (currencyKeys.length > 1) ...[
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          currencyKeys.length,
                          (index) => Container(
                            width: 6.w,
                            height: 6.w,
                            margin: EdgeInsets.symmetric(horizontal: 3.w),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _activeCurrencyIndex == index
                                  ? AppColors.onboardingViolet
                                  : AppColors.white.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                      ),
                    ],
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
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AppText(
              title,
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.white.withValues(alpha: 0.45),
            ),
          ),
          SizedBox(height: 4.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AppText(
              value,
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          SizedBox(height: 4.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AppText(
              subtitle,
              fontSize: 9.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.white.withValues(alpha: 0.3),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
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
