import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';

class IconSelector extends StatelessWidget {
  final IconData selectedIcon;
  final Function(IconData) onIconSelected;

  const IconSelector({
    super.key,
    required this.selectedIcon,
    required this.onIconSelected,
  });

  static const List<IconData> icons = [
    Icons.flight_takeoff_rounded,
    Icons.home_rounded,
    Icons.local_pizza_rounded,
    Icons.celebration_rounded,
    Icons.bolt_rounded,
    Icons.shopping_cart_rounded,
    Icons.cake_rounded,
    Icons.landscape_rounded,
    Icons.directions_boat_rounded,
    Icons.school_rounded,
    Icons.work_rounded,
    Icons.favorite_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      children: icons.map((icon) {
        final isSelected = icon.codePoint == selectedIcon.codePoint;
        return GestureDetector(
          onTap: () => onIconSelected(icon),
          child: Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.onboardingViolet.withValues(alpha: 0.15)
                  : AppColors.cardDark,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isSelected
                    ? AppColors.onboardingViolet
                    : AppColors.white.withValues(alpha: 0.08),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected
                  ? AppColors.onboardingViolet
                  : AppColors.white.withValues(alpha: 0.6),
              size: 24.sp,
            ),
          ),
        );
      }).toList(),
    );
  }
}
