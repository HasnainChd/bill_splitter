import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/models/expense.dart';
import 'firebase_group_provider.dart';
import 'auth_provider.dart';


// Firebase Expense State
class FirebaseExpenseState {
  final List<Expense> expenses;
  final bool isLoading;
  final String? error;

  const FirebaseExpenseState({
    required this.expenses,
    this.isLoading = false,
    this.error,
  });

  FirebaseExpenseState copyWith({
    List<Expense>? expenses,
    bool? isLoading,
    String? error,
  }) {
    return FirebaseExpenseState(
      expenses: expenses ?? this.expenses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FirebaseExpenseState &&
          runtimeType == other.runtimeType &&
          expenses == other.expenses &&
          isLoading == other.isLoading &&
          error == other.error;

  @override
  int get hashCode => expenses.hashCode ^ isLoading.hashCode ^ error.hashCode;
}

// Firebase Expense Notifier (backed by Supabase!)
class FirebaseExpenseNotifier extends StateNotifier<FirebaseExpenseState> {
  final SupabaseClient _supabase;

  FirebaseExpenseNotifier(this._supabase)
      : super(const FirebaseExpenseState(expenses: [], isLoading: false));

  // Load expenses for a specific group from Supabase
  Future<void> loadExpensesForGroup(String groupId) async {
    try {
      state = state.copyWith(isLoading: true);

      final user = _supabase.auth.currentUser;
      if (user == null) {
        state = state.copyWith(isLoading: false, expenses: []);
        return;
      }

      final data = await _supabase
          .from('expenses')
          .select()
          .eq('groupId', groupId)
          .order('date', ascending: false);

      final expenses = (data as List).map((row) {
        return Expense(
          expenseId: row['id']?.toString() ?? '',
          groupId: groupId,
          title: row['title'] as String,
          amount: (row['amount'] as num).toDouble(),
          currency: row['currency'] as String? ?? 'USD',
          paidBy: row['paidBy'] as String,
          splitAmong: Map<String, double>.from(row['splitAmong'] ?? {}),
          date: row['date'] != null
              ? DateTime.parse(row['date'] as String)
              : DateTime.now(),
          notes: row['notes'] as String?,
          categoryIconCodePoint: row['categoryIconCodePoint'] as int? ??
              Icons.restaurant.codePoint,
        );
      }).toList();

      state = state.copyWith(expenses: expenses, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load expenses: $e',
      );
    }
  }

  // Add a new expense to Supabase
  Future<void> addExpense({
    required String groupId,
    required String title,
    required double amount,
    required String currency,
    required String paidBy,
    required Map<String, double> splitAmong,
    String? notes,
    int categoryIconCodePoint = 0xe567,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      await _supabase.from('expenses').insert({
        'groupId': groupId,
        'title': title,
        'amount': amount,
        'currency': currency,
        'paidBy': paidBy,
        'splitAmong': splitAmong,
        'notes': notes,
        'categoryIconCodePoint': categoryIconCodePoint,
        'date': DateTime.now().toIso8601String(),
      });

      // Reload expenses for the group
      await loadExpensesForGroup(groupId);
    } catch (e) {
      state = state.copyWith(error: 'Failed to add expense: $e');
      rethrow;
    }
  }

  // Get expenses for a specific group
  List<Expense> getExpensesForGroup(String groupId) {
    return state.expenses
        .where((expense) => expense.groupId == groupId)
        .toList();
  }

  // Update an expense in Supabase
  Future<void> updateExpense(Expense updatedExpense) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      await _supabase.from('expenses').update({
        'title': updatedExpense.title,
        'amount': updatedExpense.amount,
        'currency': updatedExpense.currency,
        'paidBy': updatedExpense.paidBy,
        'splitAmong': updatedExpense.splitAmong,
        'notes': updatedExpense.notes,
        'categoryIconCodePoint': updatedExpense.categoryIconCodePoint,
      }).eq('id', updatedExpense.expenseId);

      await loadExpensesForGroup(updatedExpense.groupId);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update expense: $e');
      rethrow;
    }
  }

  // Delete an expense from Supabase
  Future<void> deleteExpense(String groupId, String expenseId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      await _supabase
          .from('expenses')
          .delete()
          .eq('id', expenseId);

      await loadExpensesForGroup(groupId);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete expense: $e');
      rethrow;
    }
  }

  // Calculate balances for a group
  Map<String, double> calculateBalances(String groupId) {
    final groupExpenses = getExpensesForGroup(groupId);
    final Map<String, double> balances = {};

    for (final expense in groupExpenses) {
      final amountPerPerson = expense.amount / expense.splitAmong.keys.length;

      // Add to payer's balance (they paid, so they're owed)
      balances[expense.paidBy] =
          (balances[expense.paidBy] ?? 0) + expense.amount;

      // Subtract from each person who split (they owe)
      for (final person in expense.splitAmong.keys) {
        balances[person] = (balances[person] ?? 0) - amountPerPerson;
      }
    }

    return balances;
  }
}

// Firebase Expense Provider (now Supabase backed)
final firebaseExpenseProvider =
    StateNotifierProvider<FirebaseExpenseNotifier, FirebaseExpenseState>((ref) {
  ref.watch(supabaseUserProvider);
  return FirebaseExpenseNotifier(
    ref.watch(supabaseClientProvider),
  );
});


// Provider to get expenses for a specific group
final expensesForGroupProvider =
    StreamProvider.family<List<Expense>, String>((ref, groupId) {
  final user = ref.watch(supabaseUserProvider);
  final supabase = ref.watch(supabaseClientProvider);

  if (user == null) {
    return Stream.value([]);
  }


  return supabase
      .from('expenses')
      .stream(primaryKey: ['id'])
      .eq('groupId', groupId)
      .order('date', ascending: false)
      .map((snapshot) {
    return snapshot.map((row) {
      return Expense(
        expenseId: row['id']?.toString() ?? '',
        title: row['title'] as String,
        amount: (row['amount'] as num).toDouble(),
        currency: row['currency'] as String? ?? 'USD',
        paidBy: row['paidBy'] as String,
        splitAmong: Map<String, double>.from(row['splitAmong'] ?? {}),
        date: row['date'] != null
            ? DateTime.parse(row['date'] as String)
            : DateTime.now(),
        notes: row['notes'] as String?,
        groupId: row['groupId'] as String,
        categoryIconCodePoint: row['categoryIconCodePoint'] as int? ??
            Icons.restaurant.codePoint,
      );
    }).toList();
  });
});

// Provider to calculate balances for a group
final balancesForGroupProvider =
    Provider.family<Map<String, double>, String>((ref, groupId) {
  final expensesAsync = ref.watch(expensesForGroupProvider(groupId));
  final expenses = expensesAsync.value ?? [];
  final Map<String, double> balances = {};

  for (final expense in expenses) {
    final amountPerPerson = expense.amount / expense.splitAmong.keys.length;

    // Add to payer's balance (they paid, so they're owed)
    balances[expense.paidBy] = (balances[expense.paidBy] ?? 0) + expense.amount;

    // Subtract from each person who split (they owe)
    for (final person in expense.splitAmong.keys) {
      balances[person] = (balances[person] ?? 0) - amountPerPerson;
    }
  }

  return balances;
});
