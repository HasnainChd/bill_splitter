import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/router/app_router.dart';

// Auth State
class AuthState {
  final bool isLoading;
  final bool isLogin;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isLogin = true,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isLogin,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isLogin: isLogin ?? this.isLogin,
      error: error,
    );
  }
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  void toggleAuthMode() {
    state = state.copyWith(isLogin: !state.isLogin);
  }

  Future<void> handleAuth(
    String email,
    String password,
    BuildContext context,
  ) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      AppSnackBar.showError(context, 'Please fill in all fields');
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final auth = FirebaseAuth.instance;

      if (state.isLogin) {
        // Sign in
        await auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
      } else {
        // Sign up
        await auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
      }

      AppSnackBar.showSuccess(
        context,
        state.isLogin
            ? 'Logged in successfully'
            : 'Account created successfully',
      );
      context.go('/');
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Authentication failed';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for this email';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password provided';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Email already in use';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Password is too weak';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email address';
      }

      state = state.copyWith(error: errorMessage);
      AppSnackBar.showError(context, errorMessage);
    } catch (e) {
      state = state.copyWith(error: 'An error occurred: $e');
      AppSnackBar.showError(context, 'An error occurred: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> sendPasswordReset(
    String email,
    BuildContext context,
  ) async {
    if (email.trim().isEmpty) {
      AppSnackBar.showError(context, 'Please enter your email address');
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.trim(),
      );
      AppSnackBar.showSuccess(
        context,
        'Password reset email sent successfully. Please check your inbox.',
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRouter.login);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Password reset failed';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email address';
      }
      state = state.copyWith(error: errorMessage);
      AppSnackBar.showError(context, errorMessage);
    } catch (e) {
      state = state.copyWith(error: 'An error occurred: $e');
      AppSnackBar.showError(context, 'An error occurred: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

// Auth Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// Login password visibility toggle
final loginObscureProvider = StateProvider<bool>((ref) => true);

// Form Controllers Provider
class FormControllers {
  final TextEditingController email;
  final TextEditingController password;

  FormControllers({required this.email, required this.password});

  void dispose() {
    email.dispose();
    password.dispose();
  }
}

final formControllersProvider = Provider<FormControllers>((ref) {
  final controllers = FormControllers(
    email: TextEditingController(),
    password: TextEditingController(),
  );
  ref.onDispose(() {
    controllers.dispose();
  });
  return controllers;
});

class ForgotPasswordControllers {
  final TextEditingController email;

  ForgotPasswordControllers({required this.email});

  void dispose() {
    email.dispose();
  }
}

final forgotPasswordControllersProvider = Provider<ForgotPasswordControllers>((ref) {
  final controllers = ForgotPasswordControllers(
    email: TextEditingController(),
  );
  ref.onDispose(() {
    controllers.dispose();
  });
  return controllers;
});
