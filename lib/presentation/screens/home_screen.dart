import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/group_card.dart';
import '../../core/models/group.dart';
import '../../providers/group_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupState = ref.watch(groupProvider);
    final groups = groupState.groups;
    final isLoading = groupState.isLoading;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: AppColors.primaryMid,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryMid,
                AppColors.primaryAccent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          "Bill Splitter",
          style: TextStyle(
            color: AppColors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: IconButton(
              icon: Icon(
                Icons.settings_outlined,
                color: AppColors.white,
                size: 22.sp,
              ),
              onPressed: () => context.push('/settings'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : groups.isEmpty
                ? _buildEmptyState()
                : _buildGroupList(context, groups, ref),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/createGroup'),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: AppColors.textOnAccent),
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

  Widget _buildGroupList(
      BuildContext context, List<Group> groups, WidgetRef ref) {
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
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                final balance = ref.watch(groupBalanceProvider(group.groupId));

                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: GroupCard(
                    groupName: group.name,
                    memberCount: group.members.length,
                    balance: balance,
                    onTap: () {
                      context.go(
                          '${AppRouter.groupDetail}?groupId=${group.groupId}');
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
