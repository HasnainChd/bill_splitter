import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/create_group_screen.dart';
import '../../presentation/screens/group_detail_screen.dart';
import '../../presentation/screens/add_expense_screen.dart';
import '../../presentation/screens/settle_up_screen.dart';
import '../../presentation/screens/settings_screen.dart';

class AppRouter {
  static const String home = '/home';
  static const String createGroup = '/create-group';
  static const String groupDetail = '/group-detail';
  static const String addExpense = '/add-expense';
  static const String settleUp = '/settle-up';
  static const String settings = '/settings';

  static GoRouter get router {
    return GoRouter(
      initialLocation: home,
      routes: [
        GoRoute(
          path: home,
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: createGroup,
          name: 'create-group',
          builder: (context, state) => const CreateGroupScreen(),
        ),
        GoRoute(
          path: groupDetail,
          name: 'group-detail',
          builder: (context, state) {
            final groupId = state.uri.queryParameters['groupId'];
            return GroupDetailScreen(groupId: groupId ?? '');
          },
        ),
        GoRoute(
          path: addExpense,
          name: 'add-expense',
          builder: (context, state) {
            final groupId = state.uri.queryParameters['groupId'];
            return AddExpenseScreen(groupId: groupId ?? '');
          },
        ),
        GoRoute(
          path: settleUp,
          name: 'settle-up',
          builder: (context, state) {
            final groupId = state.uri.queryParameters['groupId'];
            return SettleUpScreen(groupId: groupId ?? '');
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
}
