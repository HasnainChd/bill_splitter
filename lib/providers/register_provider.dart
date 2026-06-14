import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../core/utils/app_snackbar.dart';
import '../core/router/app_router.dart';

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
  final SupabaseClient _supabase = Supabase.instance.client;

  RegisterNotifier() : super(const RegisterState());

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
        String? avatarUrl;

        // Upload profile photo to storage if provided
        if (profilePhotoPath != null && profilePhotoPath.isNotEmpty) {
          try {
            final file = File(profilePhotoPath);
            final fileExt = profilePhotoPath.split('.').last;
            final fileName = '${user.id}_avatar.$fileExt';

            await _supabase.storage.from('avatars').upload(
              fileName,
              file,
              fileOptions: const FileOptions(upsert: true),
            );

            avatarUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
          } catch (storageError) {
            debugPrint('Storage upload failed: $storageError');
          }
        }

        // The public profile row is automatically created in the 'users' table
        // by the database trigger on auth.users.
        // We only need to update the avatarUrl in the public.users table if we uploaded a photo.
        if (avatarUrl != null) {
          try {
            await _supabase.from('users').update({
              'avatarUrl': avatarUrl,
            }).eq('id', user.id);
          } catch (dbError) {
            debugPrint('Failed to update avatarUrl in database: $dbError');
          }
        }
      }

      if (!context.mounted) return;
      AppSnackBar.showSuccess(context, 'Account created successfully!');
      
      // Go to home screen
      context.go(AppRouter.home);
    } on AuthException catch (e) {
      final errorMessage = e.message;
      state = state.copyWith(error: errorMessage);
      if (context.mounted) {
        AppSnackBar.showError(context, errorMessage);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      if (context.mounted) {
        AppSnackBar.showError(context, 'An error occurred: $e');
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

// Providers
final registerProvider = StateNotifierProvider.autoDispose<RegisterNotifier, RegisterState>((ref) {
  return RegisterNotifier();
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
