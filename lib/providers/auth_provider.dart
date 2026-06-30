import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/router/app_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/models/group.dart';
import '../../core/models/expense.dart';
import '../supabase_options.dart';

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
      final supabase = Supabase.instance.client;

      if (state.isLogin) {
        // Sign in
        await supabase.auth.signInWithPassword(
          email: email.trim(),
          password: password.trim(),
        );
      } else {
        // Sign up
        await supabase.auth.signUp(
          email: email.trim(),
          password: password.trim(),
        );
      }

      if (!context.mounted) return;
      AppSnackBar.showSuccess(
        context,
        state.isLogin
            ? 'Logged in successfully'
            : 'Account created successfully',
      );
      context.go('/');
    } on AuthException catch (e) {
      final errorMessage = e.message;
      state = state.copyWith(error: errorMessage);
      if (context.mounted) {
        AppSnackBar.showError(context, errorMessage);
      }
    } catch (e) {
      final errStr = e.toString();
      final msg = errStr.contains('SocketException') ||
              errStr.contains('ClientException')
          ? 'No internet connection. Please check your network and try again.'
          : 'An error occurred: $e';
      state = state.copyWith(error: msg);
      if (context.mounted) {
        AppSnackBar.showError(context, msg);
      }
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
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'equaly://reset-password',
      );
      if (!context.mounted) return;
      AppSnackBar.showSuccess(
        context,
        'Password reset email sent successfully. Please check your inbox.',
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRouter.login);
      }
    } on AuthException catch (e) {
      final errorMessage = e.message;
      state = state.copyWith(error: errorMessage);
      if (context.mounted) {
        AppSnackBar.showError(context, errorMessage);
      }
    } catch (e) {
      final errStr = e.toString();
      final msg = errStr.contains('SocketException') ||
              errStr.contains('ClientException')
          ? 'No internet connection. Please check your network and try again.'
          : 'An error occurred: $e';
      state = state.copyWith(error: msg);
      if (context.mounted) {
        AppSnackBar.showError(context, msg);
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    state = state.copyWith(isLoading: true);
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: SupabaseOptions.googleWebClientId,
      );

      try {
        await googleSignIn.signOut();
      } catch (_) {}

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw 'Could not retrieve ID Token from Google';
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } on AuthException catch (e) {
      state = state.copyWith(error: e.message);
      if (context.mounted) {
        AppSnackBar.showError(context, e.message);
      }
    } catch (e) {
      state = state.copyWith(error: 'Google sign-in failed: $e');
      if (context.mounted) {
        AppSnackBar.showError(context, 'Google Sign-In failed: $e');
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> signInWithApple(BuildContext context) async {
    state = state.copyWith(isLoading: true);
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw 'Could not retrieve ID Token from Apple';
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
      );
    } on AuthException catch (e) {
      state = state.copyWith(error: e.message);
      if (context.mounted) {
        AppSnackBar.showError(context, e.message);
      }
    } catch (e) {
      state = state.copyWith(error: 'Apple sign-in failed: $e');
      if (context.mounted) {
        AppSnackBar.showError(context, 'Apple Sign-In failed: $e');
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

// Auth Provider
final authProvider =
    StateNotifierProvider.autoDispose<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// Login password visibility toggle
final loginObscureProvider = StateProvider.autoDispose<bool>((ref) => true);

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

final formControllersProvider = Provider.autoDispose<FormControllers>((ref) {
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

final forgotPasswordControllersProvider =
    Provider.autoDispose<ForgotPasswordControllers>((ref) {
  final controllers = ForgotPasswordControllers(
    email: TextEditingController(),
  );
  ref.onDispose(() {
    controllers.dispose();
  });
  return controllers;
});

// Provider for the current Supabase user
final supabaseUserProvider = StateProvider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

// Listener for Supabase auth state changes to clear Hive data and reset states
final authStateListenerProvider = Provider<void>((ref) {
  final client = Supabase.instance.client;
  final subscription = client.auth.onAuthStateChange.listen((data) async {
    final event = data.event;
    final currentUser = client.auth.currentUser;
    debugPrint(
        '👤 Supabase Auth event: $event. Current user: ${currentUser?.email}');

    if (event == AuthChangeEvent.signedOut ||
        event == AuthChangeEvent.userDeleted) {
      debugPrint('👤 User is signed out. Clearing Hive boxes...');
      try {
        final groupsBox = await Hive.openBox<Group>('groups');
        await groupsBox.clear();
        final expensesBox = await Hive.openBox<Expense>('expenses');
        await expensesBox.clear();
        final settingsBox = await Hive.openBox('settings');
        await settingsBox.clear();
        final readNotificationsBox = await Hive.openBox('read_notifications');
        await readNotificationsBox.clear();
        debugPrint('🧹 Cache cleared successfully on signout!');
      } catch (e) {
        debugPrint('Error clearing Hive boxes on sign out: $e');
      }
      ref.read(supabaseUserProvider.notifier).state = null;
    } else {
      debugPrint(
          '👤 User is logged in. Updating user provider to ${currentUser?.email}...');
      ref.read(supabaseUserProvider.notifier).state = currentUser;
    }
  });

  ref.onDispose(() {
    subscription.cancel();
  });
});
