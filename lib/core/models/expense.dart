import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 1)
class Expense {
  @HiveField(0)
  final String expenseId;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String currency;

  @HiveField(4)
  final String paidBy;

  @HiveField(5)
  final Map<String, double> splitAmong;

  @HiveField(6)
  final DateTime date;

  @HiveField(7)
  final String? notes;

  @HiveField(8)
  final String groupId;

  @HiveField(9)
  final int categoryIconCodePoint;

  @HiveField(10)
  final String splitType;

  @HiveField(11)
  final String? receiptUrl;

  @HiveField(12)
  final DateTime? createdAt;

  @HiveField(13)
  final DateTime? updatedAt;

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
    required this.categoryIconCodePoint,
    this.splitType = 'Equal',
    this.receiptUrl,
    this.createdAt,
    this.updatedAt,
  });

  // Helper getter for IconData
  IconData get categoryIcon => IconData(
        categoryIconCodePoint,
        fontFamily: 'MaterialIcons',
      );

  // Helper factory to create Expense with IconData
  factory Expense.withIcon({
    required String expenseId,
    required String title,
    required double amount,
    required String currency,
    required String paidBy,
    required Map<String, double> splitAmong,
    required DateTime date,
    String? notes,
    required String groupId,
    required IconData categoryIcon,
    String splitType = 'Equal',
    String? receiptUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      expenseId: expenseId,
      title: title,
      amount: amount,
      currency: currency,
      paidBy: paidBy,
      splitAmong: splitAmong,
      date: date,
      notes: notes,
      groupId: groupId,
      categoryIconCodePoint: categoryIcon.codePoint,
      splitType: splitType,
      receiptUrl: receiptUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
