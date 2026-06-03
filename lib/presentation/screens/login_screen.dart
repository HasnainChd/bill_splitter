import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_button.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.watch(authProvider.notifier);
    final controllers = ref.watch(formControllersProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40.h),
              const AppText(
                'Bill Splitter',
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
              SizedBox(height: 8.h),
              AppText(
                authState.isLogin ? 'Welcome back!' : 'Create an account',
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: 48.h),
              AppTextField(
                label: 'Email',
                hint: 'Enter your email',
                controller: controllers.email,
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16.h),
              AppTextField(
                label: 'Password',
                hint: 'Enter your password',
                controller: controllers.password,
                prefixIcon: Icons.lock,
                obscureText: true,
              ),
              SizedBox(height: 32.h),
              AppButton(
                label: authState.isLogin ? 'Sign In' : 'Sign Up',
                onTap: () {
                  authNotifier.handleAuth(
                    controllers.email.text,
                    controllers.password.text,
                    context,
                  );
                },
                isLoading: authState.isLoading,
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText(
                    authState.isLogin
                        ? "Don't have an account? "
                        : 'Already have an account? ',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  GestureDetector(
                    onTap: () {
                      authNotifier.toggleAuthMode();
                    },
                    child: AppText(
                      authState.isLogin ? 'Sign Up' : 'Sign In',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
