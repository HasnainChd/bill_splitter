import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/expense.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/utils/app_dialog.dart';
import '../../core/utils/app_snackbar.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final Expense expense;

  const ExpenseDetailScreen({super.key, required this.expense});

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
            'Expense Detail',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textOnPrimary,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.textOnPrimary),
              onPressed: () => _showDeleteConfirmation(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero card
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                padding: EdgeInsets.all(24.w),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        expense.categoryIcon,
                        size: 48.sp,
                        color: AppColors.white,
                      ),
                      SizedBox(height: 16.h),
                      AppText(
                        expense.title,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                      SizedBox(height: 8.h),
                      AppText(
                        '${expense.currency} ${expense.amount.toStringAsFixed(2)}',
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                      SizedBox(height: 4.h),
                      AppText(
                        '${expense.currency} • ${_formatDate(expense.date)}',
                        fontSize: 13,
                        color: AppColors.white.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Paid By card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'PAID BY',
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        AppAvatar(name: expense.paidBy),
                        SizedBox(width: 8.w),
                        AppText(
                          expense.paidBy,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        const Spacer(),
                        AppText(
                          '${expense.currency} ${expense.amount.toStringAsFixed(2)}',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Split Details card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'SPLIT AMONG',
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                    SizedBox(height: 12.h),
                    ...expense.splitAmong.entries.map((entry) {
                      final index =
                          expense.splitAmong.keys.toList().indexOf(entry.key);
                      final isEven = index % 2 == 0;
                      return Container(
                        color: isEven
                            ? AppColors.surface
                            : AppColors.surfaceVariant,
                        padding: EdgeInsets.symmetric(
                            vertical: 8.h, horizontal: 8.w),
                        margin: EdgeInsets.only(bottom: 4.h),
                        child: Row(
                          children: [
                            AppAvatar(name: entry.key, size: 32.sp),
                            SizedBox(width: 8.w),
                            AppText(
                              entry.key,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                            const Spacer(),
                            AppText(
                              '${expense.currency} ${entry.value.toStringAsFixed(2)}',
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Notes card (only if notes exist)
              if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        'NOTES',
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        expense.notes!,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await AppDialog.showConfirm(
      context,
      title: 'Delete Expense',
      message: 'Are you sure you want to delete "${expense.title}"?',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDanger: true,
    );

    if (confirmed == true && context.mounted) {
      // TODO: Delete expense from provider
      AppSnackBar.showSuccess(context, 'Expense deleted');
      context.pop();
    }
  }
}
