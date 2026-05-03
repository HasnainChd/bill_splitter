import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_button.dart';
import '../../core/utils/app_snackbar.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _memberController = TextEditingController();
  final List<String> _members = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    _descriptionController.dispose();
    _memberController.dispose();
    super.dispose();
  }

  void _addMember() {
    final memberName = _memberController.text.trim();
    if (memberName.isNotEmpty && !_members.contains(memberName)) {
      setState(() {
        _members.add(memberName);
        _memberController.clear();
      });
    }
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      AppSnackBar.showError(context, 'Please enter a group name');
      return;
    }

    if (_members.isEmpty) {
      AppSnackBar.showError(context, 'Please add at least one member');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      AppSnackBar.showSuccess(context, 'Group created successfully');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
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
        body: SingleChildScrollView(
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
                controller: _groupNameController,
                prefixIcon: Icons.group,
              ),
              SizedBox(height: 16.h),
              AppTextField(
                label: 'Description',
                hint: 'Enter group description',
                controller: _descriptionController,
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
                      controller: _memberController,
                      prefixIcon: Icons.person,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  AppButton(
                    label: 'Add',
                    onTap: _addMember,
                    isOutlined: true,
                    width: 80.w,
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              if (_members.isNotEmpty) ...[
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: _members.map((member) {
                    return Chip(
                      label: Text(
                        member,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13.sp,
                        ),
                      ),
                      backgroundColor: AppColors.primaryLight,
                      side: BorderSide(color: AppColors.primary, width: 1),
                      deleteIcon: Icon(
                        Icons.close,
                        size: 16.sp,
                        color: AppColors.textSecondary,
                      ),
                      onDeleted: () {
                        setState(() {
                          _members.remove(member);
                        });
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 24.h),
              ],
              SizedBox(height: 32.h),
              AppButton(
                label: 'Create Group',
                onTap: _createGroup,
                isLoading: _isLoading,
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }
}
