import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../core/utils/app_snackbar.dart';
import '../core/utils/error_handler.dart';
import '../core/router/app_router.dart';
import '../core/services/analytics_service.dart';
import 'profile_provider.dart';

// Registration State
class RegisterState {
  final bool isLoading;
  final String? error;

  const RegisterState({
    this.isLoading = false,
    this.error,
  });

  RegisterState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return RegisterState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class RegisterNotifier extends StateNotifier<RegisterState> {
  final Ref _ref;
  final SupabaseClient _supabase = Supabase.instance.client;

  RegisterNotifier(this._ref) : super(const RegisterState());

  Future<void> signUp({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required bool termsAccepted,
    required BuildContext context,
    String? profilePhotoPath,
  }) async {
    if (fullName.trim().isEmpty ||
        username.trim().isEmpty ||
        email.trim().isEmpty ||
        password.trim().isEmpty) {
      AppSnackBar.showError(context, 'Please fill in all fields');
      return;
    }

    if (!termsAccepted) {
      AppSnackBar.showError(context, 'You must agree to the Terms of Service & Privacy Policy');
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      // Create user in Supabase Auth with metadata
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password.trim(),
        data: {
          'fullName': fullName.trim(),
          'username': username.trim(),
        },
      );

      final user = response.user;
      if (user != null) {
        AnalyticsService.logSignUp(method: 'email');
        AnalyticsService.setUserId(user.id);

        // Initialize/update the user profile using the profile provider
        try {
          await _ref.read(profileProvider.notifier).updateProfile(
                fullName: fullName.trim(),
                username: username.trim(),
                phone: '',
                bio: '',
                currency: 'USD (\$)',
                avatarFilePath: profilePhotoPath,
              );
        } catch (profileError) {
          debugPrint('Failed to initialize profile after signup: $profileError');
        }
      }

      if (!context.mounted) return;
      AppSnackBar.showSuccess(context, 'Account created successfully!');
      
      // Go to home screen
      context.go(AppRouter.home);
    } on AuthException catch (e) {
      final errorMessage = ErrorHandler.getUserFriendlyMessage(e);
      state = state.copyWith(error: errorMessage);
      AnalyticsService.logLoginFailed(errorReason: errorMessage);
      if (context.mounted) {
        AppSnackBar.showError(context, errorMessage);
      }
    } catch (e) {
      final msg = ErrorHandler.getUserFriendlyMessage(e);
      state = state.copyWith(error: msg);
      AnalyticsService.logLoginFailed(errorReason: msg);
      if (context.mounted) {
        AppSnackBar.showError(context, msg);
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

// Providers
final registerProvider = StateNotifierProvider.autoDispose<RegisterNotifier, RegisterState>((ref) {
  return RegisterNotifier(ref);
});

// Terms Acceptance Provider
final termsAcceptedProvider = StateProvider.autoDispose<bool>((ref) => false);

// Register Password Obscure Provider
final registerObscureProvider = StateProvider.autoDispose<bool>((ref) => true);

// Profile Photo Provider (contains profile picture details/path if selected)
final profilePhotoProvider = StateProvider.autoDispose<String?>((ref) => null);

// Password Strength Provider
final passwordStrengthProvider = Provider.autoDispose.family<double, String>((ref, password) {
  if (password.isEmpty) return 0.0;
  double score = 0.0;
  if (password.length >= 8) score += 0.25;
  if (password.contains(RegExp(r'[A-Z]'))) score += 0.25;
  if (password.contains(RegExp(r'[0-9]'))) score += 0.25;
  if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score += 0.25;
  return score;
});

// Register Form Controllers
class RegisterFormControllers {
  final TextEditingController fullName;
  final TextEditingController username;
  final TextEditingController email;
  final TextEditingController password;

  RegisterFormControllers({
    required this.fullName,
    required this.username,
    required this.email,
    required this.password,
  });

  void dispose() {
    fullName.dispose();
    username.dispose();
    email.dispose();
    password.dispose();
  }
}

final registerFormControllersProvider = Provider.autoDispose<RegisterFormControllers>((ref) {
  final controllers = RegisterFormControllers(
    fullName: TextEditingController(),
    username: TextEditingController(),
    email: TextEditingController(),
    password: TextEditingController(),
  );
  ref.onDispose(() {
    controllers.dispose();
  });
  return controllers;
});
