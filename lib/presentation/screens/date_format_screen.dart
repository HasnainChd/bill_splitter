import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_card.dart';
import '../../providers/settings_provider.dart';

class DateFormatScreen extends ConsumerWidget {
  const DateFormatScreen({super.key});

  final List<Map<String, String>> _formats = const [
    {'format': 'MM/DD/YYYY', 'example': '12/31/2026', 'desc': 'Standard US Format'},
    {'format': 'DD/MM/YYYY', 'example': '31/12/2026', 'desc': 'European / Global Format'},
    {'format': 'YYYY-MM-DD', 'example': '2026-12-31', 'desc': 'ISO Standard Format'},
    {'format': 'DD-MM-YYYY', 'example': '31-12-2026', 'desc': 'Dash Separated format'},
    {'format': 'MMM DD, YYYY', 'example': 'Dec 31, 2026', 'desc': 'Text abbreviation format'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFormat = ref.watch(dateFormatProvider);

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
                    'Date Format',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Format List
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: _formats.length,
                itemBuilder: (context, index) {
                  final fmt = _formats[index];
                  final isSelected = activeFormat == fmt['format'];

                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: GestureDetector(
                      onTap: () {
                        ref.read(dateFormatProvider.notifier).state = fmt['format']!;
                      },
                      child: AppCard(
                        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
                        border: isSelected
                            ? Border.all(
                                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                width: 1.5,
                              )
                            : Border.all(
                                color: AppColors.white.withValues(alpha: 0.03),
                                width: 1,
                              ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    fmt['format']!,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.white,
                                  ),
                                  SizedBox(height: 4.h),
                                  AppText(
                                    'Example: ${fmt['example']}',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF10B981),
                                  ),
                                  SizedBox(height: 2.h),
                                  AppText(
                                    fmt['desc']!,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.white.withValues(alpha: 0.4),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: const Color(0xFF10B981),
                                size: 22.sp,
                              )
                            else
                              Icon(
                                Icons.circle_outlined,
                                color: AppColors.white.withValues(alpha: 0.15),
                                size: 22.sp,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
