import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/expense.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/create_group_screen.dart';
import '../../presentation/screens/group_detail_screen.dart';
import '../../presentation/screens/add_expense_screen.dart';
import '../../presentation/screens/expense_detail_screen.dart';
import '../../presentation/screens/settle_up_screen.dart';
import '../../presentation/screens/settings_screen.dart';

class AppRouter {
  static const String home = '/';
  static const String createGroup = '/createGroup';
  static const String groupDetail = '/groupDetail';
  static const String addExpense = '/addExpense';
  static const String expenseDetail = '/expenseDetail';
  static const String settleUp = '/settleUp';
  static const String settings = '/settings';

  static final GoRouter router = GoRouter(
    initialLocation: home,
    routes: [
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
          // Get groupId from query parameter
          final groupId = state.uri.queryParameters['groupId'];

          if (groupId == null || groupId.isEmpty) {
            // If no groupId provided, show error
            return Scaffold(
              appBar: AppBar(
                title: const Text('Error'),
              ),
              body: const Center(
                child: Text('Invalid navigation: Group ID not provided'),
              ),
            );
          }

          // We'll need to get the group from provider in the screen itself
          return AddExpenseScreen(groupId: groupId);
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
