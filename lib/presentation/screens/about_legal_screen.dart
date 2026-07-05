import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_card.dart';

class AboutLegalScreen extends StatelessWidget {
  const AboutLegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    'About & Legal',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    SizedBox(height: 20.h),
                    // App Logo Symbol
                    Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.onboardingViolet, AppColors.onboardingCyan],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22.r),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.payments_rounded,
                        color: AppColors.white,
                        size: 40.sp,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    const AppText(
                      'Equally',
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.white,
                    ),
                    SizedBox(height: 4.h),
                    AppText(
                      'Split bills. Settle easily.',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white.withValues(alpha: 0.45),
                    ),
                    SizedBox(height: 6.h),
                    AppText(
                      'v2.4.1 (Build 412)',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onboardingCyan,
                    ),
                    SizedBox(height: 32.h),

                    // Legal Items list
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildListTile(
                            context: context,
                            title: 'Terms of Service',
                            onTap: () => _showDialogText(context, 'Terms of Service', 'Placeholder for Equally Terms of Service agreement document content...'),
                          ),
                          _buildDivider(),
                          _buildListTile(
                            context: context,
                            title: 'Privacy Policy',
                            onTap: () => _showDialogText(context, 'Privacy Policy', 'Placeholder for Equally Privacy Policy details...'),
                          ),
                          _buildDivider(),
                          _buildListTile(
                            context: context,
                            title: 'Open Source Licenses',
                            onTap: () => _showDialogText(context, 'Open Source Licenses', 'License details for Flutter, Riverpod, GoRouter, Firebase, and other tools...'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Website & Social Links
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildLinkRow(
                            icon: Icons.language_rounded,
                            label: 'Official Website',
                            url: 'https://devorastudios.dev',
                          ),
                          _buildDivider(),
                          _buildLinkRow(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'Twitter / X',
                            url: '@equally_app',
                          ),
                          _buildDivider(),
                          _buildLinkRow(
                            icon: Icons.code_rounded,
                            label: 'GitHub Repository',
                            url: 'github.com/equally/bill_splitter',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40.h),

                    // Copyright
                    AppText(
                      '© 2026 Equally Technologies Inc.',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white.withValues(alpha: 0.25),
                    ),
                    AppText(
                      'All rights reserved.',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white.withValues(alpha: 0.2),
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

  Widget _buildListTile({
    required BuildContext context,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
      title: AppText(
        title,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.white.withValues(alpha: 0.2),
        size: 20.sp,
      ),
      onTap: onTap,
    );
  }

  Widget _buildLinkRow({
    required IconData icon,
    required String label,
    required String url,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
      leading: Container(
        width: 32.w,
        height: 32.w,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1C38),
          borderRadius: BorderRadius.circular(8.r),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: AppColors.onboardingCyan, size: 16.sp),
      ),
      title: AppText(
        label,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      ),
      trailing: AppText(
        url,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.white.withValues(alpha: 0.35),
      ),
      onTap: () {},
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withValues(alpha: 0.04),
      height: 1,
      thickness: 1,
    );
  }

  void _showDialogText(BuildContext context, String title, String text) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: AppText(
            title,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          content: SingleChildScrollView(
            child: AppText(
              text,
              fontSize: 13,
              color: AppColors.textGrey,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const AppText(
                'Close',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.onboardingViolet,
              ),
            ),
          ],
        );
      },
    );
  }
}
