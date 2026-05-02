import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/group_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Mock data for demonstration - replace with actual data later
  final List<Map<String, dynamic>> _mockGroups = const [
    {
      'name': 'Roommates',
      'members': 4,
      'balance': 125.50,
    },
    {
      'name': 'Trip to Paris',
      'members': 6,
      'balance': -45.75,
    },
    {
      'name': 'Dinner Club',
      'members': 3,
      'balance': 0.00,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final hasGroups = _mockGroups.isNotEmpty;

    return SafeArea(
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
          title: const AppText(
            'Bill Splitter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: AppColors.white),
              onPressed: () => context.go(AppRouter.settings),
            ),
          ],
        ),
        body: hasGroups ? _buildGroupList() : _buildEmptyState(),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/createGroup'),
          backgroundColor: AppColors.accent,
          child: const Icon(Icons.add, color: AppColors.textOnAccent),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 80.sp,
            color: AppColors.accent,
          ),
          SizedBox(height: 24.h),
          const AppText(
            'No groups yet',
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: 8.h),
          const AppText(
            'Tap + to create your first group',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupList() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            'Your Groups',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: ListView.builder(
              itemCount: _mockGroups.length,
              itemBuilder: (context, index) {
                final group = _mockGroups[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: GroupCard(
                    groupName: group['name'] as String,
                    memberCount: group['members'] as int,
                    balance: group['balance'] as double,
                    onTap: () {
                      // Navigate to group detail with group ID
                      context.go(
                          '${AppRouter.groupDetail}?groupId=${group['name']}');
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
