import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/utils/app_snackbar.dart';

final bugCategoryProvider = StateProvider.autoDispose<String>((ref) => 'UI / Styling');
final bugSubmittingProvider = StateProvider.autoDispose<bool>((ref) => false);

final bugTitleControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final bugDescControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

class ReportBugScreen extends ConsumerWidget {
  const ReportBugScreen({super.key});

  final List<String> _categories = const [
    'UI / Styling',
    'Expense Calculation',
    'Group Management',
    'Settlement Flow',
    'Performance / Lag',
    'Other Bug',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = ref.watch(bugTitleControllerProvider);
    final descriptionController = ref.watch(bugDescControllerProvider);
    final category = ref.watch(bugCategoryProvider);
    final isSubmitting = ref.watch(bugSubmittingProvider);

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Column(
          children: [
            SizedBox(height: 30.h),
            // Header Row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              child: Row(
                children: [
                  Container(
                    width: 42.w,
                    height: 42.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1C38),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.chevron_left_rounded,
                        color: AppColors.white,
                        size: 24.sp,
                      ),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  const AppText(
                    'Report a Bug',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText(
                      'Found something broken? Let us know so we can fix it as soon as possible.',
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                    SizedBox(height: 24.h),

                    // Bug Title
                    AppTextField(
                      label: 'Bug Title',
                      hint: 'e.g. Group total is calculation is wrong',
                      controller: titleController,
                      prefix: Icon(
                        Icons.title_rounded,
                        color: AppColors.white.withValues(alpha: 0.35),
                        size: 18.sp,
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Category Dropdown Label
                    AppText(
                      'CATEGORY',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white.withValues(alpha: 0.45),
                      letterSpacing: 1.0,
                    ),
                    SizedBox(height: 8.h),
                    // Dropdown Container
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: category,
                          dropdownColor: AppColors.cardDark,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.white.withValues(alpha: 0.6),
                          ),
                          isExpanded: true,
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          items: _categories.map((String cat) {
                            return DropdownMenuItem<String>(
                              value: cat,
                              child: Text(cat),
                            );
                          }).toList(),
                          onChanged: (String? val) {
                            if (val != null) {
                              ref.read(bugCategoryProvider.notifier).state = val;
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Description textfield (multiline)
                    AppText(
                      'DESCRIPTION',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white.withValues(alpha: 0.45),
                      letterSpacing: 1.0,
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: TextField(
                        controller: descriptionController,
                        maxLines: 6,
                        style: const TextStyle(color: AppColors.white),
                        decoration: InputDecoration(
                          hintText: 'Describe how the bug occurred, steps to reproduce, or other useful context...',
                          hintStyle: TextStyle(
                            color: AppColors.white.withValues(alpha: 0.35),
                            fontSize: 13.sp,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16.w),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Attachment Section (Mocked picker)
                    _sectionLabel('ATTACH SCREENSHOT'),
                    SizedBox(height: 8.h),
                    GestureDetector(
                      onTap: () {
                        AppSnackBar.showInfo(context, 'Media picker simulated.');
                      },
                      child: Container(
                        width: double.infinity,
                        height: 90.h,
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: AppColors.onboardingViolet,
                              size: 28.sp,
                            ),
                            SizedBox(height: 6.h),
                            AppText(
                              'Tap to upload screenshot or log file',
                              fontSize: 11,
                              color: AppColors.white.withValues(alpha: 0.35),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 32.h),

                    // Submit Button
                    AppButton(
                      label: 'Submit Report',
                      isLoading: isSubmitting,
                      color: AppColors.onboardingViolet,
                      onTap: () {
                        final title = titleController.text;
                        final desc = descriptionController.text;

                        if (title.trim().isEmpty || desc.trim().isEmpty) {
                          AppSnackBar.showWarning(
                            context,
                            'Please fill in both the title and description.',
                          );
                          return;
                        }

                        ref.read(bugSubmittingProvider.notifier).state = true;

                        Future.delayed(const Duration(seconds: 1), () {
                          ref.read(bugSubmittingProvider.notifier).state = false;
                          titleController.clear();
                          descriptionController.clear();
                          if (context.mounted) {
                            AppSnackBar.showSuccess(
                              context,
                              'Thank you! Bug report submitted successfully.',
                            );
                            context.pop();
                          }
                        });
                      },
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

  Widget _sectionLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 2.h),
      child: AppText(
        text,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: AppColors.white.withValues(alpha: 0.45),
        letterSpacing: 1.2,
      ),
    );
  }
}
