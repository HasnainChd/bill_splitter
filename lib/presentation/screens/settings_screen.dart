import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const AppText(
            'Settings',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          backgroundColor: Colors.blue,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.go(AppRouter.home),
          ),
        ),
        body: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    'Account Settings',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
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
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    'App Settings',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
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
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    'Data & Storage',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
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
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    'About',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
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
        leading: Icon(icon, size: 24.sp),
        title: AppText(
          title,
          fontSize: 16.sp,
        ),
        subtitle: AppText(
          subtitle,
          fontSize: 13.sp,
          color: Colors.grey[600],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16.sp,
          color: Colors.grey[400],
        ),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
