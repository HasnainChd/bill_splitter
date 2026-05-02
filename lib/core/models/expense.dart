import 'package:flutter/material.dart';

class Expense {
  final String expenseId;
  final String title;
  final double amount;
  final String currency;
  final String paidBy;
  final Map<String, double> splitAmong;
  final DateTime date;
  final String? notes;
  final String groupId;
  final IconData categoryIcon;

  const Expense({
    required this.expenseId,
    required this.title,
    required this.amount,
    required this.currency,
    required this.paidBy,
    required this.splitAmong,
    required this.date,
    this.notes,
    required this.groupId,
    required this.categoryIcon,
  });
}
