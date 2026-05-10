import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/models/expense.dart';

// Expense State
class ExpenseState {
  final List<Expense> expenses;
  final bool isLoading;
  final String? error;

  const ExpenseState({
    required this.expenses,
    this.isLoading = false,
    this.error,
  });

  ExpenseState copyWith({
    List<Expense>? expenses,
    bool? isLoading,
    String? error,
  }) {
    return ExpenseState(
      expenses: expenses ?? this.expenses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseState &&
          runtimeType == other.runtimeType &&
          expenses == other.expenses &&
          isLoading == other.isLoading &&
          error == other.error;

  @override
  int get hashCode => expenses.hashCode ^ isLoading.hashCode ^ error.hashCode;
}

// Expense Notifier
class ExpenseNotifier extends StateNotifier<ExpenseState> {
  ExpenseNotifier() : super(const ExpenseState(expenses: [])) {
    _loadExpenses();
  }

  // Load expenses from Hive
  Future<void> _loadExpenses() async {
    try {
      final box = await Hive.openBox<Expense>('expenses');
      final expenses = box.values.toList();
      state = state.copyWith(expenses: expenses);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load expenses: $e');
    }
  }

  // Save expenses to Hive
  Future<void> _saveExpenses() async {
    try {
      final box = await Hive.openBox<Expense>('expenses');
      await box.clear();
      for (final expense in state.expenses) {
        await box.put(expense.expenseId, expense);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to save expenses: $e');
    }
  }

  // Add a new expense
  Future<void> addExpense(Expense expense) async {
    state = state.copyWith(
      expenses: [...state.expenses, expense],
    );
    await _saveExpenses();
  }

  // Get expenses for a specific group
  List<Expense> getExpensesForGroup(String groupId) {
    return state.expenses
        .where((expense) => expense.groupId == groupId)
        .toList();
  }

  // Update an expense
  Future<void> updateExpense(Expense updatedExpense) async {
    final updatedExpenses = state.expenses.map((expense) {
      return expense.expenseId == updatedExpense.expenseId
          ? updatedExpense
          : expense;
    }).toList();

    state = state.copyWith(expenses: updatedExpenses);
    await _saveExpenses();
  }

  // Delete an expense
  Future<void> deleteExpense(String expenseId) async {
    final updatedExpenses = state.expenses
        .where((expense) => expense.expenseId != expenseId)
        .toList();
    state = state.copyWith(expenses: updatedExpenses);
    await _saveExpenses();
  }

  // Calculate per-person balances for a group
  Map<String, double> calculateBalances(String groupId) {
    final groupExpenses = getExpensesForGroup(groupId);
    final Map<String, double> balances = {};

    for (final expense in groupExpenses) {
      // Add amount to payer
      balances[expense.paidBy] =
          (balances[expense.paidBy] ?? 0) + expense.amount;

      // Subtract split amounts from each person
      expense.splitAmong.forEach((person, amount) {
        balances[person] = (balances[person] ?? 0) - amount;
      });
    }

    return balances;
  }

  // Get total expenses for a group
  double getTotalExpenses(String groupId) {
    return getExpensesForGroup(groupId)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }
}

// Provider
final expenseProvider =
    StateNotifierProvider<ExpenseNotifier, ExpenseState>((ref) {
  return ExpenseNotifier();
});

// Family provider for expenses by group
final expensesForGroupProvider =
    Provider.family<List<Expense>, String>((ref, groupId) {
  final expenseState = ref.watch(expenseProvider);
  return expenseState.expenses
      .where((expense) => expense.groupId == groupId)
      .toList();
});

// Family provider for balances by group - REACTIVE
final balancesForGroupProvider =
    Provider.family<Map<String, double>, String>((ref, groupId) {
  // Use ref.watch so it reacts to changes
  final expenses = ref.watch(expensesForGroupProvider(groupId));
  final Map<String, double> balances = {};

  for (final expense in expenses) {
    // Person who paid gets credited
    balances[expense.paidBy] = (balances[expense.paidBy] ?? 0) + expense.amount;

    // Each person in split gets debited
    expense.splitAmong.forEach((person, amount) {
      balances[person] = (balances[person] ?? 0) - amount;
    });
  }

  return balances;
});
