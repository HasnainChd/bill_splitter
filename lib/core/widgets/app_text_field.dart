import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import 'app_text.dart';

class AppTextField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final String? label;
  // New: full Widget (used by login/register)
  final Widget? prefix;
  final Widget? suffix;
  // Legacy: IconData (used by add_expense, create_group, etc.)
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int? maxLines;
  final String? suffixText;
  final void Function(String)? onChanged;
  final bool readOnly;
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    super.key,
    required this.hint,
    required this.controller,
    this.label,
    this.prefix,
    this.suffix,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.suffixText,
    this.onChanged,
    this.readOnly = false,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    // Prefer explicit Widget prefix; fall back to wrapping the IconData
    final resolvedPrefix = prefix ??
        (prefixIcon != null
            ? (maxLines != null && maxLines! > 1
                ? Padding(
                    padding: EdgeInsets.only(top: 10.h),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          prefixIcon,
                          color: AppColors.textGrey.withValues(alpha: 0.5),
                          size: 18,
                        ),
                      ],
                    ),
                  )
                : Icon(
                    prefixIcon,
                    color: AppColors.textGrey.withValues(alpha: 0.5),
                    size: 18,
                  ))
            : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          AppText(
            label!.toUpperCase(),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textGrey.withValues(alpha: 0.6),
            letterSpacing: 1.0,
          ),
          SizedBox(height: 8.h),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          onChanged: onChanged,
          readOnly: readOnly,
          inputFormatters: inputFormatters,
          cursorColor: Colors.white,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
            color: readOnly ? Colors.white.withValues(alpha: 0.4) : Colors.white,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textGrey.withValues(alpha: 0.4),
            ),
            prefixIcon: resolvedPrefix,
            suffixIcon: suffix,
            suffixText: suffixText,
            suffixStyle: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: AppColors.cardDark,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(
                color: AppColors.onboardingViolet,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(
                color: AppColors.coralRed,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(
                color: AppColors.coralRed,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
