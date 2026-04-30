import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_avatar.dart';

class GroupDetailScreen extends StatelessWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const AppText(
            'Group Details',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          backgroundColor: Colors.blue,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.go(AppRouter.home),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                'Group ID: $groupId',
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
              SizedBox(height: 24.h),
              AppText(
                'Group Details',
                fontSize: 24.sp,
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: 16.h),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Group Information',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        AppAvatar(
                          name: groupId,
                          size: 48.sp,
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                groupId,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              SizedBox(height: 4.h),
                              AppText(
                                '4 members',
                                fontSize: 14.sp,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    AppText(
                      'Group details and member information will be displayed here',
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Recent Expenses',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    SizedBox(height: 16.h),
                    AppText(
                      'Recent expenses will be listed here',
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                    SizedBox(height: 12.h),
                    _buildExpensePlaceholder(
                        'Dinner at Restaurant', '\$45.50', 'John'),
                    SizedBox(height: 8.h),
                    _buildExpensePlaceholder(
                        'Movie Tickets', '\$32.00', 'Sarah'),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: "add_expense",
              onPressed: () {
                context.go('${AppRouter.addExpense}?groupId=$groupId');
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add, color: Colors.white),
            ),
            SizedBox(height: 12.h),
            FloatingActionButton(
              heroTag: "settle_up",
              onPressed: () {
                context.go('${AppRouter.settleUp}?groupId=$groupId');
              },
              backgroundColor: Colors.green,
              child: const Icon(Icons.account_balance, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensePlaceholder(String title, String amount, String paidBy) {
    return AppCard(
      padding: EdgeInsets.all(12.w),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
                SizedBox(height: 4.h),
                AppText(
                  'Paid by $paidBy',
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
          AppText(
            amount,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }
}
