import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/group.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text.dart';
import '../../providers/group_provider.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({
    super.key,
    required this.inviteCode,
  });

  final String inviteCode;

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processInvite();
    });
  }

  Future<void> _processInvite() async {
    final currentUser = Supabase.instance.client.auth.currentUser;

    if (currentUser == null) {
      // User is not logged in: save invite code to SharedPreferences and redirect to login
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_invite_code', widget.inviteCode);
      } catch (e) {
        debugPrint('Error saving pending_invite_code: $e');
      }

      if (!mounted) return;
      AppSnackBar.showInfo(context, 'Please log in to join the group');
      context.go(AppRouter.login);
      return;
    }

    // User is logged in: try joining group by invite code
    try {
      final Group group = await ref
          .read(groupProvider.notifier)
          .joinGroupByInviteCode(widget.inviteCode);

      if (!mounted) return;
      AppSnackBar.showSuccess(
        context,
        'Successfully joined ${group.name}!',
      );
      context.go(AppRouter.groupDetail, extra: group.groupId);
    } catch (e) {
      if (!mounted) return;

      final errStr = e.toString();
      if (errStr.contains('already_member')) {
        AppSnackBar.showInfo(context, "You're already in this group");
        context.go(AppRouter.home);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'This invite link is invalid or has expired.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: _isLoading
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64.w,
                        height: 64.w,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppColors.onboardingViolet.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const CircularProgressIndicator(
                          color: AppColors.onboardingViolet,
                          strokeWidth: 3,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      const AppText(
                        'Joining Group...',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                      SizedBox(height: 8.h),
                      AppText(
                        'Please wait while we process your invite link',
                        fontSize: 14,
                        color: AppColors.textGrey.withValues(alpha: 0.7),
                        align: TextAlign.center,
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80.w,
                        height: 80.w,
                        decoration: BoxDecoration(
                          color: AppColors.coralRed.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.coralRed,
                          size: 44.sp,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      const AppText(
                        'Invalid Invite Link',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                      SizedBox(height: 12.h),
                      AppText(
                        _errorMessage ??
                            'This invite link is invalid or has expired.',
                        fontSize: 14,
                        color: AppColors.textGrey,
                        align: TextAlign.center,
                      ),
                      SizedBox(height: 32.h),
                      AppButton(
                        label: 'Go Home',
                        onTap: () => context.go(AppRouter.home),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
