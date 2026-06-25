// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/group.dart';
import '../../core/models/expense.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/create_group_screen.dart';
import '../../presentation/screens/group_detail_screen.dart';
import '../../presentation/screens/add_expense_screen.dart';
import '../../presentation/screens/expense_detail_screen.dart';
import '../../presentation/screens/settle_up_screen.dart';
import '../../presentation/screens/settings_screen.dart';
import '../../presentation/screens/login_screen.dart';
import '../../presentation/screens/register_screen.dart';
import '../../presentation/screens/forgot_password_screen.dart';
import '../../presentation/screens/activity_screen.dart';
import '../../presentation/screens/edit_profile_screen.dart';
import '../../presentation/screens/help_support_screen.dart';
import '../../presentation/screens/payment_methods_screen.dart';
import '../../presentation/screens/notifications_screen.dart';
import '../../presentation/screens/notification_settings_screen.dart';
import '../../presentation/screens/security_screen.dart';
import '../../presentation/screens/equaly_pro_screen.dart';
import '../../presentation/onboarding/onboarding_screen.dart';
import '../../presentation/onboarding/onboarding_walkthrough_screen.dart';
import '../../presentation/screens/privacy_settings_screen.dart';
import '../../presentation/screens/default_currency_screen.dart';
import '../../presentation/screens/language_screen.dart';
import '../../presentation/screens/date_format_screen.dart';
import '../../presentation/screens/two_factor_auth_screen.dart';
import '../../presentation/screens/change_password_screen.dart';
import '../../presentation/screens/report_bug_screen.dart';
import '../../presentation/screens/about_legal_screen.dart';
import '../../presentation/screens/lock_screen.dart';

import '../../presentation/screens/splash_screen.dart';

