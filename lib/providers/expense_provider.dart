import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/models/expense.dart';
import 'auth_provider.dart';

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
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _expensesSubscription;

  ExpenseNotifier() : super(const ExpenseState(expenses: [], isLoading: false)) {
    _loadExpensesFromCache();
    _setupRealtimeListeners();
  }

  void _setupRealtimeListeners() {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    _expensesSubscription = _supabase
        .channel('public:expenses')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'expenses',
          callback: (payload) {
            final newRecord = payload.newRecord;
            final oldRecord = payload.oldRecord;
            final groupId = (newRecord['group_id'] ?? oldRecord['group_id'])?.toString();
            if (groupId != null) {
              loadExpensesForGroup(groupId);
            }
          },
        );
    _expensesSubscription?.subscribe();
  }

  @override
  void dispose() {
    _expensesSubscription?.unsubscribe();
    super.dispose();
  }

  // Helper mapping from backend categories (Text) to icon code points
  static int _getIconCodePoint(String? categoryName) {
    switch (categoryName?.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded.codePoint;
      case 'travel':
        return Icons.flight_takeoff_rounded.codePoint;
      case 'rent':
        return Icons.home_rounded.codePoint;
      case 'shopping':
        return Icons.shopping_cart_rounded.codePoint;
      case 'bills':
        return Icons.bolt_rounded.codePoint;
      case 'fun':
        return Icons.theater_comedy_rounded.codePoint;
      default:
        return Icons.local_pizza_rounded.codePoint;
    }
  }

  // Helper mapping from icon code points to backend category names
  static String _getCategoryName(int codePoint) {
    if (codePoint == Icons.restaurant_rounded.codePoint) return 'Food';
    if (codePoint == Icons.flight_takeoff_rounded.codePoint) return 'Travel';
    if (codePoint == Icons.home_rounded.codePoint) return 'Rent';
    if (codePoint == Icons.shopping_cart_rounded.codePoint) return 'Shopping';
    if (codePoint == Icons.bolt_rounded.codePoint) return 'Bills';
    if (codePoint == Icons.theater_comedy_rounded.codePoint) return 'Fun';
    return 'Other';
  }

  // Load from local Hive cache on start
  Future<void> _loadExpensesFromCache() async {
    try {
      final box = await Hive.openBox<Expense>('expenses');
      state = state.copyWith(expenses: box.values.toList());
    } catch (e) {
      debugPrint('Failed to load expenses from Hive cache: $e');
    }
  }

  // Get expenses for a specific group from Supabase, caching them in Hive
  Future<void> loadExpensesForGroup(String groupId) async {
    try {
      state = state.copyWith(isLoading: true);
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        // Fallback: Load from Hive cache
        final box = await Hive.openBox<Expense>('expenses');
        state = state.copyWith(expenses: box.values.toList(), isLoading: false);
        return;
      }

      // Fetch expenses with joined splits
      final response = await _supabase
          .from('expenses')
          .select('*, splits(*)')
          .eq('group_id', groupId);

      final List<Expense> fetchedExpenses = [];
      final box = await Hive.openBox<Expense>('expenses');

      // Clear cached expenses for this group
      final keysToRemove = box.keys
          .where((k) => box.get(k)?.groupId == groupId)
          .toList();
      await box.deleteAll(keysToRemove);

      for (final row in response as List) {
        final List splitsList = row['splits'] ?? [];
        final Map<String, double> splitAmong = {};
        for (final split in splitsList) {
          splitAmong[split['user_id']?.toString() ?? ''] =
              (split['amount'] as num).toDouble();
        }

        final expense = Expense(
          expenseId: row['id']?.toString() ?? '',
          title: row['description'] as String? ?? '',
          amount: (row['amount'] as num).toDouble(),
          currency: row['currency'] as String? ?? 'PKR',
          paidBy: row['paid_by']?.toString() ?? '',
          splitAmong: splitAmong,
          date: row['date'] != null
              ? DateTime.parse(row['date'] as String)
              : DateTime.now(),
          notes: row['notes'] as String?,
          groupId: row['group_id']?.toString() ?? '',
          categoryIconCodePoint: _getIconCodePoint(row['category'] as String?),
        );

        fetchedExpenses.add(expense);
        await box.put(expense.expenseId, expense);
      }

      // Reload all cache to state
      state = state.copyWith(expenses: box.values.toList(), isLoading: false);
    } catch (e) {
      debugPrint('Error loading expenses for group $groupId: $e');
      try {
        final box = await Hive.openBox<Expense>('expenses');
        state = state.copyWith(
          expenses: box.values.toList(),
          isLoading: false,
          error: 'Offline mode: $e',
        );
      } catch (boxError) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load expenses: $e (Cache: $boxError)',
        );
      }
    }
  }

  // Add a new expense
  Future<void> addExpense({
    required String groupId,
    required String title,
    required double amount,
    required String currency,
    required String paidBy,
    required Map<String, double> splitAmong,
    required int categoryIconCodePoint,
    String? notes,
  }) async {
    try {
      state = state.copyWith(isLoading: true);
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // 1. Insert into expenses table
      final expenseData = await _supabase.from('expenses').insert({
        'group_id': groupId,
        'paid_by': paidBy,
        'amount': amount,
        'description': title,
        'category': _getCategoryName(categoryIconCodePoint),
        'date': DateTime.now().toIso8601String(),
      }).select().single();

      final String expenseId = expenseData['id'] as String;

      // 2. Insert splits into splits table
      final List<Map<String, dynamic>> splitRows = [];
      splitAmong.forEach((userId, splitAmount) {
        splitRows.add({
          'expense_id': expenseId,
          'user_id': userId,
          'amount': splitAmount,
        });
      });
      await _supabase.from('splits').insert(splitRows);

      // 3. Reload from remote
      await loadExpensesForGroup(groupId);
    } catch (e) {
      state = state.copyWith(error: 'Failed to add expense: $e', isLoading: false);
      rethrow;
    }
  }

  // Get expenses for a specific group (local helper)
  List<Expense> getExpensesForGroup(String groupId) {
    return state.expenses
        .where((expense) => expense.groupId == groupId)
        .toList();
  }

  // Update an expense
  Future<void> updateExpense(Expense updatedExpense) async {
    try {
      state = state.copyWith(isLoading: true);
      // 1. Update expenses table
      await _supabase.from('expenses').update({
        'amount': updatedExpense.amount,
        'description': updatedExpense.title,
        'category': _getCategoryName(updatedExpense.categoryIconCodePoint),
      }).eq('id', updatedExpense.expenseId);

      // 2. Delete and insert splits table
      await _supabase
          .from('splits')
          .delete()
          .eq('expense_id', updatedExpense.expenseId);

      final List<Map<String, dynamic>> splitRows = [];
      updatedExpense.splitAmong.forEach((userId, splitAmount) {
        splitRows.add({
          'expense_id': updatedExpense.expenseId,
          'user_id': userId,
          'amount': splitAmount,
        });
      });
      await _supabase.from('splits').insert(splitRows);

      // 3. Reload
      await loadExpensesForGroup(updatedExpense.groupId);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update expense: $e', isLoading: false);
      rethrow;
    }
  }

  // Delete an expense
  Future<void> deleteExpense(String groupId, String expenseId) async {
    try {
      state = state.copyWith(isLoading: true);
      await _supabase.from('expenses').delete().eq('id', expenseId);
      await loadExpensesForGroup(groupId);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete expense: $e', isLoading: false);
      rethrow;
    }
  }
}

// Provider
final expenseProvider =
    StateNotifierProvider<ExpenseNotifier, ExpenseState>((ref) {
  ref.watch(supabaseUserProvider);
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
