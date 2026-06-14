import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selected category chip
final aeCategoryProvider = StateProvider.autoDispose<String>((ref) => 'Food');

/// Split type: 'Equal', 'Custom', '%'
final aeSplitTypeProvider = StateProvider.autoDispose<String>((ref) => 'Equal');

/// Which members are included in the split
final aeSelectedMembersProvider =
    StateProvider.autoDispose<Set<String>>((ref) => {});

/// Amount text controller
final aeAmountControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
  final c = TextEditingController(text: '0');
  ref.onDispose(c.dispose);
  return c;
});

/// Description text controller
final aeTitleControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
  final c = TextEditingController();
  ref.onDispose(c.dispose);
  return c;
});

// ─── Create Group providers ────────────────────────────────────────────────

/// Selected icon index (0-based)
final cgIconIndexProvider = StateProvider.autoDispose<int>((ref) => 6);

/// Selected color index (0-based)
final cgColorIndexProvider = StateProvider.autoDispose<int>((ref) => 1);

/// Selected members set (initials/id)
final cgSelectedMembersProvider =
    StateProvider.autoDispose<Set<String>>((ref) => {'SC', 'MT'});

/// Member search query
final cgMemberSearchProvider =
    StateProvider.autoDispose<String>((ref) => '');

/// Group name controller
final cgNameControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
  final c = TextEditingController();
  ref.onDispose(c.dispose);
  return c;
});

/// Member search controller
final cgSearchControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
  final c = TextEditingController();
  ref.onDispose(c.dispose);
  return c;
});
