// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

class AppRouter {
  static const String login = '/login';
  static const String home = '/';
  static const String createGroup = '/createGroup';
  static const String groupDetail = '/groupDetail';
  static const String addExpense = '/addExpense';
  static const String expenseDetail = '/expenseDetail';
  static const String settleUp = '/settleUp';
  static const String settings = '/settings';

  static final GoRouter router = GoRouter(
    initialLocation: login,
    redirect: (context, state) {
      final auth = FirebaseAuth.instance.currentUser;
      final isLoggingIn = state.matchedLocation == login;

      if (auth == null && !isLoggingIn) {
        return login;
      }

      if (auth != null && isLoggingIn) {
        return home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
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
          print(' Router: Building AddExpenseScreen');
          print(' Router: state.extra type: ${state.extra.runtimeType}');

          // Accept Group object via extra parameter
          if (state.extra == null) {
            print(' Router: No group object provided');
            return Scaffold(
              appBar: AppBar(
                title: const Text('Error'),
              ),
              body: const Center(
                child: Text('Invalid navigation: Group object not provided'),
              ),
            );
          }

          final group = state.extra as Group;
          print('👥 Router: Group received: ${group.name} (${group.groupId})');

          return AddExpenseScreen(group: group);
        },
      ),
      GoRoute(
        path: expenseDetail,
        name: 'expenseDetail',
        builder: (context, state) {
          final expense = state.extra as Expense?;
          if (expense == null) {
            // If no expense provided, redirect to home
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/');
            });
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
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
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Text('Page not found: ${state.uri.toString()}'),
      ),
    ),
  );
}
