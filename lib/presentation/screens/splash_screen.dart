import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/router/app_router.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: FutureBuilder(
        future: Future.delayed(const Duration(milliseconds: 2500)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // Navigate based on auth status after the animation delay
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final auth = Supabase.instance.client.auth.currentUser;
              if (auth != null) {
                context.go(AppRouter.home);
              } else {
                context.go(AppRouter.onboarding);
              }
            });
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated logo
                Container(
                  width: 90.w,
                  height: 90.w,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primaryPurple,
                        AppColors.primaryPurpleLight
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(18.w),
                    child: Image.asset(
                      'assets/zap.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .scale(
                        delay: 150.ms,
                        duration: 800.ms,
                        curve: Curves.easeOutBack)
                    .shimmer(delay: 950.ms, duration: 1200.ms),
                SizedBox(height: 24.h),
                const AppText(
                  'Equaly',
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                  letterSpacing: 1.5,
                )
                    .animate()
                    .fadeIn(delay: 350.ms, duration: 800.ms)
                    .slideY(begin: 0.15, end: 0, curve: Curves.easeOutQuad),
                SizedBox(height: 10.h),
                const AppText(
                  'Split bills. Keep friends.',
                  fontSize: 15,
                  color: AppColors.textGrey,
                ).animate().fadeIn(delay: 600.ms, duration: 800.ms),
              ],
            ),
          );
        },
      ),
    );
  }
}
