import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';

class UpdateDialogs {
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.devorastudios.equally';

  static Future<void> _launchStore() async {
    const String urlString = _playStoreUrl;
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  /// Shows the non-dismissable Force Update dialog
  static void showForceUpdate(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: AppColors.backgroundDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
              side: BorderSide(color: AppColors.white.withValues(alpha: 0.15), width: 1.5),
            ),
            contentPadding: EdgeInsets.all(24.w),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 28.r,
                  backgroundColor:
                      AppColors.onboardingViolet.withValues(alpha: 0.12),
                  child: Icon(
                    Icons.system_update,
                    color: AppColors.onboardingViolet,
                    size: 28.sp,
                  ),
                ),
                SizedBox(height: 20.h),
                const AppText(
                  'Update Required',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                  align: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                AppText(
                  'A new version of Equally is required to continue. Please update to the latest version.',
                  fontSize: 14,
                  color: AppColors.white.withValues(alpha: 0.6),
                  align: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: _launchStore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.onboardingViolet,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: const AppText(
                      'Update Now',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shows the dismissable Soft Update Suggestion dialog
  static void showSoftUpdate(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
            side: BorderSide(color: AppColors.white.withValues(alpha: 0.15), width: 1.5),
          ),
          contentPadding: EdgeInsets.all(24.w),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 28.r,
                backgroundColor: AppColors.success.withValues(alpha: 0.12),
                child: Icon(
                  Icons.new_releases_outlined,
                  color: AppColors.success,
                  size: 28.sp,
                  // Ensure correct alignment of standard releases icon
                ),
              ),
              SizedBox(height: 20.h),
              const AppText(
                'Update Available',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
                align: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              AppText(
                'A new version of Equally is available with improvements and bug fixes.',
                fontSize: 14,
                color: AppColors.white.withValues(alpha: 0.6),
                align: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48.h,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: AppColors.white.withValues(alpha: 0.1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: AppText(
                          'Later',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: SizedBox(
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _launchStore();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.onboardingViolet,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: const AppText(
                          'Update Now',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
