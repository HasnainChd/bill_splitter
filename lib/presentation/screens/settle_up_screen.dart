import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_button.dart';

class SettleUpScreen extends StatelessWidget {
  final String groupId;

  const SettleUpScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const AppText(
            'Settle Up',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          backgroundColor: Colors.blue,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () =>
                context.go('${AppRouter.groupDetail}?groupId=$groupId'),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                'Group ID: $groupId',
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
              SizedBox(height: 24.h),
              AppText(
                'Settle Up Balances',
                fontSize: 24.sp,
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: 16.h),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Outstanding Balances',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    SizedBox(height: 16.h),
                    _buildBalanceItem('John', 'You owe \$45.50', Colors.red),
                    SizedBox(height: 12.h),
                    _buildBalanceItem(
                        'Sarah', 'Owes you \$32.00', Colors.green),
                    SizedBox(height: 12.h),
                    _buildBalanceItem('Mike', 'You owe \$12.75', Colors.red),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Settlement Suggestions',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    SizedBox(height: 16.h),
                    _buildSettlementItem('Pay John \$45.50'),
                    SizedBox(height: 12.h),
                    _buildSettlementItem('Collect \$32.00 from Sarah'),
                    SizedBox(height: 12.h),
                    _buildSettlementItem('Pay Mike \$12.75'),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Recent Settlements',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    SizedBox(height: 16.h),
                    _buildRecentSettlement(
                        'Dinner split', 'Settled with John', '\$25.50'),
                    SizedBox(height: 12.h),
                    _buildRecentSettlement(
                        'Movie tickets', 'Settled with Sarah', '\$15.00'),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
              AppButton(
                label: 'Mark All as Settled',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settlement completed!')),
                  );
                },
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceItem(String name, String amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          name,
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
        ),
        AppText(
          amount,
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ],
    );
  }

  Widget _buildSettlementItem(String suggestion) {
    return AppCard(
      padding: EdgeInsets.all(12.w),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: Colors.amber[600],
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: AppText(
              suggestion,
              fontSize: 14.sp,
            ),
          ),
          AppButton(
            label: 'Settle',
            onTap: () {
              // Handle settlement
            },
            isOutlined: true,
            width: 80.w,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSettlement(
      String description, String settledWith, String amount) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                description,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
              SizedBox(height: 2.h),
              AppText(
                settledWith,
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
        AppText(
          amount,
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: Colors.green,
        ),
      ],
    );
  }
}
