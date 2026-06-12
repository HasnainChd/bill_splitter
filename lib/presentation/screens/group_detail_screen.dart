import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/expense.dart';
import '../../core/models/group.dart';
import '../../core/widgets/app_text.dart';
import '../../providers/firebase_group_provider.dart';
import '../../providers/firebase_expense_provider.dart';

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  // Mock member balance data — replaced with real data post-backend migration
  static const List<Map<String, dynamic>> _mockBalances = [
    {
      'initials': 'SC',
      'name': 'Sarah Chen',
      'sub': 'you owe',
      'amount': -168.0,
      'color': 0xFFEC4899
    },
    {
      'initials': 'MT',
      'name': 'Marcus Thompson',
      'sub': 'you owe',
      'amount': -169.0,
      'color': 0xFFF59E0B
    },
    {
      'initials': 'AJ',
      'name': 'You',
      'sub': 'owes you',
      'amount': 337.0,
      'color': 0xFF818CF8
    },
  ];

  static const Map<String, IconData> _categoryIcons = {
    'Food': Icons.restaurant_rounded,
    'Travel': Icons.flight_takeoff_rounded,
    'Rent': Icons.home_rounded,
    'Shopping': Icons.shopping_cart_rounded,
    'Bills': Icons.bolt_rounded,
    'Fun': Icons.theater_comedy_rounded,
    'default': Icons.receipt_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupState = ref.watch(firebaseGroupProvider);
    final expensesAsync = ref.watch(expensesForGroupProvider(groupId));
    final expenses = expensesAsync.value ?? [];

    final group = groupState.groups.firstWhere(
      (g) => g.groupId == groupId,
      orElse: () => Group(
        groupId: groupId,
        name: 'Friday Dinner Crew',
        members: const ['You', 'Sarah', 'Marcus', 'Priya'],
        currency: 'USD',
        createdAt: DateTime.now(),
      ),
    );

    final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Gradient Header ──
            SliverToBoxAdapter(
              child: _buildGradientHeader(context, group, expenses),
            ),

            // ── Members Section ──
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.h),
                    _sectionHeader('MEMBERS'),
                    SizedBox(height: 12.h),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        children: List.generate(_mockBalances.length, (i) {
                          final m = _mockBalances[i];
                          final isLast = i == _mockBalances.length - 1;
                          return Column(
                            children: [
                              _buildMemberRow(m),
                              if (!isLast)
                                Divider(
                                    color:
                                        AppColors.white.withValues(alpha: 0.04),
                                    height: 1,
                                    indent: 56.w),
                            ],
                          );
                        }),
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),

            // ── Expenses Section header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionHeader('EXPENSES'),
                    GestureDetector(
                      onTap: () => context.push('/addExpense', extra: group),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: AppColors.onboardingViolet
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.add,
                                color: AppColors.onboardingViolet, size: 14.sp),
                            SizedBox(width: 4.w),
                            const AppText(
                              'Add',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onboardingViolet,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Expense Items ──
            expenses.isEmpty
                ? SliverToBoxAdapter(child: _buildEmptyExpenses())
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 4.h),
                        child: _buildExpenseRow(context, expenses[i]),
                      ),
                      childCount: expenses.length,
                    ),
                  ),

            // ── Total Row ──
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 14.h),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText(
                            'Total group expenses',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white.withValues(alpha: 0.6),
                          ),
                          AppText(
                            '\$${totalExpenses.toStringAsFixed(2)}',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
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

  Widget _buildGradientHeader(
      BuildContext context, dynamic group, List<Expense> expenses) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.onboardingViolet, AppColors.primaryPurpleDarker],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: back + more
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.go('/'),
                    child: Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(Icons.chevron_left_rounded,
                          color: AppColors.white, size: 20.sp),
                    ),
                  ),
                  Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.more_horiz_rounded,
                        color: AppColors.white, size: 20.sp),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Group icon + name
              Row(
                children: [
                  Container(
                    width: 52.w,
                    height: 52.w,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(Icons.flight_takeoff_rounded,
                        color: AppColors.white, size: 26.sp),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          group?.name ?? 'Group',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                        AppText(
                          '${group?.members.length ?? 0} members · May 2024',
                          fontSize: 13,
                          color: AppColors.white.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            'Your balance in group',
                            fontSize: 12,
                            color: AppColors.white.withValues(alpha: 0.7),
                          ),
                          SizedBox(height: 6.h),
                          const AppText(
                            '+\$337.00',
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF10B981),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/settleUp', extra: groupId),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 18.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: const AppText(
                          'Settle Up',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.backgroundDark,
                          align: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberRow(Map<String, dynamic> m) {
    final double amount = m['amount'] as double;
    final bool isPositive = amount > 0;
    final color = Color(m['color'] as int);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: AppText(m['initials'] as String,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.white),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(m['name'] as String,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white),
                AppText(
                  '${m['sub']} \$${amount.abs().toStringAsFixed(0)}',
                  fontSize: 12,
                  color: isPositive
                      ? const Color(0xFF10B981)
                      : AppColors.balanceOwed,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: isPositive
                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                  : AppColors.balanceOwed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: AppText(
              isPositive
                  ? '+\$${amount.abs().toStringAsFixed(0)}'
                  : '-\$${amount.abs().toStringAsFixed(0)}',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color:
                  isPositive ? const Color(0xFF10B981) : AppColors.balanceOwed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseRow(BuildContext context, Expense expense) {
    final dateStr = DateFormat('MMM d').format(expense.date);
    final icon = expense.categoryIcon;
    final perPerson = expense.splitAmong.isNotEmpty
        ? expense.amount / expense.splitAmong.length
        : expense.amount;

    return Container(
      margin: EdgeInsets.only(bottom: 4.h),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.04)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: Container(
          width: 38.w,
          height: 38.w,
          decoration: BoxDecoration(
            color: AppColors.onboardingViolet.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: AppColors.onboardingViolet, size: 18.sp),
        ),
        title: AppText(expense.title,
            fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.white),
        subtitle: AppText(
          'Paid by ${expense.paidBy} · $dateStr',
          fontSize: 11,
          color: AppColors.white.withValues(alpha: 0.4),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AppText(
              '\$${expense.amount.toStringAsFixed(2)}',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
            AppText(
              '\$${perPerson.toStringAsFixed(0)}/person',
              fontSize: 11,
              color: AppColors.white.withValues(alpha: 0.4),
            ),
          ],
        ),
        onTap: () => context.push('/expenseDetail', extra: expense),
      ),
    );
  }

  Widget _buildEmptyExpenses() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 40.h),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long_rounded,
                size: 48.sp, color: AppColors.white.withValues(alpha: 0.2)),
            SizedBox(height: 12.h),
            const AppText('No expenses yet',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.white),
            SizedBox(height: 4.h),
            AppText('Tap + Add to record the first one',
                fontSize: 13, color: AppColors.white.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return AppText(
      text,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: AppColors.white.withValues(alpha: 0.4),
      letterSpacing: 1.2,
    );
  }
}
