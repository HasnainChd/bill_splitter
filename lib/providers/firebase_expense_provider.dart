import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/models/expense.dart';
import 'firebase_group_provider.dart';

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

// Firebase Expense Notifier
class FirebaseExpenseNotifier extends StateNotifier<FirebaseExpenseState> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebaseExpenseNotifier(this._firestore, this._auth)
      : super(const FirebaseExpenseState(expenses: [], isLoading: false));

  // Load expenses for a specific group from Firestore
  Future<void> loadExpensesForGroup(String groupId) async {
    try {
      state = state.copyWith(isLoading: true);

      final user = _auth.currentUser;
      if (user == null) {
        state = state.copyWith(isLoading: false, expenses: []);
        return;
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('groups')
          .doc(groupId)
          .collection('expenses')
          .orderBy('date', descending: true)
          .get();

      final expenses = snapshot.docs.map((doc) {
        final data = doc.data();
        return Expense(
          expenseId: doc.id,
          groupId: groupId,
          title: data['title'] as String,
          amount: (data['amount'] as num).toDouble(),
          currency: data['currency'] as String? ?? 'USD',
          paidBy: data['paidBy'] as String,
          splitAmong: Map<String, double>.from(data['splitAmong'] ?? {}),
          date: (data['date'] as Timestamp).toDate(),
          notes: data['notes'] as String?,
          categoryIconCodePoint: data['categoryIconCodePoint'] as int? ??
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

  // Add a new expense to Firestore
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
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('groups')
          .doc(groupId)
          .collection('expenses')
          .add({
        'title': title,
        'amount': amount,
        'currency': currency,
        'paidBy': paidBy,
        'splitAmong': splitAmong,
        'notes': notes,
        'categoryIconCodePoint': categoryIconCodePoint,
        'date': FieldValue.serverTimestamp(),
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

  // Update an expense in Firestore
  Future<void> updateExpense(Expense updatedExpense) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('groups')
          .doc(updatedExpense.groupId)
          .collection('expenses')
          .doc(updatedExpense.expenseId)
          .update({
        'title': updatedExpense.title,
        'amount': updatedExpense.amount,
        'currency': updatedExpense.currency,
        'paidBy': updatedExpense.paidBy,
        'splitAmong': updatedExpense.splitAmong,
        'notes': updatedExpense.notes,
        'categoryIconCodePoint': updatedExpense.categoryIconCodePoint,
      });

      await loadExpensesForGroup(updatedExpense.groupId);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update expense: $e');
      rethrow;
    }
  }

  // Delete an expense from Firestore
  Future<void> deleteExpense(String groupId, String expenseId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('groups')
          .doc(groupId)
          .collection('expenses')
          .doc(expenseId)
          .delete();

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

// Firebase Expense Provider
final firebaseExpenseProvider =
    StateNotifierProvider<FirebaseExpenseNotifier, FirebaseExpenseState>((ref) {
  return FirebaseExpenseNotifier(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

// Provider to get expenses for a specific group
final expensesForGroupProvider =
    StreamProvider.family<List<Expense>, String>((ref, groupId) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);

  if (auth.currentUser == null) {
    return Stream.value([]);
  }

  return firestore
      .collection('users')
      .doc(auth.currentUser!.uid)
      .collection('groups')
      .doc(groupId)
      .collection('expenses')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Expense(
        expenseId: doc.id,
        title: data['title'] ?? '',
        amount: (data['amount'] as num).toDouble(),
        currency: data['currency'] ?? 'USD',
        paidBy: data['paidBy'] ?? '',
        splitAmong: Map<String, double>.from(data['splitAmong'] ?? {}),
        date: (data['date'] as Timestamp).toDate(),
        notes: data['notes'],
        groupId: data['groupId'] ?? '',
        categoryIconCodePoint: data['categoryIconCodePoint'] ?? 0xe567,
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
