import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RegisterNotifier() : super(const RegisterState());

  Future<void> signUp({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required bool termsAccepted,
    required BuildContext context,
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
      // Create user in Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      if (user != null) {
        // Create user doc in Firestore 'users' collection
        await _firestore.collection('users').doc(user.uid).set({
          'fullName': fullName.trim(),
          'username': username.trim(),
          'email': email.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      AppSnackBar.showSuccess(context, 'Account created successfully!');
      
      // Go to home screen
      context.go(AppRouter.home);
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Registration failed';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'Email already in use';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Password is too weak';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email address';
      }
      state = state.copyWith(error: errorMessage);
      AppSnackBar.showError(context, errorMessage);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      AppSnackBar.showError(context, 'An error occurred: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

// Providers
final registerProvider = StateNotifierProvider<RegisterNotifier, RegisterState>((ref) {
  return RegisterNotifier();
});

// Terms Acceptance Provider
final termsAcceptedProvider = StateProvider<bool>((ref) => false);

// Register Password Obscure Provider
final registerObscureProvider = StateProvider<bool>((ref) => true);

// Profile Photo Provider (contains profile picture details/path if selected)
final profilePhotoProvider = StateProvider<String?>((ref) => null);

// Password Strength Provider
final passwordStrengthProvider = Provider.family<double, String>((ref, password) {
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

final registerFormControllersProvider = Provider<RegisterFormControllers>((ref) {
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
