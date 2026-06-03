import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_button.dart';
import '../../providers/create_group_provider.dart';

class CreateGroupScreen extends ConsumerWidget {
  const CreateGroupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupState = ref.watch(createGroupProvider);
    final groupNotifier = ref.watch(createGroupProvider.notifier);
    final controllers = ref.watch(createGroupFormControllersProvider);

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryMid, AppColors.primaryAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const AppText(
          'Create Group',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.go(AppRouter.home),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText(
                'Create New Group',
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: 24.h),
              AppTextField(
                label: 'Group Name',
                hint: 'Enter group name',
                controller: controllers.groupName,
                prefixIcon: Icons.group,
              ),
              SizedBox(height: 16.h),
              AppTextField(
                label: 'Description',
                hint: 'Enter group description',
                controller: controllers.description,
                maxLines: 3,
              ),
              SizedBox(height: 24.h),
              const AppText(
                'Add Members',
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      hint: 'Enter member name',
                      controller: controllers.member,
                      prefixIcon: Icons.person,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  AppButton(
                    label: 'Add',
                    onTap: () {
                      groupNotifier.addMember(controllers.member.text.trim());
                      controllers.member.clear();
                    },
                    isOutlined: true,
                    width: 80.w,
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              if (groupState.members.isNotEmpty) ...[
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: groupState.members.map((member) {
                    return Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            member,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          GestureDetector(
                            onTap: () => groupNotifier.removeMember(member),
                            child: Icon(
                              Icons.close_rounded,
                              size: 15.sp,
                              color: AppColors.primaryAccent,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 24.h),
              ],
              SizedBox(height: 32.h),
              AppButton(
                label: 'Create Group',
                onTap: () {
                  groupNotifier.createGroup(
                    controllers.groupName.text,
                    groupState.members,
                    ref,
                    context,
                  );
                },
                isLoading: groupState.isLoading,
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }
}
