import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_button.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          'Settings',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            // Profile Card
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  AppAvatar(
                    name: 'John Doe',
                    size: 56.sp,
                  ),
                  SizedBox(height: 12.h),
                  const AppText(
                    'John Doe',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                  SizedBox(height: 4.h),
                  const AppText(
                    'john.doe@example.com',
                    fontSize: 14,
                    color: AppColors.white,
                  ),
                  SizedBox(height: 16.h),
                  AppButton(
                    label: 'Edit Profile',
                    onTap: () {},
                    isOutlined: true,
                    color: AppColors.white,
                    textColor: AppColors.white,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Premium Card
            AppCard(
              gradient: true,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, AppColors.accentDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.workspace_premium,
                          color: AppColors.textOnAccent,
                          size: 24.sp,
                        ),
                        SizedBox(width: 8.w),
                        const AppText(
                          'Upgrade to Premium',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textOnAccent,
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    const AppText(
                      'Get unlimited groups, advanced analytics, and more',
                      fontSize: 13,
                      color: AppColors.textOnAccent,
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      width: double.infinity,
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(12.r),
                          child: Center(
                            child: Text(
                              "Upgrade Now",
                              style: TextStyle(
                                color: AppColors.accentDark,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Account Settings
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    'ACCOUNT SETTINGS',
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                  SizedBox(height: 16.h),
                  _buildListTile(
                    icon: Icons.person,
                    title: 'Profile',
                    subtitle: 'Manage your profile information',
                  ),
                  _buildListTile(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Manage notification preferences',
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // App Settings
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    'APP SETTINGS',
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                  SizedBox(height: 16.h),
                  _buildListTile(
                    icon: Icons.palette,
                    title: 'Theme',
                    subtitle: 'Choose app theme',
                  ),
                  _buildListTile(
                    icon: Icons.language,
                    title: 'Language',
                    subtitle: 'Choose app language',
                  ),
                  _buildListTile(
                    icon: Icons.currency_exchange,
                    title: 'Currency',
                    subtitle: 'Set default currency',
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // Data & Storage
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    'DATA & STORAGE',
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                  SizedBox(height: 16.h),
                  _buildListTile(
                    icon: Icons.cloud_upload,
                    title: 'Backup',
                    subtitle: 'Backup your data',
                  ),
                  _buildListTile(
                    icon: Icons.cloud_download,
                    title: 'Restore',
                    subtitle: 'Restore from backup',
                  ),
                  _buildListTile(
                    icon: Icons.delete,
                    title: 'Clear Data',
                    subtitle: 'Clear all app data',
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // About
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    'ABOUT',
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                  SizedBox(height: 16.h),
                  _buildListTile(
                    icon: Icons.info,
                    title: 'About Bill Splitter',
                    subtitle: 'App version and information',
                  ),
                  _buildListTile(
                    icon: Icons.help,
                    title: 'Help & Support',
                    subtitle: 'Get help and support',
                  ),
                  _buildListTile(
                    icon: Icons.privacy_tip,
                    title: 'Privacy Policy',
                    subtitle: 'View privacy policy',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: ListTile(
        leading: Icon(icon, size: 24.sp, color: AppColors.primary),
        title: AppText(
          title,
          fontSize: 16,
        ),
        subtitle: AppText(
          subtitle,
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16.sp,
          color: AppColors.textHint,
        ),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
