import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';

final localAuthProvider = Provider<LocalAuthentication>((ref) => LocalAuthentication());

final isAuthenticatingProvider = StateProvider<bool>((ref) => false);

class LockScreen extends ConsumerWidget {
  final String nextRoute;

  const LockScreen({super.key, required this.nextRoute});

  Future<void> _authenticate(BuildContext context, WidgetRef ref) async {
    final isAuthenticating = ref.read(isAuthenticatingProvider);
    if (isAuthenticating) return;

    ref.read(isAuthenticatingProvider.notifier).state = true;
    final auth = ref.read(localAuthProvider);

    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        // Device doesn't support biometrics, let them in
        if (context.mounted) {
          context.go(nextRoute);
        }
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to access Equaly',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (context.mounted) {
        if (didAuthenticate) {
          context.go(nextRoute);
        } else {
          ref.read(isAuthenticatingProvider.notifier).state = false;
        }
      }
    } on PlatformException catch (e) {
      debugPrint('Error authenticating: $e');
      if (context.mounted) {
        ref.read(isAuthenticatingProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticating = ref.watch(isAuthenticatingProvider);

    // Auto trigger authentication on first render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isAuthenticating) {
        _authenticate(context, ref);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 80.sp,
              color: AppColors.onboardingViolet,
            ),
            SizedBox(height: 24.h),
            const AppText(
              'App Locked',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
            SizedBox(height: 12.h),
            const AppText(
              'Use Face ID or Fingerprint to unlock',
              fontSize: 14,
              color: AppColors.textGrey,
            ),
            SizedBox(height: 48.h),
            if (!isAuthenticating)
              GestureDetector(
                onTap: () => _authenticate(context, ref),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                  decoration: BoxDecoration(
                    color: AppColors.onboardingViolet,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.onboardingViolet.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const AppText(
                    'Unlock Now',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              )
            else
              const CircularProgressIndicator(color: AppColors.onboardingViolet),
          ],
        ),
      ),
    );
  }
}
