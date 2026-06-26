import '../models/expense.dart';
import 'package:flutter/material.dart';

class FinancialCalculator {
  /// Calculate net balances for each member in a group based on all expenses
  static Map<String, double> calculateGroupBalances(List<Expense> groupExpenses) {
    final Map<String, double> balances = {};
    for (final expense in groupExpenses) {
      balances[expense.paidBy] = (balances[expense.paidBy] ?? 0) + expense.amount;
      for (final split in expense.splitAmong.entries) {
        final person = split.key;
        final amount = split.value;
        balances[person] = (balances[person] ?? 0) - amount;
      }
    }
    return balances;
  }

  /// Calculate global profile totals for a specific user across all groups
  static Map<String, double> calculateUserGlobalBalances(String userId, List<Expense> allExpenses) {
    double owes = 0.0;
    double owedToYou = 0.0;

    // Group expenses by groupId
    final Map<String, List<Expense>> groupExpensesMap = {};
    for (final e in allExpenses) {
      groupExpensesMap.putIfAbsent(e.groupId, () => []).add(e);
    }

    // Calculate per-group balance to find exact owes/owed amounts
    for (final groupExps in groupExpensesMap.values) {
      final balances = calculateGroupBalances(groupExps);
      final myBalance = balances[userId] ?? 0.0;
      if (myBalance < -0.01) {
        owes += myBalance.abs();
      } else if (myBalance > 0.01) {
        owedToYou += myBalance;
      }
    }

    return {
      'owes': owes,
      'owedToYou': owedToYou,
      'net': owedToYou - owes,
    };
  }

  /// Calculate net balances per currency for a specific user across all groups
  static Map<String, double> calculateUserGlobalBalancesPerCurrency(String userId, List<Expense> allExpenses) {
    final Map<String, double> netBalances = {};

    // Group expenses by groupId
    final Map<String, List<Expense>> groupExpensesMap = {};
    for (final e in allExpenses) {
      groupExpensesMap.putIfAbsent(e.groupId, () => []).add(e);
    }

    // Calculate per-group balance and add to the corresponding currency
    for (final entry in groupExpensesMap.entries) {
      final groupExps = entry.value;
      if (groupExps.isEmpty) continue;

      final currency = groupExps.first.currency;
      final balances = calculateGroupBalances(groupExps);
      final myBalance = balances[userId] ?? 0.0;

      if (myBalance.abs() > 0.01) {
        netBalances[currency] = (netBalances[currency] ?? 0.0) + myBalance;
      }
    }

    return netBalances;
  }

  /// Calculate total settled amount from all expenses
  static double calculateTotalSettled(List<Expense> expenses) {
    double totalSettled = 0.0;
    for (final exp in expenses) {
      if (exp.title == 'Settle Payment' || 
          exp.categoryIconCodePoint == Icons.handshake_rounded.codePoint) {
        totalSettled += exp.amount;
      }
    }
    return totalSettled;
  }

  /// Regenerate equal splits dynamically based on current amount and members
  static Map<String, double> generateEqualSplits(double totalAmount, List<String> memberIds) {
    if (memberIds.isEmpty) return {};
    final splitAmt = totalAmount / memberIds.length;
    return {for (final mId in memberIds) mId: splitAmt};
  }
}
