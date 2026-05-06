import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/expense.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/expense_tile.dart';
import '../../core/widgets/balance_row.dart';
import '../../providers/group_provider.dart';
import '../../providers/expense_provider.dart';
import 'package:intl/intl.dart';

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupNotifier = ref.read(groupProvider.notifier);
    final group = groupNotifier.getGroupById(groupId);
    final expenses = ref.watch(expensesForGroupProvider(groupId));
    final balances = ref.watch(balancesForGroupProvider(groupId));

    if (group == null) {
      return Scaffold(
        appBar: AppBar(
          title: const AppText('Group Not Found', color: AppColors.white),
        ),
        body: const Center(
          child: AppText('Group not found'),
        ),
      );
    }

    final totalExpenses = expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final yourBalance = balances['You'] ?? 0.0;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                group.name,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnPrimary,
              ),
              AppText(
                '${group.members.length} members',
                fontSize: 14,
                color: AppColors.textOnPrimary.withValues(alpha: 0.7),
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textOnPrimary),
            onPressed: () => context.go('/'),
          ),
          actions: [
            IconButton(
              icon:
                  const Icon(Icons.person_add, color: AppColors.textOnPrimary),
              onPressed: () {
                // Add member functionality
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textOnPrimary),
              onSelected: (value) {
                if (value == 'delete') {
                  // Delete group functionality
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete Group'),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Expenses'),
              Tab(text: 'Balances'),
            ],
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.white.withValues(alpha: 0.6),
            indicatorColor: AppColors.accent,
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Summary Card
              Padding(
                padding: EdgeInsets.all(16.w),
                child: AppCard(
                  gradient: true,
                  padding: EdgeInsets.all(16.w),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    padding: EdgeInsets.all(16.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AppText(
                                'Total Expenses',
                                fontSize: 14,
                                color: AppColors.white,
                              ),
                              SizedBox(height: 4.h),
                              AppText(
                                '\$${totalExpenses.toStringAsFixed(2)}',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40.h,
                          color: AppColors.white.withValues(alpha: 0.3),
                          margin: EdgeInsets.symmetric(horizontal: 16.w),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const AppText(
                                'Your Balance',
                                fontSize: 14,
                                color: AppColors.white,
                              ),
                              SizedBox(height: 4.h),
                              AppText(
                                '\$${yourBalance.abs().toStringAsFixed(2)}',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Tab Content
              Expanded(
                child: TabBarView(
                  children: [
                    _buildExpensesTab(context, expenses, group.name),
                    _buildBalancesTab(context, balances),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            context.push('/addExpense?groupId=${group.groupId}');
          },
          backgroundColor: AppColors.accent,
          child: const Icon(Icons.add, color: AppColors.textOnAccent),
        ),
      ),
    );
  }

  Widget _buildExpensesTab(
      BuildContext context, List<Expense> expenses, String groupName) {
    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 60.sp,
              color: AppColors.textHint,
            ),
            SizedBox(height: 16.h),
            const AppText(
              'No expenses yet',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            SizedBox(height: 8.h),
            const AppText(
              'Add your first expense to get started',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        final dateStr = DateFormat('MMM dd').format(expense.date);

        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: ExpenseTile(
            key: ValueKey(expense.expenseId),
            expenseName: expense.title,
            paidByName: expense.paidBy,
            amount: expense.amount,
            date: dateStr,
            categoryIcon: expense.categoryIcon,
            onTap: () {
              context.push('/expenseDetail', extra: expense);
            },
          ),
        );
      },
    );
  }

  Widget _buildBalancesTab(BuildContext context, Map<String, double> balances) {
    final hasUnsettledBalances =
        balances.values.any((balance) => balance.abs() > 0.01);

    final balanceEntries = balances.entries.toList();

    return ListView.builder(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 16.h,
        bottom: 16.h,
      ),
      itemCount: balanceEntries.length + (hasUnsettledBalances ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < balanceEntries.length) {
          final entry = balanceEntries[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: BalanceRow(
              memberName: entry.key,
              balance: entry.value,
            ),
          );
        } else {
          // Settle Up button at the end
          return Padding(
            padding: EdgeInsets.only(
              left: 0,
              right: 0,
              top: 16.h,
              bottom: 90.h,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/settleUp', extra: groupId),
                icon: Icon(
                  Icons.handshake_outlined,
                  size: 20.sp,
                  color: AppColors.white,
                ),
                label: Text(
                  "Settle Up",
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
