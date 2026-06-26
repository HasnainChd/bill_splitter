import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Active bottom nav tab index
final homeTabIndexProvider = StateProvider<int>((ref) => 0);

/// Groups tab — search query
final groupSearchQueryProvider = StateProvider<String>((ref) => '');

/// Groups tab — active filter chip ('All', 'Owed', 'Owe')
final groupFilterProvider = StateProvider<String>((ref) => 'All');

/// Groups tab — TextField controller (auto-disposed with the widget)
final groupSearchControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(controller.dispose);
  return controller;
});

/// Settle tab — active filter chip ('All', 'I Owe', 'Owed to Me')
final settleFilterProvider = StateProvider<String>((ref) => 'All');

/// Home tab — active balance card index
final homeBalancePageIndexProvider = StateProvider.autoDispose<int>((ref) => 0);
