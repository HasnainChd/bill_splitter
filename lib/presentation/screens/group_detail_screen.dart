import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/group.dart';
import '../../core/models/expense.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/expense_tile.dart';
import '../../core/widgets/balance_row.dart';

class GroupDetailScreen extends StatelessWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  // Mock data for demonstration
  final List<Map<String, dynamic>> _mockExpenses = const [
    {
      'name': 'Dinner at Restaurant',
      'paidBy': 'John',
      'amount': 45.50,
      'date': 'Oct 28',
      'category': Icons.restaurant,
    },
    {
      'name': 'Movie Tickets',
      'paidBy': 'Sarah',
      'amount': 32.00,
      'date': 'Oct 27',
      'category': Icons.movie,
    },
    {
      'name': 'Gas Station',
      'paidBy': 'Mike',
      'amount': 25.00,
      'date': 'Oct 26',
      'category': Icons.local_gas_station,
    },
  ];

  final List<Map<String, dynamic>> _mockMembers = const [
    {'name': 'John', 'balance': 125.50},
    {'name': 'Sarah', 'balance': -45.75},
    {'name': 'Mike', 'balance': -79.75},
    {'name': 'You', 'balance': 0.00},
  ];

  // Move calculations outside build method to reduce main thread work
  double get _totalExpenses => _mockExpenses.fold<double>(
        0,
        (sum, expense) => sum + expense['amount'],
      );
  double get _yourBalance => 0.00; // Mock balance

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: SafeArea(
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
                  groupId,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textOnPrimary,
                ),
                AppText(
                  '4 members',
                  fontSize: 14,
                  color: AppColors.textOnPrimary.withValues(alpha: 0.7),
                ),
              ],
            ),
            leading: IconButton(
              icon:
                  const Icon(Icons.arrow_back, color: AppColors.textOnPrimary),
              onPressed: () => context.go('/'),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add,
                    color: AppColors.textOnPrimary),
                onPressed: () {
                  // Add member functionality
                },
              ),
              PopupMenuButton<String>(
                icon:
                    const Icon(Icons.more_vert, color: AppColors.textOnPrimary),
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
          body: Column(
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
                                '\$${_totalExpenses.toStringAsFixed(2)}',
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
                                '\$${_yourBalance.abs().toStringAsFixed(2)}',
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
                    _buildExpensesTab(context),
                    _buildBalancesTab(context),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // Create Group object from groupId for navigation
              final group = Group(
                groupId: groupId,
                name: groupId, // Using groupId as name for now
                members: const ['You', 'John', 'Sarah', 'Mike'],
                currency: 'USD',
                createdAt: DateTime.now(),
              );
              context.push('/addExpense', extra: group);
            },
            backgroundColor: AppColors.accent,
            child: const Icon(Icons.add, color: AppColors.textOnAccent),
          ),
        ),
      ),
    );
  }

  Widget _buildExpensesTab(BuildContext context) {
    if (_mockExpenses.isEmpty) {
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
      itemCount: _mockExpenses.length,
      itemBuilder: (context, index) {
        final expense = _mockExpenses[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: ExpenseTile(
            key: ValueKey('expense_$index'),
            expenseName: expense['name'] as String,
            paidByName: expense['paidBy'] as String,
            amount: expense['amount'] as double,
            date: expense['date'] as String,
            categoryIcon: expense['category'] as IconData,
            onTap: () {
              // Create proper Expense object from mock data
              final expenseObj = Expense(
                expenseId: 'expense_$index',
                title: expense['name'] as String,
                amount: expense['amount'] as double,
                currency: 'USD',
                paidBy: expense['paidBy'] as String,
                splitAmong: {
                  'You': (expense['amount'] as double) / 4,
                  'John': (expense['amount'] as double) / 4,
                  'Sarah': (expense['amount'] as double) / 4,
                  'Mike': (expense['amount'] as double) / 4,
                },
                date: DateTime.now(),
                notes: null,
                groupId: groupId,
                categoryIcon: expense['category'] as IconData,
              );
              context.push('/expenseDetail', extra: expenseObj);
            },
          ),
        );
      },
    );
  }

  Widget _buildBalancesTab(BuildContext context) {
    final hasUnsettledBalances =
        _mockMembers.any((member) => (member['balance'] as double) != 0);

    return ListView.builder(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 16.h,
        bottom: 16.h,
      ),
      itemCount: _mockMembers.length + (hasUnsettledBalances ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _mockMembers.length) {
          final member = _mockMembers[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: BalanceRow(
              memberName: member['name'] as String,
              balance: member['balance'] as double,
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
