import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;
        return Padding(
          padding: EdgeInsets.only(right: index < totalSteps - 1 ? 8.w : 0),
          child: Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.onboardingViolet
                  : AppColors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
        );
      }),
    );
  }
}