class AppRouter {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String walkthrough = '/walkthrough';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgotPassword';
  static const String home = '/';
  static const String createGroup = '/createGroup';
  static const String groupDetail = '/groupDetail';
  static const String addExpense = '/addExpense';
  static const String expenseDetail = '/expenseDetail';
  static const String settleUp = '/settleUp';
  static const String settings = '/settings';
  static const String activity = '/activity';
  static const String editProfile = '/editProfile';
  static const String helpSupport = '/helpSupport';
  static const String paymentMethods = '/paymentMethods';
  static const String notifications = '/notifications';
  static const String notificationSettings = '/notificationSettings';
  static const String security = '/security';
  static const String equalyPro = '/equalyPro';
  static const String privacySettings = '/privacySettings';
  static const String defaultCurrency = '/defaultCurrency';
  static const String language = '/language';
  static const String dateFormat = '/dateFormat';
  static const String twoFactorAuth = '/twoFactorAuth';
  static const String changePassword = '/changePassword';
  static const String reportBug = '/reportBug';
  static const String aboutLegal = '/aboutLegal';
  static const String lockScreen = '/lockScreen';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    redirect: (context, state) {
      final auth = Supabase.instance.client.auth.currentUser;
      final isSplash = state.matchedLocation == splash;
      final isLoggingIn = state.matchedLocation == login;
      final isRegistering = state.matchedLocation == register;
      final isForgotPassword = state.matchedLocation == forgotPassword;
      final isChangePassword = state.matchedLocation == changePassword;
      final isLockScreen = state.matchedLocation == lockScreen;
      final isOnboarding = state.matchedLocation == onboarding ||
          state.matchedLocation == walkthrough;

      // Always allow splash, onboarding, auth, change password, and lock screens
      if (isSplash || isOnboarding || isLoggingIn || isRegistering || isForgotPassword || isChangePassword || isLockScreen) {
        return null;
      }

      // Redirect unauthenticated users away from protected screens
      if (auth == null) {
        return login;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: lockScreen,
        name: 'lockScreen',
        builder: (context, state) {
          final nextRoute = state.uri.queryParameters['next'] ?? home;
          return LockScreen(nextRoute: nextRoute);
        },
      ),
      GoRoute(
        path: onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: walkthrough,
        name: 'walkthrough',
        builder: (context, state) => const OnboardingWalkthroughScreen(),
      ),
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: createGroup,
        name: 'createGroup',
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: groupDetail,
        name: 'groupDetail',
        builder: (context, state) {
          // Support both query parameter and extra parameter
          final groupId = state.uri.queryParameters['groupId'] ??
              (state.extra as String?) ??
              '';
          return GroupDetailScreen(groupId: groupId);
        },
      ),
      GoRoute(
        path: addExpense,
        name: 'addExpense',
        builder: (context, state) {
          if (state.extra is Map<String, dynamic>) {
            final map = state.extra as Map<String, dynamic>;
            final group = map['group'] as Group;
            final expense = map['expense'] as Expense?;
            final scannedAmount = map['scannedAmount'] as String?;
            final scannedTitle = map['scannedTitle'] as String?;
            final scannedImagePath = map['scannedImagePath'] as String?;
            return AddExpenseScreen(
              group: group,
              expenseToEdit: expense,
              scannedAmount: scannedAmount,
              scannedTitle: scannedTitle,
              scannedImagePath: scannedImagePath,
            );
          }
          final group = state.extra as Group?;
          if (group == null) {
            return const Scaffold(
              body: Center(child: Text('Group data required')),
            );
          }
          return AddExpenseScreen(group: group);
        },
      ),
      GoRoute(
        path: expenseDetail,
        name: 'expenseDetail',
        builder: (context, state) {
          final expense = state.extra as Expense?;
          if (expense == null) {
            return const Scaffold(
              body: Center(child: Text('Expense data required')),
            );
          }
          return ExpenseDetailScreen(expense: expense);
        },
      ),
      GoRoute(
        path: settleUp,
        name: 'settleUp',
        builder: (context, state) {
          // Support both query parameter and extra parameter
          final groupId = state.uri.queryParameters['groupId'] ??
              (state.extra as String?) ??
              '';
          return SettleUpScreen(groupId: groupId);
        },
      ),
      GoRoute(
        path: settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: activity,
        name: 'activity',
        builder: (context, state) => const ActivityScreen(),
      ),
      GoRoute(
        path: editProfile,
        name: 'editProfile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: helpSupport,
        name: 'helpSupport',
        builder: (context, state) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: paymentMethods,
        name: 'paymentMethods',
        builder: (context, state) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: notificationSettings,
        name: 'notificationSettings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: security,
        name: 'security',
        builder: (context, state) => const SecurityScreen(),
      ),
      GoRoute(
        path: equalyPro,
        name: 'equalyPro',
        builder: (context, state) => const EqualyProScreen(),
      ),
      GoRoute(
        path: privacySettings,
        name: 'privacySettings',
        builder: (context, state) => const PrivacySettingsScreen(),
      ),
      GoRoute(
        path: defaultCurrency,
        name: 'defaultCurrency',
        builder: (context, state) => const DefaultCurrencyScreen(),
      ),
      GoRoute(
        path: language,
        name: 'language',
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: dateFormat,
        name: 'dateFormat',
        builder: (context, state) => const DateFormatScreen(),
      ),
      GoRoute(
        path: twoFactorAuth,
        name: 'twoFactorAuth',
        builder: (context, state) => const TwoFactorAuthScreen(),
      ),
      GoRoute(
        path: changePassword,
        name: 'changePassword',
        builder: (context, state) {
          final isRecovery = state.uri.queryParameters['isRecovery'] == 'true';
          return ChangePasswordScreen(isRecovery: isRecovery);
        },
      ),
      GoRoute(
        path: reportBug,
        name: 'reportBug',
        builder: (context, state) => const ReportBugScreen(),
      ),
      GoRoute(
        path: aboutLegal,
        name: 'aboutLegal',
        builder: (context, state) => const AboutLegalScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Text('Page not found: ${state.uri.toString()}'),
      ),
    ),
  );
}
