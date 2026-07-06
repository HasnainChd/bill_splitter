import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:async';
import '../core/models/expense.dart';
import '../core/utils/date_helper.dart';
import 'auth_provider.dart';
import 'group_provider.dart';
import '../core/utils/financial_calculator.dart';

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

  ExpenseNotifier(Ref ref)
      : super(const ExpenseState(expenses: [], isLoading: false)) {
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
            final groupId =
                (newRecord['group_id'] ?? oldRecord['group_id'])?.toString();
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
      final keysToRemove =
          box.keys.where((k) => box.get(k)?.groupId == groupId).toList();
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
              ? parseUtcDateTime(row['date'] as String)
              : DateTime.now(),
          notes: row['notes'] as String?,
          groupId: row['group_id']?.toString() ?? '',
          categoryIconCodePoint: _getIconCodePoint(row['category'] as String?),
          splitType: row['split_type'] as String? ?? 'Equal',
          receiptUrl: row['receipt_url'] as String?,
          createdAt: row['created_at'] != null
              ? parseUtcDateTime(row['created_at'] as String)
              : null,
          updatedAt: row['updated_at'] != null
              ? parseUtcDateTime(row['updated_at'] as String)
              : null,
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

  // Get expenses for multiple groups from Supabase, caching them in Hive
  Future<void> loadExpensesForGroups(List<String> groupIds) async {
    if (groupIds.isEmpty) return;
    try {
      state = state.copyWith(isLoading: true);
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        final box = await Hive.openBox<Expense>('expenses');
        state = state.copyWith(expenses: box.values.toList(), isLoading: false);
        return;
      }

      // Fetch expenses with joined splits for all given groups
      final response = await _supabase
          .from('expenses')
          .select('*, splits(*)')
          .filter('group_id', 'in', '(${groupIds.join(",")})');

      final List<Expense> fetchedExpenses = [];
      final box = await Hive.openBox<Expense>('expenses');

      // Clear cached expenses for all these groups
      final keysToRemove = box.keys
          .where((k) => groupIds.contains(box.get(k)?.groupId))
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
              ? parseUtcDateTime(row['date'] as String)
              : DateTime.now(),
          notes: row['notes'] as String?,
          groupId: row['group_id']?.toString() ?? '',
          categoryIconCodePoint: _getIconCodePoint(row['category'] as String?),
          splitType: row['split_type'] as String? ?? 'Equal',
          receiptUrl: row['receipt_url'] as String?,
          createdAt: row['created_at'] != null
              ? parseUtcDateTime(row['created_at'] as String)
              : null,
          updatedAt: row['updated_at'] != null
              ? parseUtcDateTime(row['updated_at'] as String)
              : null,
        );

        fetchedExpenses.add(expense);
        await box.put(expense.expenseId, expense);
      }

      // Reload all cache to state
      state = state.copyWith(expenses: box.values.toList(), isLoading: false);
    } catch (e) {
      debugPrint('Error loading expenses for groups $groupIds: $e');
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
    required String splitType,
    DateTime? date,
    String? notes,
    String? receiptUrl,
  }) async {
    try {
      state = state.copyWith(isLoading: true);
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // 1. Insert into expenses table
      final expenseData = await _supabase
          .from('expenses')
          .insert({
            'group_id': groupId,
            'paid_by': paidBy,
            'amount': amount,
            'currency': currency,
            'description': title,
            'category': _getCategoryName(categoryIconCodePoint),
            'date': (date ?? DateTime.now()).toUtc().toIso8601String(),
            'split_type': splitType,
            'notes': notes,
            'receipt_url': receiptUrl,
          })
          .select()
          .single();

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
      final errorMsg = _getFriendlyErrorMsg(e);
      state = state.copyWith(
          error: 'Failed to add expense: $errorMsg', isLoading: false);
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
    final originalExpenses = List<Expense>.from(state.expenses);
    try {
      state = state.copyWith(isLoading: true);
      // 1. Optimistic UI Update & Reversal of Old Data
      final updatedExpensesList = state.expenses
          .map((e) =>
              e.expenseId == updatedExpense.expenseId ? updatedExpense : e)
          .toList();
      state = state.copyWith(expenses: updatedExpensesList, isLoading: true);

      // 2. Update expenses table
      final updateResponse = await _supabase
          .from('expenses')
          .update({
            'amount': updatedExpense.amount,
            'currency': updatedExpense.currency,
            'description': updatedExpense.title,
            'category': _getCategoryName(updatedExpense.categoryIconCodePoint),
            'paid_by': updatedExpense.paidBy,
            'split_type': updatedExpense.splitType,
            'date': updatedExpense.date.toUtc().toIso8601String(),
            'notes': updatedExpense.notes,
            'receipt_url': updatedExpense.receiptUrl,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', updatedExpense.expenseId)
          .select();

      if (updateResponse.isEmpty) {
        throw Exception(
            'You do not have permission to modify this expense (RLS blocked), or it no longer exists.');
      }

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

      // 4. Force strict reload
      await loadExpensesForGroup(updatedExpense.groupId);
      // Extra notify listeners implicitly happens when state changes, but we ensure loading is false.
      state = state.copyWith(isLoading: false);
    } catch (e) {
      final errorMsg = _getFriendlyErrorMsg(e);
      state = state.copyWith(
          expenses: originalExpenses,
          error: 'Failed to update expense: $errorMsg',
          isLoading: false);
      rethrow;
    }
  }

  // Delete an expense
  Future<void> deleteExpense(String groupId, String expenseId) async {
    final originalExpenses = List<Expense>.from(state.expenses);
    try {
      debugPrint(
          '🗑️ Attempting to delete expense with ID: $expenseId for group: $groupId');
      // Optimistic removal
      final updatedList =
          state.expenses.where((e) => e.expenseId != expenseId).toList();
      state = state.copyWith(expenses: updatedList, isLoading: true);

      final deleteResponse = await _supabase
          .from('expenses')
          .delete()
          .eq('id', expenseId)
          .select();
      debugPrint('🗑️ Delete response from Supabase: $deleteResponse');

      if (deleteResponse.isEmpty) {
        debugPrint(
            '⚠️ WARNING: Delete succeeded but returned 0 rows! RLS or ID mismatch?');
        throw Exception(
            'You do not have permission to delete this expense (RLS blocked), or it no longer exists.');
      }

      await loadExpensesForGroup(groupId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      final errorMsg = _getFriendlyErrorMsg(e);
      state = state.copyWith(
          expenses: originalExpenses,
          error: 'Failed to delete expense: $errorMsg',
          isLoading: false);
      rethrow;
    }
  }

  void clearExpenses() {
    state = const ExpenseState(expenses: [], isLoading: false);
  }

  // Upload receipt
  Future<String?> uploadReceipt(File imageFile) async {
    try {
      state = state.copyWith(isLoading: true);
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}_receipt.$fileExt';
      final path = 'receipts/$fileName';

      await _supabase.storage.from('receipts').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$fileExt'),
          );

      final imageUrl = _supabase.storage.from('receipts').getPublicUrl(path);
      state = state.copyWith(isLoading: false);
      return imageUrl;
    } catch (e) {
      final errorMsg = _getFriendlyErrorMsg(e);
      state = state.copyWith(
          error: 'Failed to upload receipt: $errorMsg', isLoading: false);
      rethrow;
    }
  }

  // Fetch a single expense by ID directly from Supabase, updates Hive cache and in-memory state
  Future<void> loadExpense(String expenseId) async {
    try {
      final response = await _supabase
          .from('expenses')
          .select('*, splits(*)')
          .eq('id', expenseId)
          .maybeSingle();

      final box = await Hive.openBox<Expense>('expenses');

      if (response == null) {
        // If not found in remote database, delete from local cache and in-memory state
        debugPrint('⚠️ Single expense $expenseId not found in Supabase. Removing from local cache.');
        await box.delete(expenseId);
        final updatedList = state.expenses
            .where((e) => e.expenseId != expenseId)
            .toList();
        state = state.copyWith(expenses: updatedList);
        return;
      }

      final List splitsList = response['splits'] ?? [];
      final Map<String, double> splitAmong = {};
      for (final split in splitsList) {
        splitAmong[split['user_id']?.toString() ?? ''] =
            (split['amount'] as num).toDouble();
      }

      final expense = Expense(
        expenseId: response['id']?.toString() ?? '',
        title: response['description'] as String? ?? '',
        amount: (response['amount'] as num).toDouble(),
        currency: response['currency'] as String? ?? 'PKR',
        paidBy: response['paid_by']?.toString() ?? '',
        splitAmong: splitAmong,
        date: response['date'] != null
            ? parseUtcDateTime(response['date'] as String)
            : DateTime.now(),
        notes: response['notes'] as String?,
        groupId: response['group_id']?.toString() ?? '',
        categoryIconCodePoint: _getIconCodePoint(response['category'] as String?),
        splitType: response['split_type'] as String? ?? 'Equal',
        receiptUrl: response['receipt_url'] as String?,
        createdAt: response['created_at'] != null
            ? parseUtcDateTime(response['created_at'] as String)
            : null,
        updatedAt: response['updated_at'] != null
            ? parseUtcDateTime(response['updated_at'] as String)
            : null,
      );

      await box.put(expense.expenseId, expense);

      // Update in-memory state: replace if exists, or append if new
      final list = List<Expense>.from(state.expenses);
      final idx = list.indexWhere((e) => e.expenseId == expenseId);
      if (idx != -1) {
        list[idx] = expense;
      } else {
        list.add(expense);
      }
      state = state.copyWith(expenses: list);
      debugPrint('✅ Single expense $expenseId successfully synced and updated in state.');
    } catch (e) {
      debugPrint('❌ Error loading single expense $expenseId: $e');
    }
  }

  // Helper for friendly error messages
  String _getFriendlyErrorMsg(dynamic e) {
    if (e is SocketException) {
      return 'Network unavailable. Please check your connection.';
    } else if (e is TimeoutException) {
      return 'Request timed out. The server might be slow or unreachable.';
    } else if (e is PostgrestException) {
      return 'Database error: \${e.message}';
    }
    return e.toString();
  }
}

// Provider
final expenseProvider =
    StateNotifierProvider<ExpenseNotifier, ExpenseState>((ref) {
  ref.watch(supabaseUserProvider);
  final notifier = ExpenseNotifier(ref);

  ref.listen<GroupState>(groupProvider, (previous, next) {
    if (!next.isLoading) {
      if (next.groups.isNotEmpty) {
        final groupIds = next.groups.map((g) => g.groupId).toList();
        notifier.loadExpensesForGroups(groupIds);
      } else {
        notifier.clearExpenses();
      }
    }
  }, fireImmediately: true);

  return notifier;
});

// Family provider for expenses by group
final expensesForGroupProvider =
    Provider.family<List<Expense>, String>((ref, groupId) {
  final expenseState = ref.watch(expenseProvider);
  return expenseState.expenses
      .where((expense) => expense.groupId == groupId)
      .toList();
});

// Family provider for actual expenses by group (excluding settlements)
final actualExpensesForGroupProvider =
    Provider.family<List<Expense>, String>((ref, groupId) {
  final expenses = ref.watch(expensesForGroupProvider(groupId));
  return expenses.where((e) {
    final isSettlement = e.title == 'Settle Payment' ||
        e.categoryIconCodePoint == Icons.handshake_rounded.codePoint;
    return !isSettlement;
  }).toList();
});

// Family provider for balances by group - REACTIVE
final balancesForGroupProvider =
    Provider.family<Map<String, double>, String>((ref, groupId) {
  final expenses = ref.watch(expensesForGroupProvider(groupId));
  return FinancialCalculator.calculateGroupBalances(expenses);
});
