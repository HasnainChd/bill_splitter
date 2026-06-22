import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bill_splitter/main.dart' as app;
import 'package:bill_splitter/providers/auth_provider.dart';
import 'package:bill_splitter/providers/expense_provider.dart';
import 'package:bill_splitter/providers/group_provider.dart';
import 'package:bill_splitter/core/widgets/app_text_field.dart';
import 'package:bill_splitter/core/router/app_router.dart' as app_router;
import 'package:bill_splitter/presentation/providers/tab_providers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('SplitFree End-to-End Regression Test Suite', () {
    testWidgets('Complete Regression User Journey',
        (WidgetTester tester) async {
      app.main();

      await tester.pumpAndSettle(const Duration(seconds: 4));

      // 1. App Launch & Login
      print('--- Phase 1: Launch & Login ---');

      // If we are already logged in, sign out first
      if (find.text('Total Others Owe You').evaluate().isNotEmpty ||
          find.text('Groups').evaluate().isNotEmpty) {
        print('Already logged in, signing out first to test login flow...');
        await tester.tap(find.byIcon(Icons.person_outline_rounded).evaluate().isNotEmpty 
          ? find.byIcon(Icons.person_outline_rounded).first 
          : find.byIcon(Icons.person_rounded).first);
        await tester.pumpAndSettle();
        // Assuming there is a Logout text or icon
        final logoutFinder = find.textContaining('Log Out');
        if (logoutFinder.evaluate().isNotEmpty) {
          await tester.tap(logoutFinder.first);
        } else {
          // Find log out icon
          await tester.tap(find.byIcon(Icons.logout_rounded).first);
        }
        await tester.pumpAndSettle(const Duration(seconds: 4));
      }

      // Check if we are at onboarding
      if (find.text('Welcome back').evaluate().isEmpty) {
        print('Navigating directly to Login screen via router...');
        app_router.AppRouter.router.go(app_router.AppRouter.login);
        await tester.pumpAndSettle(const Duration(seconds: 4));
      }

      expect(find.text('Welcome back'), findsOneWidget,
          reason: 'Login screen not visible');

      final textFields = find.byType(AppTextField);
      expect(textFields.evaluate().length, greaterThanOrEqualTo(2));

      await tester.enterText(textFields.first, 'devcodeinnovations@gmail.com');
      await tester.pumpAndSettle();
      await tester.enterText(textFields.at(1), 'Nain@123');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      final signInBtn = find.text('Sign In').last;
      await tester.ensureVisible(signInBtn);
      await tester.pumpAndSettle();
      await tester.tap(signInBtn);
      await tester
          .pumpAndSettle(const Duration(seconds: 8)); // Wait for network auth

      // Verify Home screen loaded
      expect(find.text('Total Others Owe You'), findsWidgets,
          reason: 'Failed to reach Home screen');

      // Helper to access providers
      ProviderContainer getContainer() {
        final element = tester.element(find.byType(MaterialApp).first);
        return ProviderScope.containerOf(element, listen: false);
      }

      final container = getContainer();

      // Ensure data loaded
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // 3. Prepare Test Group
      print('--- Phase 3: Prepare Test Group ---');
      container.read(homeTabIndexProvider.notifier).state = 1; // Groups tab
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final groupName = 'Regression Test Group';
      final groupFinder = find.text(groupName);

      if (groupFinder.evaluate().isEmpty) {
        // Create it via provider to avoid UI scrolling flakiness in setup
        final currentUserId = container.read(supabaseUserProvider)?.id;
        if (currentUserId != null) {
          await container.read(groupProvider.notifier).addGroup(
                name: groupName,
                members: [currentUserId],
                currency: 'PKR',
                iconCodePoint: 0xe4fc, // default group icon (groups)
                iconFontFamily: 'MaterialIcons',
              );
          await tester.pumpAndSettle(const Duration(seconds: 4));
        }
      }

      await tester.tap(find.text(groupName).first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 4. Create Expense
      print('--- Phase 4: Create Expense ---');
      // Capture initial totals
      final groupStateBefore = container.read(groupProvider);
      final expensesBefore = container.read(expenseProvider).expenses;

      // Navigate to Add Expense screen via router
      final group =
          groupStateBefore.groups.firstWhere((g) => g.name == groupName);
      app_router.AppRouter.router
          .push(app_router.AppRouter.addExpense, extra: group);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final expenseTitle = 'Regression Expense $timestamp';
      final expenseAmount = '250';

      await tester.enterText(find.byType(TextField).first, expenseAmount);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(AppTextField).first, expenseTitle);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      final addExpenseBtn = find.textContaining('Add Expense').last;
      await tester.dragUntilVisible(
        addExpenseBtn,
        find.byType(CustomScrollView).first,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      await tester.tap(addExpenseBtn, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 6));

      // 5. Verify Home Screen / Group Details
      print('--- Phase 5: Verify Creation ---');
      // We should be back at group details
      expect(find.text(expenseTitle), findsWidgets,
          reason: 'New expense title not found in list');

      // Verify Provider State
      final expensesAfter = container.read(expenseProvider).expenses;
      expect(expensesAfter.length, expensesBefore.length + 1,
          reason: 'Expense count did not increase');

      final createdExpense = expensesAfter.firstWhere((e) => e.title == expenseTitle);
      expect(createdExpense.amount, 250.0);

      // Return to home before testing tabs to ensure nav bar is visible and interactive
      app_router.AppRouter.router.go(app_router.AppRouter.home);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify Home Screen
      container.read(homeTabIndexProvider.notifier).state = 0;
      await tester.pumpAndSettle();

      // Verify Stats Screen
      container.read(homeTabIndexProvider.notifier).state = 3;
      await tester.pumpAndSettle();

      // Verify Profile Screen
      container.read(homeTabIndexProvider.notifier).state = 4;
      await tester.pumpAndSettle();

      // Return to Groups and open details again
      container.read(homeTabIndexProvider.notifier).state = 1;
      await tester.pumpAndSettle();
      await tester.tap(find.text(groupName).first);
      await tester.pumpAndSettle();

      // 6. Edit Expense
      print('--- Phase 6: Edit Expense ---');
      await tester.tap(find.text(expenseTitle).first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      // Edit it
      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final updatedAmount = '350';
      await tester.enterText(find.byType(TextField).first, updatedAmount);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      final updateExpenseBtn = find.textContaining('Update Expense').last;
      await tester.dragUntilVisible(
        updateExpenseBtn,
        find.byType(CustomScrollView).first,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      await tester.tap(updateExpenseBtn, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      expect(find.textContaining('350'), findsWidgets,
          reason: 'Updated amount not found in detail screen');

      // Verify Provider State updated
      final expensesAfterEdit = container.read(expenseProvider).expenses;
      final editedExpense = expensesAfterEdit
          .firstWhere((e) => e.expenseId == createdExpense.expenseId);
      expect(editedExpense.amount, 350.0,
          reason: 'Provider amount not updated');

      // 7. Delete Expense
      print('--- Phase 7: Delete Expense ---');
      await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Confirm dialog
      await tester.tap(find.text('Delete').first);
      await tester.pumpAndSettle(const Duration(seconds: 6));

      // Verify Provider State removed
      final expensesAfterDelete = container.read(expenseProvider).expenses;
      final isDeleted = expensesAfterDelete
          .where((e) => e.expenseId == createdExpense.expenseId)
          .isEmpty;
      expect(isDeleted, isTrue,
          reason: 'Expense still in provider state after delete');

      // Verify UI
      expect(find.text(expenseTitle), findsNothing,
          reason: 'Expense still visible in UI after delete');

      print('--- End-to-End Regression Test Suite Passed ---');
    });
  });
}
